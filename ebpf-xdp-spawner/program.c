// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright (C) 2025 Donatas Abraitis
 */

#include <linux/in.h>
#include <uapi/linux/bpf.h>
#include <uapi/linux/if_ether.h>
#include <uapi/linux/ip.h>
#include <uapi/linux/tcp.h>

struct event_t {
	__u32 daddr;
	__u16 dport;
};

BPF_PERF_OUTPUT(events);
BPF_HASH(status_hash, u64, u8, 1024000);

static inline u64 make_hash_key(__u32 ip, __u16 port)
{
	return ((__u64)ip << 32) | (__u64)port;
}

int xdp_prog(struct xdp_md *ctx)
{
	void *data = (void *)(long)ctx->data;
	void *data_end = (void *)(long)ctx->data_end;
	struct event_t evt = {};
	struct ethhdr *eth = data;
	struct iphdr *iph;
	struct tcphdr *tcp;
	uint64_t nh_off = sizeof(*eth);
	__u64 key;
	__u32 ip;
	__u16 port;

	if (data + nh_off > data_end)
		return XDP_PASS;

	if (eth->h_proto != __constant_htons(ETH_P_IP))
		return XDP_PASS;

	iph = data + nh_off;
	if ((void *)&iph[1] > data_end)
		return XDP_PASS;

	/* For now only IPv4... */
	if (iph->version != 4)
		return XDP_PASS;

	/* ... and TCP */
	if (iph->protocol != IPPROTO_TCP)
		return XDP_PASS;

	tcp = (void *)iph + iph->ihl * 4;
	if ((void *)(tcp + 1) > data_end)
		return XDP_PASS;

	ip = __constant_ntohl(iph->daddr);
	port = __constant_ntohs(tcp->dest);

	/* FIXME: Normally this will only 80/443 ports */
	if (port != 80 && port != 8080 && port != 8081 && port != 8082 && port != 8083)
		return XDP_PASS;

	key = make_hash_key(ip, port);
	evt.daddr = __constant_ntohl(iph->daddr);
	evt.dport = port;
	events.perf_submit(ctx, &evt, sizeof(evt));

	u8 *status = status_hash.lookup(&key);
	if (!status)
		return XDP_DROP;

	if (*status != 2)
		/* If it's not UP - drop it (= tell the client to retry) */
		return XDP_DROP;

	return XDP_PASS;
}
