#!/bin/bash

##以下源地址可以自己替换以避免下载速度慢的问题
STAGE_MIRRORS=http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/
GENTOO_MIRRORS=https://mirrors.ustc.edu.cn/gentoo/
PORTAGE_MIRRORS=rsync://rsync.mirrors.ustc.edu.cn/gentoo-portage/

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
then read -p "输入你想使用的文件系统:btrfs,xfs,jfs 回车或者其他字符将默认格式化为ext4(请事先确认当前系统支持此文件系统且有相应工具) " FILESYSTEM
    if [ "$FILESYSTEM" ==  ]
    then mkfs.ext4 $ROOT
    elif [ "$FILESYSTEM" == btrfs ]
    then mkfs.btrfs $ROOT -f
    elif [ "$FILESYSTEM" == xfs ]
    then mkfs.xfs $ROOT
    elif [ "$FILESYSTEM" == jfs ]
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
then LATEST=$(wget -q $STAGE_MIRRORS/current-stage3-amd64/ && grep -o stage3-amd64-.........tar.bz2 index.html | head -1)
wget $STAGE_MIRRORS/current-stage3-amd64/$LATEST
echo 解压中...
tar xjpf $LATEST --xattrs --numeric-owner
else 
LATEST=$(wget -q $STAGE_MIRRORS/current-stage3-amd64-systemd/ && grep -o stage3-amd64-systemd-.........tar.bz2 index.html | head -1)
wget $STAGE_MIRRORS/current-stage3-amd64-systemd/$LATEST
echo 解压中...
tar xjpf $LATEST --xattrs --numeric-owner
fi

rm $LATEST

if [ "$BOOT" == y ]
then umount $boot > /dev/null
     mount -v $boot /mnt/gentoo/boot
fi

##配置make.conf
sed -i 's/CFLAGS=\"-O2 -pipe\"/CFLAGS=\"-march=native -O2 -pipe\"/g' /mnt/gentoo/etc/portage/make.conf ##你可以在此根据你的CPU修改优化例如改成-march=haswell -O3 -pipe
echo "GENTOO_MIRRORS=\"$GENTOO_MIRRORS\" ">> /mnt/gentoo/etc/portage/make.conf ##如果此软件源巨慢或者你在国外 可以自行修改
echo "L10N=\"en-US zh-CN\"
LINGUAS=\"en_US zh_CN\"" >> /mnt/gentoo/etc/portage/make.conf

##Video Cards
VIDEO=6
while (($VIDEO!=1&&$VIDEO!=2&&$VIDEO!=3&&$VIDEO!=4&&$VIDEO!=5));do
echo "输入对应的显卡配置
[1]  Intel
[2]  Nvidia
[3]  Intel/Nvidia
[4]  AMD/ATI
[5]  Intel/AMD"
read VIDEO
if [ "$VIDEO" == 1 ]
then echo VIDEO_CARDS=\"intel i965\" >> /mnt/gentoo/etc/portage/make.conf
elif [ "$VIDEO" == 2 ]
then echo VIDEO_CARDS=\"nvidia\" >> /mnt/gentoo/etc/portage/make.conf
elif [ "$VIDEO" == 3 ]
then echo VIDEO_CARDS=\"intel i965 nvidia\" >> /mnt/gentoo/etc/portage/make.conf
elif [ "$VIDEO" == 4 ]
then echo VIDEO_CARDS=\"radeon\" >> /mnt/gentoo/etc/portage/make.conf
elif [ "$VIDEO" == 5 ]
then echo VIDEO_CARDS=\"intel i965 radeon\" >> /mnt/gentoo/etc/portage/make.conf
else echo 请输入正确数字
fi
done

mkdir /mnt/gentoo/etc/portage/repos.conf
echo "[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = rsync
sync-uri = $PORTAGE_MIRRORS
auto-sync = yes" > /mnt/gentoo/etc/portage/repos.conf/gentoo.conf ##同上上

##Chroot
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
rm /mnt/gentoo/etc/resolv.conf > /dev/null
cp /etc/resolv.conf /mnt/gentoo/etc/
cd root/
wget https://raw.githubusercontent.com/YangMame/Gentoo-Installer/master/Config.sh
chmod +x Config.sh
rm /mnt/gentoo/etc/fstab
chroot /mnt/gentoo /root/Config.sh
