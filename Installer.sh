#!/bin/bash

##分区
mkdir /mnt/gentoo
read -p "Do you want to adjust the partition ? (Input y to use fdisk or Enter to continue:  " TMP
if [ "$TMP" == y ]
then fdisk -l
read -p "Which disk do you want to adjust ? (/dev/sdX:  " DISK
fdisk $DISK
fi
fdisk -l
read -p "Input the / mount point:  " ROOT
read -p "Format it ? (y or Enter  " TMP
if [ "$TMP" == y ]
then read -p "Input y to use ext4 defalut to use btrfs  " TMP
if [ "$TMP" == y ]
then mkfs.ext4 $ROOT
else mkfs.btrfs $ROOT -f
fi
fi
mount $ROOT /mnt/gentoo
read -p "Do you have the /boot mount point? (y or Enter  " BOOT
if [ "$BOOT" == y ]
then fdisk -l
read -p "Input the /boot mount point:  " BOOT
read -p "Format it ? (y or Enter  " TMP
if [ "$TMP" == y ]
then mkfs.fat -F32 $BOOT
fi
mkdir /mnt/gentoo/boot
mount $BOOT /mnt/gentoo/boot
fi
read -p "Do you have the swap partition ? (y or Enter  " SWAP
if [ "$SWAP" == y ]
then fdisk -l
read -p "Input the swap mount point:  " SWAP
read -P "Format it ? (y or Enter  " TMP
if [ "$TMP" == y ]
then mkswap $SWAP
fi
swapon $SWAP
fi

##安装文件
cd /mnt/gentoo
wget -c -r -np -k -L -p http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-systemd/
cp mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-systemd/stage3-amd64-systemd*.tar.bz2 install.tar.bz2
tar xvjpf install.tar.bz2 --xattrs --numeric-owner
rm -r mirrors.ustc.edu.cn/ install.tar.bz2

##配置make.conf
sed -i 's/CFLAGS=\"-O2 -pipe\"/CFLAGS=\"-march=native -O2 -pipe\"/g' /mnt/gentoo/etc/portage/make.conf ##你可以在此根据你的CPU修改优化例如改成-march=haswell -O3 -pipe（主要是因为我懒 后期会加上）
echo "GENTOO_MIRRORS=\"https://mirrors.ustc.edu.cn/gentoo/\" ">> /mnt/gentoo/etc/portage/make.conf ##如果此软件源巨慢或者你在国外 可以自行修改
echo "L10N=\"en-US zh-CN\"
LINGUAS=\"en_US zh_CN\"" >> /mnt/gentoo/etc/portage/make.conf
read -p "Edit the make.conf if you want to add your video cards like VIDEO_CARDS=\"intel\" VIDEO_CARDS=\"nvidia\" or VIDEO_CARDS=\"intel i965 nvidia\"" TMP ##懒得加选择  其实无所谓 可以自己手动安装
if [ "$TMP" == y ]
then nano  /mnt/gentoo/etc/portage/make.conf
fi
mkdir /mnt/gentoo/etc/portage/repos.conf
echo "[DEFAULT]                                                     
main-repo = gentoo                                            
                                                              
[gentoo]                                                      
location = /usr/portage                                       
sync-type = rsync                                             
sync-uri = rsync://rsync.mirrors.ustc.edu.cn/gentoo-portage/  
auto-sync = yes" >> /mnt/gentoo/etc/portage/repos.conf/gentoo.conf ##同上上

##chroot
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys 
mount --rbind /dev /mnt/gentoo/dev 
mount --make-rslave /mnt/gentoo/dev
cp /etc/resolv.conf /mnt/gentoo/etc/
cd root/
wget https://raw.githubusercontent.com/yangxins/Gentoo-Installer/master/Config.sh
chmod +x Config.sh
rm /mnt/gentoo/etc/fstab
genfstab -U -p /mnt/gentoo >> /mnt/gentoo/etc/fstab
chroot /mnt/gentoo /root/Config.sh