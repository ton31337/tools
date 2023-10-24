#!/bin/bash
# $ shc -f spawn.sh -o spawn

set -x

# User input comes as /tmp/u12345678.socket.
# Parse some more relevant parts, like u12345678.
US_PATH="${1}"
US_NAME=$(basename "${US_PATH}")
US_USER="${US_NAME::-7}"

if [[ ${US_PATH} == *".socket"*   ]]; then
	[ -S "${US_PATH}" ] ||
		/usr/bin/unshare \
			--mount \
			--propagation private \
			/opt/h5g/bin/spawn-php-fpm.sh "${US_USER}" \
			2>"/tmp/unshare-${US_USER}.log" \
			>"/tmp/unshare-${US_USER}.log"
fi
