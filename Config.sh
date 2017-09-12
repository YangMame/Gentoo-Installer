#!/bin/bash

source /etc/profile

##更新
emerge-webrsync
emerge --sync
eselect profile list
read -p "输入你想使用的配置 使用systemd需选上带有systemd字样的.如果你想使用gnome或者kde桌面则选上对应的，如果你想使用窗口管理则选择desktop（openRC用）或systemd（systemd用）即可" PROFILE
eselect profile set $PROFILE
read -p "回车开始更新系统"
emerge -uvDN @world

##时区
echo "Asia/Shanghai" > /etc/timezone
emerge --config sys-libs/timezone-data
echo "en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale list
echo "************************************************************"
read -p "你想使用哪个语言 " TMP
eselect locale set $TMP

##内核
echo "************************************************************"
read -p "是否使用最新内核 y或回车跳过  " TMP
if [ "$TMP" == y ]
then echo "sys-kernel/gentoo-sources ~amd64" > /etc/portage/package.accept_keywords
fi
emerge gentoo-sources genkernel
echo "************************************************************"

##安装文件系统工具
if [ $1 == btrfs ]
then emerge sys-fs/btrfs-progs
elif [ $1 == xfs ]
then emerge sys-fs/xfsprogs
elif [ $1 == jfs ]
then emerge sys-fs/jfsutils
fi

cd /usr/sv/linux

TMP=4
while (($TMP!=1&&$TMP!=2&&$TMP!=3));do
    read -p "你想如何编译内核
[1]  从网络上下载自己的内核配置
[2]  使用genkernel all （如果你不会配置内核 建议选择这个）
[3]  现场开始编译（建议参照金步国的文档编译：http://www.jinbuguo.com/kernel/longterm-linux-kernel-options.html）
: " TMP
    if (($TMP==1))
    then read -p "输入下载地址：" TMP
	wget -v TMP -O .config
        make menuconfig
	read -p "回车开始编译"
        make -j8 && make modules_install ##根据你CPU修改-j8 推荐核数x2
        make install
        genkernel --install initramfs
    elif (($TMP==2))
    then genkernel all
    elif (($TMP==3))
    then
	rm .config
        make menuconfig
	read -p "回车开始编译安装内核"
        make -j8 && make modules_install
        make install
        genkernel --install initramfs
    else echo Error ! Input the currect number !
    fi
done
emerge  sys-kernel/linux-firmware

##NetWork
echo "************************************************************"
read -p  "安装NetworkManager "
emerge --autounmask-write  networkmanager
etc-update --automode -3
emerge networkmanager
systemctl enable NetworkManager
echo "************************************************************"
read -p "Input your hostname  " TMP
echo $TMP > /etc/hostname

##Tools
emerge app-admin/sysklogd
emerge sys-process/cronie
crontab /etc/crontab
echo "************************************************************"
echo "Change your password "
passwd

##GRUB
read -p "Are you Uefi ? " TMP
if [ "$TMP" == y ]
then echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
    emerge grub
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Gentoo
else emerge grub
    fdisk -l
    read -p "Input the disk you want to install the grub  " GRUB
    grub-install --target=i386-pc $GRUB
fi
ln -sf /proc/self/mounts /etc/mtab
systemd-machine-id-setup
echo 'GRUB_CMDLINE_LINUX=\"init=/usr/lib/systemd/systemd\"' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

##安装桌面环境

##添加用户

##开机自启
