setenv machid 1029
setenv bootargs earlyprintk console=/dev/ttyS0,115200 root=/dev/mmcblk0p2
load mmc 0:1 0x43000000 sun8i-h3-nanopi-neo.dtb
load mmc 0:1 0x41000000 zImage
bootz 0x41000000 - 0x43000000
#load mmc 0:1 0x45000000 boot/initramfs-sunxi-new
#bootz 0x41000000 0x45000000 0x43000000
