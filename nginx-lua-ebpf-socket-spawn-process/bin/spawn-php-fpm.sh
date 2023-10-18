#!/bin/bash
# $ shc -f spawn-php-fpm.sh -o spawn-php-fpm

set -x

CHROOT="/var/lib/machines/debian"

mount --bind /dev/pts/ "${CHROOT}/dev/pts"
mount --bind /opt/h5g/skeleton/etc/passwd "${CHROOT}/etc/passwd"
mount --bind /opt/h5g/skeleton/etc/group "${CHROOT}/etc/group"
mount --bind /opt/h5g/skeleton/etc/php-fpm.conf "${CHROOT}/etc/php-fpm.conf"
mount --bind /var/www/u2 "${CHROOT}/var/www/u2"
mount --bind /tmp "${CHROOT}/tmp"
chroot "${CHROOT}" sudo -u www-data /usr/sbin/php-fpm8.2 --fpm-config /etc/php-fpm.conf
