## 测试ing
 Live系统推荐用Arch linux的live CD 因为有genfstab（其它内置genfstab或者安装此程序的也可以使用）
 仅支持amd64系统 使用systemd 支持UEFI 三种内核配置：Ubuntu内核配置 Genkernel all 还有从网络下载配置或全手动配置（之所以不用Arch的内核配置是因为驱动可能不如Ubuntu全面）
 (如果你的efi分区是直接挂载到/boot而不是/boot/efi 可能造成grub混乱 建议：把现有系统的引导换成bootctl：https://wiki.archlinux.org/index.php/Systemd-boot)