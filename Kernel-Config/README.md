### 注意,此内核配置仅我个人使用,仅作参考和备份

* 电脑型号: GL552JX 1.0 飞行堡垒第一代i5低配版,已加4G内存条和山丧的120G SSD
* UEFI启动,支持用做efi文件启动,支持使用efibootmgr启动(内核配置中/dev/sdb2是根目录)
* 文件系统: BTRFS
* 性能优先,因为我平时不用电池直接插电用
* 没有使用initramfs
* 需要事先安装好`sys-firmware/intel-microcode`和`sys-kernel/linux-firmware`,因为内核中的Intel-microcode和蓝牙驱动需要
