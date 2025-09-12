#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2025 Donatas Abraitis
#
# TL;DR;
# This is a PoC of using eBPF XDP to spawn containers on incoming
# connection attempts to specific ports (80, 443).
# If a container is already running for that IP:port, nothing happens.
# If no container is running, a new one is spawned.
# The container is expected to register its health status in Redis
# under a specific key (e.g., "status:<ip>_<port>").
#
# To run:
# $ sudo python3 loader.py --iface eth0

import argparse
import ctypes
import socket
import struct
import time
import redis
from bcc import BPF

CONTAINER_STATUS_UNKNOWN = 0
CONTAINER_STATUS_DOWN = 1
CONTAINER_STATUS_UP = 2


class Redis:
    def __init__(self):
        self.client = redis.Redis(
            unix_socket_path="/var/run/redis/redis-server.sock",
        )


# NOTE: This MUST match with the eBPF key
def make_key(ip_v4_int, port):
    return (ip_v4_int << 32) | port


def int_to_ip(i):
    return socket.inet_ntoa(struct.pack("!I", i))


class Event(ctypes.Structure):
    _fields_ = [("daddr", ctypes.c_uint32), ("dport", ctypes.c_uint16)]


def spawn(ip, port):
    print(f"[spawner] starting container for {ip}:{port}")
    # Simulate container spawn time, let's say it takes 10 seconds
    time.sleep(10)
    return True


def health_check(ip, port):
    # FIXME: Implement real health check, for now it's Redis,
    # but I think HTTP would be better...
    redis = Redis()
    data = redis.client.get(f"status:{ip}_{port}")
    if not data:
        return False

    return data.decode() == "UP"


def handler(cpu, data, size, bpf, status_table):
    event = ctypes.cast(data, ctypes.POINTER(Event)).contents
    ip = int_to_ip(event.daddr)
    port = event.dport

    key = ctypes.c_ulonglong(make_key(event.daddr, port))
    val = status_table.get(key)
    if val and val.value == 2:
        print(f"[event] status already UP for {ip}:{port}")
        return

    print(f"[event] handling event for {ip}:{port}")
    status_table[key] = ctypes.c_ubyte(CONTAINER_STATUS_DOWN)

    if health_check(ip, port):
        print(f"[event] health check passed for {ip}:{port}, not spawning")
        status_table[key] = ctypes.c_ubyte(CONTAINER_STATUS_UP)
        return

    # NOTE: Spawn something here...
    if spawn(ip, port):
        print(f"[event] spawned container for {ip}:{port}")
        status_table[key] = ctypes.c_ubyte(CONTAINER_STATUS_UP)


def dump_hash(hash):
    print("\n[debug] Current status map entries:")
    for k, v in hash.items():
        port = k.value & 0xFFFFFFFF
        ip = int_to_ip((k.value >> 32) & 0xFFFFFFFF)
        status = (
            "UNKNOWN"
            if v.value == CONTAINER_STATUS_UNKNOWN
            else "DOWN" if v.value == CONTAINER_STATUS_DOWN else "UP"
        )
        print(f"  → {ip}:{port} = {status} ({v.value})")
    print()


def main():
    parser = argparse.ArgumentParser(description="Spawn containers on XDP events")
    parser.add_argument(
        "--iface", required=True, help="Interface to attach XDP to (e.g., eth0)"
    )
    args = parser.parse_args()

    bpf = BPF(src_file="program.c", cflags=["-Wno-duplicate-decl-specifier"])
    fn = bpf.load_func("xdp_prog", BPF.XDP)

    bpf.attach_xdp(args.iface, fn, 0)

    events = bpf["events"]
    status_hash = bpf["status_hash"]

    events.open_perf_buffer(
        lambda cpu, data, size: handler(cpu, data, size, bpf, status_hash)
    )

    print("[main] waiting for events. CTRL-C to exit.")
    try:
        last_debug = time.time()
        last_flush = time.time()
        while True:
            bpf.perf_buffer_poll(timeout=50)

            if time.time() - last_debug > 3:
                dump_hash(status_hash)
                last_debug = time.time()

            # Clear the status map every 60 seconds to avoid stale entries
            if time.time() - last_flush > 60:
                status_hash.clear()
                last_flush = time.time()
    except KeyboardInterrupt:
        print("Detaching XDP and exiting")
    finally:
        bpf.remove_xdp(args.iface, 0)


if __name__ == "__main__":
    main()
