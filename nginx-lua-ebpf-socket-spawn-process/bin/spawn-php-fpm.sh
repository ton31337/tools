#!/bin/bash
# $ shc -f spawn-php-fpm.sh -o spawn-php-fpm
#
# Make sure the host has this /proc mount (hidepid=2)
# mount -o remount,hidepid=2 /proc
#
# Another option would be using minijail() (= minijail0):
# sudo /home/donatas/minijail/minijail-linux-v18/minijail0 \
#    -c 0xffffffff --ambient -u www-data -p -i -f /tmp/h5g/u2.jail.pid \
#    -- /usr/sbin/php-fpm8.2 --fpm-config /etc/php-fpm/h5g/u2.conf

set -x
set -e

CHROOT="/var/lib/machines/debian"

/bin/mount --bind --make-unbindable /dev/pts/ "${CHROOT}/dev/pts"
/bin/mount --bind --make-unbindable /opt/h5g/skeleton/etc/passwd "${CHROOT}/etc/passwd"
/bin/mount --bind --make-unbindable /opt/h5g/skeleton/etc/group "${CHROOT}/etc/group"
/bin/mount --bind --make-unbindable /opt/h5g/skeleton/etc/php-fpm.conf "${CHROOT}/etc/php-fpm.conf"
/bin/mount --bind --make-unbindable /var/www/u2 "${CHROOT}/var/www/u2"
/bin/mount --bind --make-unbindable /tmp "${CHROOT}/tmp"
/bin/mount --type proc none "${CHROOT}/proc" || \
    /bin/mount -o remount --type proc none "${CHROOT}/proc"
/bin/mount -o remount,noexec,nosuid,nodev "${CHROOT}/tmp"
/usr/sbin/chroot --userspec=www-data "${CHROOT}" /usr/sbin/php-fpm8.2 --fpm-config /etc/php-fpm.conf
