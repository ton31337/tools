#!/bin/bash
# $ shc -f spawn.sh -o spawn

set -x

# User input comes as /tmp/u12345678.socket.
# Parse some more relevant parts, like u12345678.
US_PATH="${1}"
US_NAME=$(basename "${US_PATH}")
US_USER="${US_NAME::-7}"
NET_NS="/run/netns/${US_USER}"

if [[ ${US_PATH} == *".socket"*   ]]; then
	if ! grep "${US_PATH}" /proc/net/unix; then
		[ -f "${NET_NS}" ] || /bin/touch "${NET_NS}"
		/usr/bin/unshare \
			--mount \
			--net="${NET_NS}" \
			--propagation private \
			/opt/h5g/bin/spawn-php-fpm.sh "${US_USER}" \
			2>"/tmp/unshare-${US_USER}.log" \
			>"/tmp/unshare-${US_USER}.log"
		/sbin/ip link delete "veth0-${US_USER}"
		/sbin/ip link add "veth0-${US_USER}" type veth peer name "veth1-${US_USER}"
		/sbin/ip -6 address add 2a02:4780:eedd::1/64 dev "veth0-${US_USER}"
		/sbin/ip link set up dev "veth0-${US_USER}"
		/sbin/ip link set "veth1-${US_USER}" netns "${US_USER}"
		/usr/bin/nsenter --net="${NET_NS}" /sbin/ip address add 127.0.0.1/8 dev lo
		/usr/bin/nsenter --net="${NET_NS}" /sbin/ip link set dev lo up
		/usr/bin/nsenter --net="${NET_NS}" /sbin/ip -6 address add 2a02:4780:eedd::3/64 dev "veth1-${US_USER}"
		/usr/bin/nsenter --net="${NET_NS}" /sbin/ip -6 link set up dev "veth1-${US_USER}"
		/usr/bin/nsenter --net="${NET_NS}" /sbin/ip -6 route add default via 2a02:4780:eedd::1
	fi
fi
