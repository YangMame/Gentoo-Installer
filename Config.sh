#!/bin/bash

source /etc/profile

##更新
emerge-webrsync
emerge --sync
eselect profile list
read -p "输入你想使用的配置 使用systemd需选上带有systemd字样的（gnome桌面请选上systemd）.如果你想使用gnome或者kde桌面则选上对应的（只有选择5,6,7将自动安装基础桌面），如果你想使用其他桌面或者wm则选择desktop（openRC用）或systemd（systemd用）即可" PROFILE
eselect profile set $PROFILE
read -p "回车开始更新系统（可能要花一段时间，可以去看俩集番）"
emerge -uvDN @world

##时区
echo "Asia/Shanghai" > /etc/timezone
emerge --config sys-libs/timezone-data
echo "en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale list
read -p "你想使用哪个语言 " TMP
eselect locale set $TMP

##配置挂载点
wget -q https://git.archlinux.org/arch-install-scripts.git/snapshot/arch-install-scripts-17.tar.gz
tar -xf arch-install-scripts-17.tar.gz
cd arch-install-scripts-17
sed -i 's/PREFIX = \/usr\/local/PREFIX = \/usr/g' Makefile
make > /dev/null
make install > /dev/null
genfstab -U / > /etc/fstab
sed -i '/selinuxfs/d' /etc/fstab
sed -i '/efivarfs/d' /etc/fstab
cd ..
rm -r arch-install-scripts-17*

##内核
read -p "使用哪个内核？ck-sources(推荐)或gentoo-sources输入y使用ck回车将使用gentoo-sources  " TMP
if [ "$TMP" == y ];then
	echo sys-kernel/ck-sources ~amd64 >> /etc/portage/package.accept_keywords
	emerge ck-sources genkernel
else
	emerge gentoo-sources genkernel
fi

##安装文件系统工具
if [ $1 == btrfs ];then
	emerge sys-fs/btrfs-progs
elif [ $1 == xfs ];then
	emerge sys-fs/xfsprogs
elif [ $1 == jfs ];then
	emerge sys-fs/jfsutils
fi

##编译安装内核

cd /usr/src/linux

TMP=4
while (($TMP!=1&&$TMP!=2&&$TMP!=3));do
read -p "你想如何编译内核
[1]  从网络上下载自己的内核配置
[2]  使用genkernel all （如果你不会配置内核 建议选择这个）
[3]  现场开始编译（建议参照金步国的文档配置：http://www.jinbuguo.com/kernel/longterm-linux-kernel-options.html）
: " TMP
	if [ "$TMP" == 1 ];then
		tmp=n
		while [ "$tmp" == n ];do
			read -p "输入下载地址：" LINK
			wget -v $LINK -O .config
			make menuconfig
			read -p "回车开始编译安装内核(输入n重新下载)" tmp
		done
		make -j8 && make modules_install ##根据你CPU修改-j8 推荐核数x2
		make install
		genkernel --install initramfs
	elif [ "$TMP" == 2 ];then
		genkernel all
	elif [ "$TMP" == 3 ];then
		rm .config > /dev/null
		tmp=n
		while [ "$tmp" == n ];do
			make menuconfig
			read -p "回车开始编译安装内核(输入n重新进入配置)" tmp
		done
		make -j8 && make modules_install
		make install
		genkernel --install initramfs
	else echo 请输入正确数字
	fi
done

emerge  sys-kernel/linux-firmware

##NetWork
read -p  "安装NetworkManager "
emerge --autounmask-write networkmanager
etc-update --automode -3
emerge networkmanager
read -p "输入你的主机名：  " TMP
echo hostname=\"$TMP\" > /etc/conf.d/hostname

##Tools
emerge app-admin/sysklogd sys-process/cronie sudo layman
sed -i 's/\# \%wheel ALL=(ALL) ALL/\%wheel ALL=(ALL) ALL/g' /etc/sudoers
crontab /etc/crontab
echo "更改root密码 "
passwd

##GRUB
read -p "是否是UEFI启动？输入y或回车为legacy安装grub " TMP
if [ "$TMP" == y ];then
	echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	emerge grub
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Gentoo
else
	emerge grub
	fdisk -l
	read -p "Input the disk you want to install the grub  " GRUB
	grub-install --target=i386-pc $GRUB
fi

if [ $2 == systemd ];then
	sed -i 's/\# GRUB_CMDLINE_LINUX=\"init=\/usr\/lib\/systemd\/systemd\"/GRUB_CMDLINE_LINUX=\"init=\/usr\/lib\/systemd\/systemd\"/g' /etc/default/grub
	ln -sf /proc/self/mounts /etc/mtab
	systemd-machine-id-setup
	systemctl enable NetworkManager
else
	rc-update add NetworkManager default
fi

grub-mkconfig -o /boot/grub/grub.cfg

##添加用户
read -p "输入你想创建的用户名(仅限小写字母，不推荐使用符号) :" USER
useradd -m -G users,wheel,audio,cdrom,floppy,portage,usb,video $USER
echo "设置用户密码"
passwd $USER

##安装桌面环境
if [ "$PROFILE" == 5 ];then
	emerge gnome-shell gdm gnome-termianl
	gpasswd -a $USER gdm
	systemctl enable gdm
elif [ "$PROFILE" == 6 ];then
	emerge --autounmask-write kde-plasma/plasma-meta sddm konsole plasma-pa plasma-nm
	etc-update --automode -3
	emerge kde-plasma/plasma-meta sddm konsole plasma-pa plasma-nm
	sed -i 's/DISPLAYMANAGER=\"xdm\"/DISPLAYMANAGER=\"sddm\"/g' /etc/conf.d/xdm
	usermod -a -G video sddm
	gpasswd -a $USER sddm
	sddm --example-config > /etc/sddm.conf
	rc-update add xdm default
elif [ "$PROFILE" == 7 ];then
	emerge --autounmask-write kde-plasma/plasma-meta sddm konsole plasma-pa plasma-nm
	etc-update --automode -3
	emerge kde-plasma/plasma-meta sddm konsole plasma-pa plasma-nm
	systemctl enable sddm
	usermod -a -G video sddm
	gpasswd -a $USER sddm
	sddm --example-config > /etc/sddm.conf
fi

##Bumblebee双显卡配置
if [ $3 == 3 ];then
	echo "=sys-power/bbswitch-9999 **
	=x11-misc/bumblebee-9999 **
	=x11-misc/primus-0.2 ~amd64" >> /etc/portage/package.accept_keywords
	emerge --autounmask-write bbswitch primus bumblebee
	etc-update --automode -3
	emerge bbswitch primus bumblebee
	sed -i 's/Bridge=auto/Bridge=primus/g' /etc/bumblebee/bumblebee.conf
	sed -i 's/PMMethod=auto/PMMethod=bbswitch/g' /etc/bumblebee/bumblebee.conf
	sed -i '5,7d' /etc/init.d/bumblebee
	if [ $2 == systemd ];then
		systemctl enable bumblebeed
	else
		rc-update add bumblebee default
	fi
		gpasswd -a $USER bumblebee
fi

##自定义
read -p "回车进入系统运行命令,如果没有选择自动安装桌面的profile请在此步骤按照wiki安装桌面(配置完之后exit即可退出）"
bash
echo "谢谢使用 有用的话请赏个star"
