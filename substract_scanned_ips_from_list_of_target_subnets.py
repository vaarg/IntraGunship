#!/usr/bin/env python3
"""
Subtract scanned IPs from a list of target subnets.

Inputs:
  - scanned.txt: one IPv4 address per line
  - subnets.txt: one IPv4 CIDR subnet per line

Output:
  - remaining CIDRs/IPs (minimal cover) to stdout, one per line

Example:
  python remaining_targets.py --scanned scanned.txt --subnets subnets.txt > remaining.txt
"""

from __future__ import annotations

import argparse
import ipaddress
import sys
from typing import Iterable, List, Set


def read_scanned_ips(path: str) -> Set[ipaddress.IPv4Address]:
    scanned: Set[ipaddress.IPv4Address] = set()
    with open(path, "r", encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.split("#", 1)[0].strip()
            if not line:
                continue
            try:
                ip = ipaddress.ip_address(line)
            except ValueError as e:
                raise ValueError(f"{path}:{lineno}: invalid IP address: {line}") from e
            if ip.version != 4:
                raise ValueError(f"{path}:{lineno}: only IPv4 is supported: {line}")
            scanned.add(ip)
    return scanned


def read_subnets(path: str) -> List[ipaddress.IPv4Network]:
    subnets: List[ipaddress.IPv4Network] = []
    with open(path, "r", encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.split("#", 1)[0].strip()
            if not line:
                continue
            try:
                net = ipaddress.ip_network(line, strict=False)
            except ValueError as e:
                raise ValueError(f"{path}:{lineno}: invalid subnet/CIDR: {line}") from e
            if net.version != 4:
                raise ValueError(f"{path}:{lineno}: only IPv4 is supported: {line}")
            subnets.append(net)
    return subnets


def summarize_gap(start: int, end: int) -> List[ipaddress.IPv4Network]:
    """Return the minimal CIDR cover for an inclusive integer IP range."""
    if start > end:
        return []
    return list(
        ipaddress.summarize_address_range(
            ipaddress.IPv4Address(start),
            ipaddress.IPv4Address(end),
        )
    )


def subtract_scanned_from_subnet(
    subnet: ipaddress.IPv4Network,
    scanned_in_subnet: Iterable[ipaddress.IPv4Address],
) -> List[ipaddress.IPv4Network]:
    """
    Return the remaining address space in `subnet` after removing the given scanned IPs.
    Output is a minimal set of CIDR blocks and /32s.
    """
    scanned_ints = sorted(int(ip) for ip in scanned_in_subnet)
    if not scanned_ints:
        return [subnet]

    start = int(subnet.network_address)
    end = int(subnet.broadcast_address)

    remaining: List[ipaddress.IPv4Network] = []
    cursor = start

    for scanned_ip in scanned_ints:
        if scanned_ip < cursor:
            continue
        if scanned_ip > end:
            break
        remaining.extend(summarize_gap(cursor, scanned_ip - 1))
        cursor = scanned_ip + 1

    remaining.extend(summarize_gap(cursor, end))
    return remaining


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Subtract scanned IPs from target subnets and emit remaining targets."
    )
    parser.add_argument("--scanned", required=True, help="Path to scanned IP list")
    parser.add_argument("--subnets", required=True, help="Path to subnet list")
    parser.add_argument(
        "--sort",
        action="store_true",
        help="Sort final output numerically by network address/prefix",
    )
    args = parser.parse_args()

    try:
        scanned_ips = read_scanned_ips(args.scanned)
        subnets = read_subnets(args.subnets)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 2

    output: List[ipaddress.IPv4Network] = []

    for subnet in subnets:
        relevant_scanned = [ip for ip in scanned_ips if ip in subnet]
        output.extend(subtract_scanned_from_subnet(subnet, relevant_scanned))

    if args.sort:
        output.sort(key=lambda n: (int(n.network_address), n.prefixlen))

    for net in output:
        print(net)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
