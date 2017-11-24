export CROSS_COMPILE=arm-linux-gnueabihf-
export ARCH=arm

KERNEL_INTREE_DTS_NAME="sun8i-h3-nanopi-neo"
KERNEL_DEFCONFIG="sunxi"

UBOOT_BOARD_DEFCONFIG="nanopi_neo"
UBOOT_FORMAT_CUSTOM_NAME="u-boot-sunxi-with-spl.bin"

KERNEL_PRODUCTS=$(addprefix linux/,arch/arm/boot/zImage arch/arm/boot/$(KERNEL_INTREE_DTS_NAME).dtb)
KERNEL_PRODUCTS_OUTPUT=$(addprefix output,$(notdir $(KERNEL_PRODUCTS)))

MKFS_F2FS=/usr/sbin/mkfs.f2fs
SLOAD_F2FS=/usr/sbin/sload.f2fs

u-boot/:
	git clone git://git.denx.de/u-boot.git

u-boot/u-boot-sunxi-with-spl.bin:
	$(MAKE) -C u-boot/ $(UBOOT_BOARD_DEFCONFIG)_defconfig all

output/$(UBOOT_FORMAT_CUSTOM_NAME): u-boot/$(UBOOT_FORMAT_CUSTOM_NAME)
	cp $^ $@

linux/:
	git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

$(KERNEL_PRODUCTS):
	cp kernel.config linux/.config
	$(MAKE) -C linux/

$(KERNEL_PRODUCTS_OUTPUT): $(KERNEL_PRODUCTS)
	cp $^ output/

output/boot.scr: boot.cmd
	mkimage -C none -A arm -T script -d $^ $@
