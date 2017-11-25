================================================
 Build script for NanoPi NEO Alpine Linux image
================================================

Build
-----

Requirements
............

  * kpartx
  * mkfs.ext2, mkfs.f2fs
  * git
  * arm-linux-gnueabihf-gcc (to build u-boot and linux kernel)
  * sudo rights (needed to mount filesystems when building)
    - TODO: this could be improved by using tools that can access image files without mounting
