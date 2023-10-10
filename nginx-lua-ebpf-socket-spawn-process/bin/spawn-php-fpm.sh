#!/bin/bash

mount --bind /opt/h5g/skeleton/etc/passwd /tmp/passwd
mount --bind /opt/h5g/skeleton/etc/group /tmp/group
sudo -u www-data /usr/sbin/php-fpm7.4 --fpm-config /etc/php/h5g/u2.conf
