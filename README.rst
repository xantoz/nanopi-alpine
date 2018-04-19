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



