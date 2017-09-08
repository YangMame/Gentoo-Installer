#!/bin/bash

##分区
umount /mnt/gentoo > /dev/null
rm -r /mnt/gentoo > /dev/null
mkdir -v /mnt/gentoo

read -p "是否进行分区？（输入y使用cfdisk进行分区，回车跳过） " TMP
if [ "$TMP" == y ]
then fdisk -l
read -p "输入你想进行分区的磁盘/dev/sdX： " TMP
cfdisk $TMP
fi

fdisk -l
read -p "输入根目录挂载点：  " ROOT
read -p "是否格式化？ （y或回车）  " TMP
if [ "$TMP" == y ]
then read -p "输入你想使用的文件系统，回车或输入了不支持的文件系统将格式化为ext4（小写字母，请事先确保当前系统支持此文件系统）  " FILESYSTEM
    if [ "$FILESYSTEM" ==  ]
    then mkfs.ext4 $ROOT
    else if [ "$FILESYSTEM" == btrfs ]
    then mkfs.btrfs $ROOT -f
    else if [ "$FILESYSTEM" == xfs ]
    then mkfs.xfs $ROOT
    else if [ "$FILESYSTEM" == jfs ]
    then mkfs.jfs $ROOT
    else mkfs.ext4 $ROOT
    fi
fi
umount $ROOT > /dev/null
mount -v $ROOT /mnt/gentoo

read -p "是否有Boot分区（UEFI必选，输入efi分区即可）y或回车  " BOOT
if [ "$BOOT" == y ]
then fdisk -l
    read -p "输入挂载点:  " boot
    read -p "是否格式化? (y或回车  " TMP
    if [ "$TMP" == y ]
    then mkfs.fat -F32 $boot
    fi
fi

read -p "是否有交换空间？Gentoo强烈建议使用 (y或回车  " SWAP
if [ "$SWAP" == y ]
then fdisk -l
    read -p "输入挂载点:  " SWAP
    read -P "是否格式化 ? (y or Enter  " TMP
    if [ "$TMP" == y ]
    then mkswap $SWAP > /dev/null
    fi
    swapon $SWAP > /dev/null
fi

##安装文件
read -p "输入y使用openRC 回车使用systemd " INIT
cd /mnt/gentoo
rm index.html > /dev/null
if [ "$INIT" == y ]
then LATEST=$(wget -q http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64/ && grep -o stage3-amd64-.........tar.bz2 index.html | head -1)
wget http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64/$LATEST
tar xvjpf $LATEST --xattrs --numeric-owner
else 
LATEST=$(wget -q http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-systemd/ && grep -o stage3-amd64-systemd-.........tar.bz2 index.html | head -1)
wget http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-systemd/$LATEST
tar xvjpf $LATEST --xattrs --numeric-owner
fi

if [ "$BOOT" == y ]
then umount $boot > /dev/null
     mount -v $boot /mnt/gentoo/boot
fi

##配置make.conf
sed -i 's/CFLAGS=\"-O2 -pipe\"/CFLAGS=\"-march=native -O2 -pipe\"/g' /mnt/gentoo/etc/portage/make.conf ##你可以在此根据你的CPU修改优化例如改成-march=haswell -O3 -pipe
echo "GENTOO_MIRRORS=\"https://mirrors.ustc.edu.cn/gentoo/\" ">> /mnt/gentoo/etc/portage/make.conf ##如果此软件源巨慢或者你在国外 可以自行修改
echo "L10N=\"en-US zh-CN\"
LINGUAS=\"en_US zh_CN\"" >> /mnt/gentoo/etc/portage/make.conf

##Video Cards


mkdir /mnt/gentoo/etc/portage/repos.conf
echo "[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = rsync
sync-uri = rsync://rsync.mirrors.ustc.edu.cn/gentoo-portage/
auto-sync = yes" >> /mnt/gentoo/etc/portage/repos.conf/gentoo.conf ##同上上

##Chroot
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
cp /etc/resolv.conf /mnt/gentoo/etc/
cd root/
wget https://raw.githubusercontent.com/YangMame/Gentoo-Installer/master/Config.sh
chmod +x Config.sh
rm /mnt/gentoo/etc/fstab
chroot /mnt/gentoo /root/Config.sh