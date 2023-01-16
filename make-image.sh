#!/bin/bash
#set -euo pipefail

readonly CCred=`printf '\033[0;31m'`
readonly CCyellow=`printf '\033[0;33m'`
readonly CCgreen=`printf '\033[92m'`
readonly CCblue=`printf '\033[94m'`
readonly CCcyan=`printf '\033[36m'`
readonly CCend=`printf '\033[0m'`
readonly CCbold=`printf '\033[1m'`
readonly CCunderline=`printf '\033[4m'`


echo_err()
{
    >&2 echo "$@"
}

die()
{
    echo_err "${CCred}${CCbold}ERROR: $@${CCend}"
    exit 2
}

log()
{
    echo_err "${CCblue}[${CCend}${CCgreen}*${CCend}${CCblue}]${CCend} $@"
}

px=$(which kpartx)
if [ -n "$px" ]; then
	popt="vs"
	mapper="/mapper"
else
	px=$(which partx)
	if [ -n "$px" ]; then
		popt="v"
		mapper=''
	else
		log "Neither kpartx or partx are installed"
		exit 1
	fi
fi
log "using '$px' for partitioning"

need_env_var()
{
    for i in "$@"; do
        (
            set +u
            var="$(eval echo \"\$"$i"\")"
            [ -n "${var}" ] || die "Environment variable ${i} not defined, or empty"
        )
    done
}

cleanup()
{
    set +eu

    clean_stage2
    # We end up in this function at the end of script execution
    [ -n "${ROOT_MOUNT:-}" -o -n "${BOOT_MOUNT:-}" ] && unmount_filesystems
    [ -n "${LOOP:-}" ] && unmap_partitions
}
trap cleanup 0

write_partition_table()
{
    log "Creating partition table"
    sfdisk "${IMAGE}" <<__EOF__
# partition table of ${IMAGE}
unit: sectors

${IMAGE}p1 : start=2048, size=131072, Id=83
${IMAGE}p2 :                          Id=83
__EOF__
}

map_partitions()
{
    # Hack to get what loop device kpartx uses for the mappings
    # /dev/mapper/loopXp1 /dev/mapper/loopXp2 /dev/mapper/loopXp3 /dev/mapper/loopXp4
    log "Mapping image partitions"
    LOOP=$($px -a$popt "${IMAGE}" | grep -Po 'loop[[:digit:]]+' | head -1)
}

unmap_partitions()
{
    log "Unmapping image partitions"
    $px -d$popt /dev/${LOOP}
    losetup -d /dev/${LOOP} || true
    LOOP=""
}

install_uboot()
{
    log "Installing u-boot to image"
    (set -x; dd if="${UBOOT}" of="${IMAGE}" bs=1024 seek=8 conv=fsync,notrunc)
    sync
}

create_filesystems()
{
    BOOT_DEVICE="/dev/${mapper}${LOOP}p1"
    ROOT_DEVICE="/dev/${mapper}${LOOP}p2"
    (set -x; mkfs.ext2 -L nanopi-boot "${BOOT_DEVICE}")
    (set -x; mkfs.f2fs -l nanopi-root "${ROOT_DEVICE}")
}

mount_filesystems()
{
    ROOT_MOUNT="$(mktemp -d /tmp/root.XXXXXX)"
    BOOT_MOUNT="${ROOT_MOUNT}/boot"
    (set -x; mount "${ROOT_DEVICE}" "${ROOT_MOUNT}")
    mkdir -p "${BOOT_MOUNT}"
    (set -x; mount "${BOOT_DEVICE}" "${BOOT_MOUNT}")
}

unmount_filesystems()
{
    log "Unmounting and cleaning up temp mountpoints"
    if [ -n "${BOOT_MOUNT:-}" ]; then
        umount "${BOOT_MOUNT}"
        rmdir "${BOOT_MOUNT}"
    fi
    if [ -n "${ROOT_MOUNT:-}" ]; then
        umount "${ROOT_MOUNT}"
        rmdir "${ROOT_MOUNT}"
    fi
}

fill_filesystems()
{
    (set -x; cp "${BOOTSCR}" "${KERNEL}" "${DTB}" "${BOOT_MOUNT}"/)
    (set -x; tar -C "${ROOT_MOUNT}/" -xf "${ROOTFS_TARBALL}")
    chown 755 "${ROOT_MOUNT}"   # Make sure the root folder in the rootfs is readable by all
}

prepare_stage2()
{
    log "Preparing stage 2"
    cp /usr/bin/qemu-arm-static ${ROOT_MOUNT}/usr/bin/
    cp stage-2.sh ${ROOT_MOUNT}/root/

    mount -t proc none ${ROOT_MOUNT}/proc
    mount -o bind /dev ${ROOT_MOUNT}/dev

    mkdir -p ${ROOT_MOUNT}/boot
    mount -o bind ${BOOT_MOUNT}/ ${ROOT_MOUNT}/boot

    log "Entering stage 2"
    chroot ${ROOT_MOUNT}/ /usr/bin/qemu-arm-static -cpu cortex-a8 /bin/sh /root/stage-2.sh
}

clean_stage2()
{
    log "Cleaing up after stage 2"
    rm ${ROOT_MOUNT}/usr/bin/qemu-arm-static
    rm ${ROOT_MOUNT}/root/stage-2.sh

    umount ${ROOT_MOUNT}/proc
    umount ${ROOT_MOUNT}/dev
    umount ${ROOT_MOUNT}/boot
}

main()
{
    need_env_var UBOOT BOOTSCR KERNEL DTB ROOTFS_TARBALL IMAGE

    write_partition_table
    install_uboot
    map_partitions
    create_filesystems
    mount_filesystems
    fill_filesystems
    prepare_stage2
}

main
