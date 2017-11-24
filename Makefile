export CROSS_COMPILE=arm-linux-gnueabihf-
export ARCH=arm

################################################################################
## Config
################################################################################
KERNEL_INTREE_DT_NAME   ?= sun8i-h3-nanopi-neo
KERNEL_DEFCONFIG         ?= sunxi

UBOOT_BOARD_DEFCONFIG    ?= nanopi_neo
UBOOT_FORMAT_CUSTOM_NAME ?= u-boot-sunxi-with-spl.bin

IMAGE_SIZE               ?= 4000M

ROOTFS_TARBALL     = alpine-minirootfs-3.6.2-armhf.tar.gz
ROOTFS_TARBALL_URL = http://dl-cdn.alpinelinux.org/alpine/v3.6/releases/armhf/$(ROOTFS_TARBALL)

################################################################################
## Possible modifiers:
##  DO_UBOOT_DEFCONFIG
##  DO_UBOOT_MENUCONFIG
##  DO_LINUX_DEFCONFIG
##  DO_LINUX_MENUCONFIG
################################################################################

################################################################################
TSTAMP:=$(shell date +'%Y%m%d-%H%M%S')
SDCARD_IMAGE:=nanopi-alpine-$(TSTAMP).img

KERNEL_PRODUCTS=$(addprefix sources/linux/,arch/arm/boot/zImage arch/arm/boot/dts/$(KERNEL_INTREE_DT_NAME).dtb)
KERNEL_PRODUCTS_OUTPUT=$(addprefix output,$(notdir $(KERNEL_PRODUCTS)))

# export MKFS_F2FS=/usr/sbin/mkfs.f2fs
# export SLOAD_F2FS=/usr/sbin/sload.f2fs

.PHONY: all
all: output/nanopi-alpine.img

sources/$(ROOTFS_TARBALL):
	wget -O 'sources/$(ROOTFS_TARBALL)' '$(ROOTFS_TARBALL_URL)'

sources/u-boot.git:
	git clone --depth=1 git://git.denx.de/u-boot.git 'sources/u-boot'
	touch '$@' # sentinel file

sources/u-boot/u-boot-sunxi-with-spl.bin: sources/u-boot.git
	if [ ! -f u-boot.config ] || [ -n '$(DO_UBOOT_DEFCONFIG)' ]; then    \
	    $(MAKE) -C sources/u-boot/ '$(UBOOT_BOARD_DEFCONFIG)_defconfig'; \
	else                                                                 \
	    cp u-boot.config sources/u-boot/.config;                         \
	fi
	if [ -n '$(DO_UBOOT_MENUCONFIG)' ]; then                             \
	    $(MAKE) -C sources/u-boot/ menuconfig;                           \
	fi
	$(MAKE) -C sources/u-boot/ all

output/$(UBOOT_FORMAT_CUSTOM_NAME): sources/u-boot/$(UBOOT_FORMAT_CUSTOM_NAME)
	cp $^ $@

sources/linux.git:
	git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git 'sources/linux/'
	touch '$@' # sentinel file

$(KERNEL_PRODUCTS): sources/linux.git
	if [ ! -f kernel.config ] || [ -n '$(DO_LINUX_DEFCONFIG)' ]; then   \
	    $(MAKE) -C sources/linux/ '$(KERNEL_DEFCONFIG)_defconfig';      \
	else                                                                \
	    cp kernel.config sources/linux/.config;                         \
	fi
	if [ -n '$(DO_LINUX_MENUCONFIG)' ]; then                            \
	    $(MAKE) -C sources/linux/ menuconfig;                           \
	fi
	$(MAKE) -C sources/linux/ all

$(KERNEL_PRODUCTS_OUTPUT): $(KERNEL_PRODUCTS)
	cp $^ output/

output/boot.scr: boot.cmd
	mkimage -C none -A arm -T script -d '$^' '$@'

output/nanopi-alpine.img: output/$(UBOOT_FORMAT_CUSTOM_NAME) output/boot.scr $(KERNEL_PRODUCTS_OUTPUT)
	truncate -s '$(IMAGE_SIZE)' '$@'
	UBOOT='$(UBOOT_FORMAT_CUSTOM_NAME)'            \
	BOOTSCR='output/boot.scr'                      \
	KERNEL='$(word 1,$(KERNEL_PRODUCTS_OUTPUT))'   \
	DTB='$(word 2,$(KERNEL_PRODUCTS_OUTPUT))'      \
	ROOTFS_TARBALL='sources/$(ROOTFS_TARBALL)'     \
	IMAGE='$@'                                     \
	sudo make-image.sh

.PHONY: clean
clean:
	if [ -d u-boot/ ]; then $(MAKE) -C sources/u-boot/ clean; fi
	if [ -d linux/ ]; then $(MAKE) -C sources/linux/ clean; fi
	rm -f output/*

.PHONY: distclean
distclean:
	rm -rf sources/*
