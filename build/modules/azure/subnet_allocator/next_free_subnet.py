#!/usr/bin/env python3
"""
next_free_subnet.py
====================
Terraform external data source — finds the next non-overlapping CIDR inside a VNet.

stdin (JSON from Terraform):
  {
    "vnet_cidr":        "10.9.0.0/16",
    "used_cidrs":       "10.9.0.0/24,10.9.1.0/26,...",   <- existing subnet CIDRs, comma-separated
    "prefix_length":    "27",                             <- desired new subnet size
    "offset_index":     "2",                             <- position of this subnet in the request list
    "sibling_prefixes": "27,28"                          <- prefix lengths of earlier siblings in same plan
  }

stdout (JSON to Terraform):
  { "cidr": "10.9.2.0/27" }

Exit 1 on any error — Terraform will surface stderr as a plan error.

Logic:
  1. Parse all currently-used CIDRs from Azure (used_cidrs).
  2. Synthesise phantom "already-claimed" blocks for siblings that come before
     this subnet in the same plan (they aren't in Azure yet, but we must not
     overlap them). We do this by walking the VNet in order and reserving one
     block per sibling prefix length.
  3. Walk every candidate /prefix_length block in the VNet and return the first
     one that overlaps neither real nor phantom blocks.
"""

import ipaddress
import json
import sys


def _collect_phantom_blocks(
    vnet: ipaddress.IPv4Network,
    real_used: list,
    sibling_prefixes: list[int],
) -> list:
    """
    For each sibling subnet that precedes us in the same plan (they don't exist
    in Azure yet), walk the VNet and claim the first free block of that size so
    we don't collide with them.
    """
    claimed = list(real_used)
    phantoms = []

    for prefix_len in sibling_prefixes:
        for candidate in vnet.subnets(new_prefix=prefix_len):
            if not any(candidate.overlaps(u) for u in claimed):
                phantoms.append(candidate)
                claimed.append(candidate)
                break

    return phantoms


def find_next_free(
    vnet_cidr: str,
    used_cidrs: list[str],
    prefix_length: int,
    sibling_prefixes: list[int],
) -> str:
    vnet = ipaddress.ip_network(vnet_cidr, strict=False)

    real_used = []
    for c in used_cidrs:
        c = c.strip()
        if c:
            try:
                real_used.append(ipaddress.ip_network(c, strict=False))
            except ValueError:
                # skip malformed entries (can happen if the VNet has no subnets yet)
                pass

    phantoms = _collect_phantom_blocks(vnet, real_used, sibling_prefixes)
    all_used = real_used + phantoms

    for candidate in vnet.subnets(new_prefix=prefix_length):
        if not any(candidate.overlaps(u) for u in all_used):
            return str(candidate)

    raise RuntimeError(
        f"No free /{prefix_length} block available in {vnet_cidr}. "
        f"Currently used: {[str(u) for u in real_used]}. "
        "Consider expanding the VNet address space or using a smaller prefix_length."
    )


def main():
    try:
        query = json.load(sys.stdin)

        vnet_cidr     = query["vnet_cidr"]
        used_raw      = query.get("used_cidrs", "")
        prefix_length = int(query["prefix_length"])
        sibling_raw   = query.get("sibling_prefixes", "")

        used_cidrs = [c.strip() for c in used_raw.split(",") if c.strip()]
        sibling_prefixes = [
            int(p.strip()) for p in sibling_raw.split(",") if p.strip()
        ]

        cidr = find_next_free(vnet_cidr, used_cidrs, prefix_length, sibling_prefixes)
        print(json.dumps({"cidr": cidr}))

    except KeyError as e:
        sys.stderr.write(f"ERROR: missing required input field {e}\n")
        sys.exit(1)
    except Exception as e:
        sys.stderr.write(f"ERROR: {e}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
