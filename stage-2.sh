#!/bin/sh

KEYBOARD_MAP="us us"
TIMEZONE="UTC"
HARDWARE_ADDR="00:11:22:33:44:55"
HOSTNAME=nanopi_neo
USER_NAME=nanopi
USER_PASS=change_me_later
ROOT_PASS=change_me_now

# fixing root permissions
chmod g+rx,o+rx /

# temporary adding dns server
echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" > /etc/resolv.conf

apk update

apk add alpine-base alpine-baselayout alpine-conf alpine-keys alpine-mirrors apk-tools bonding bridge busybox busybox-initscripts busybox-suid chrony dbus-libs e2fsprogs e2fsprogs-libs kbd-bkeymaps libblkid libcap libcom_err libc-utils libnl3 libressl libressl2.6-libcrypto libressl2.6-libssl libressl2.6-libtls libusb libuuid musl musl-utils network-extras openrc pcsc-lite-libs scanelf tzdata usb-modeswitch vlan sudo zlib dropbear dropbear-scp dropbear-ssh dropbear-dbclient dropbear-openrc 

rc-update add acpid sysinit 
rc-update add crond sysinit 
rc-update add devfs sysinit 
rc-update add dmesg sysinit 
rc-update add mdev sysinit 

rc-update add bootmisc boot 
rc-update add hostname boot 
rc-update add hwclock boot 
rc-update add keymaps boot 
rc-update add networking boot 
rc-update add sysctl boot 
rc-update add syslog boot 
rc-update add urandom boot

rc-update add dropbear default
rc-update add chronyd default

rc-update add mount-ro shutdown 
rc-update add killprocs shutdown 
rc-update add savecache shutdown

mkdir -p /lib/modules


#
# possible security hole (enabled debugging) on uart
#

# enable debug on uart 
sed -i 's/^#ttyS0/ttyS0/' /etc/inittab

# debug only - disable in future
echo "ttyS0" >> /etc/securetty


# disabling spare consoles 
sed -i 's/^tty3/#tty3/' /etc/inittab
sed -i 's/^tty4/#tty4/' /etc/inittab
sed -i 's/^tty5/#tty5/' /etc/inittab
sed -i 's/^tty6/#tty6/' /etc/inittab

# changing root password
echo root:$ROOT_PASS | chpasswd

# configuring keymap
setup-keymap $KEYBOARD_MAP

echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1     $HOSTNAME" >> /etc/hosts


cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
  hwaddress ether $HARDWARE_ADDR
  hostname $HOSTNAME
EOF

setup-timezone -z $TIMEZONE
setup-apkrepos -f
setup-sshd -c dropbear
setup-ntp -c chrony

#
# adding custom user
#
adduser -s "/bin/sh" -D $USER_NAME 
echo $USER_NAME:$USER_PASS | chpasswd
chmod u+w /etc/sudoers
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers
chmod u-w /etc/sudoers

exit 0

