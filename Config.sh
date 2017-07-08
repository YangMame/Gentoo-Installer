#!/bin/bash

source /etc/profile

##更新
emerge-webrsync
emerge --sync
eselect news read
eselect profile list
read -p "Input the num you want to use " TMP
eselect profile set $TMP
read -p "ENTER to update the system"
emerge -uvDN @world

##时区
echo "Asia/Shanghai" > /etc/timezone
emerge --config sys-libs/timezone-data
echo "en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale list
read -p "Which locale you want to use " TMP
eselect locale set $TMP

##内核
read -p "Do you want to use the latest kernel ? " TMP
if [ "$TMP" == y ]
then echo sys-kernel/gentoo-sources > /etc/portage/package.accept_keywords
fi
emerge gentoo-sources genkernel
while (($TMP!=1&&$TMP!=2&&$TMP!=3));do
read -p "Which way you want to  compile
[1]  Use Ubuntu kernel config (If you are a new user try this)
[2]  Use genkernel all
[3]  I will config by myself" TMP
if (($TMP==1))
then wget https://raw.githubusercontent.com/yangxins/Gentoo-Installer/master/Kernel-Config/Ubuntu.config
mv Ubuntu.config /usr/src/linux/.config
cd /usr/src/linux
read -p	"Are you using btrfs  filesystem" tmp ##在这里你可以修改成你使用的文件系统
if [ "$tmp" == y ]
then emerge btrfs-progs
fi
echo "If you are using btrfs or other filesystem pelease select it or just exit it"
make menuconfig
make -j8 && make modules_install ##根据你CPU修改-j8 推荐核数x2
make install
genkernel --install initramfs
elif (($TMP==2))
then genkernel all
elif (($TMP==3))
then cd /usr/src/linux
read -p "Download form internet ? " tmp
if [ "$tmp" == y ]
then read -p "Input the link to download :" tmp
wget $tmp -O .config
fi
make menuconfig
make -j8 && make modul
make install
genkernel --install initramfses_install
else echo Error ! Input the currect number !
fi
done
emerge  sys-kernel/linux-firmware

##NetWork
emerge networkmanager
systemctl enable NetworkManager
read -p "Input your hostname  " TMP
echo $TMP > /etc/hostname

##Tools
emerge app-admin/sysklogd
emerge sys-process/cronie
crontab /etc/crontab


##GRUB
read -p "Are you uefi ? " TMP
if [ "$tmp" == y ]
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
sed -i 's/## GRUB_CMDLINE_LINUX=\"init=/usr/lib/systemd/systemd\"/GRUB_CMDLINE_LINUX=\"init=/usr/lib/systemd/systemd\""' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg