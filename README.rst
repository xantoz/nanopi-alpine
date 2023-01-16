================================================
 Build script for NanoPi NEO Alpine Linux image
================================================

Requirements
............

  * kpartx
  * mkfs.ext2, mkfs.f2fs
  * git
  * gcc-arm-linux-gnueabihf (to build u-boot and linux kernel)
  * sudo rights (needed to mount filesystems when building)
    - TODO: this could be improved by using tools that can access image files without mounting
  * u-boot-tools swig libpython-dev  f2fs-tools
  * qemu-user qemu-system-arm qemu-user-static (for stage2 script)


Build
-----

Before build check Makefile and stage-2.sh files for tuning options like user, passwords, timezones and other options. To build in main directory run:
```
make
```

Notes
-----

The f2fs file system created a huge kernel dump when a file was written, so perhaps it is not
as mature as it should be, and that was with the Alpine v3.17 kernel (6.2). Using the mkfs.ext2
for the nanopi-root filesystem in make-image.sh would give a stable file system. If you want to run linux off a read only flash file system, use tmpfs on /run, /var/log, /tmp, and /var/lib/misc. The last mount is only if running dnsmasq.

