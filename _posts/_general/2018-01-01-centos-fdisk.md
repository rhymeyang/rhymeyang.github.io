---
layout: post
title:  "centos7分区 格式化挂载磁盘"
date:   2018-01-02 02:08:04 +0800
excerpted: |
    fdisk 又用到了...
tags: ['环境配置','centos', 'linux']
categories: general
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}


安装centos时，通常linux系统分区默认为3个分区，主分区最多4个，其他可根据自己的需要挂载。

+ / 根分区，通常10-100G左右（根据总磁盘大小情况）
+ /boot 系统操作分区 （100-500MB 足矣）
+ /swap 虚拟内存暂存分区（通常是内存的2倍）

如果有剩下的磁盘就保留，后期再挂载。安装完系统后就开始格式化剩下的分区，并挂载指派出来。

##  列出所有的硬盘

分别是/dev/sda和/dev/sdb，sda是系统分区，sdb是存储数据分区。

{% highlight shell %}
sudo fdisk -l
{% endhighlight %}

    磁盘 /dev/sdb：21.5 GB, 21474836480 字节，41943040 个扇区
    Units = 扇区 of 1 * 512 = 512 bytes
    扇区大小(逻辑/物理)：512 字节 / 512 字节
    I/O 大小(最小/最佳)：512 字节 / 512 字节

    磁盘 /dev/sda：32.2 GB, 32212254720 字节，62914560 个扇区
    Units = 扇区 of 1 * 512 = 512 bytes
    扇区大小(逻辑/物理)：512 字节 / 512 字节
    I/O 大小(最小/最佳)：512 字节 / 512 字节
    磁盘标签类型：dos
    磁盘标识符：0x0009ab4c

       设备 Boot      Start         End      Blocks   Id  System
    /dev/sda1   *        2048     2099199     1048576   83  Linux
    /dev/sda2         2099200    62914559    30407680   8e  Linux LVM

    磁盘 /dev/mapper/cl-root：29.0 GB, 28982640640 字节，56606720 个扇区
    Units = 扇区 of 1 * 512 = 512 bytes
    扇区大小(逻辑/物理)：512 字节 / 512 字节
    I/O 大小(最小/最佳)：512 字节 / 512 字节

    磁盘 /dev/mapper/cl-swap：2147 MB, 2147483648 字节，4194304 个扇区
    Units = 扇区 of 1 * 512 = 512 bytes
    扇区大小(逻辑/物理)：512 字节 / 512 字节
    I/O 大小(最小/最佳)：512 字节 / 512 字节


可以看到20G的数据磁盘 sdb

## 执行分区

{% highlight shell %}
sudo fdisk -S 56 /dev/sdb

sudo fdisk -l

# 格式化分区
# mkfs.ext3 /dev/sdb
# mkfs.ext4 /dev/sdb
mkfs.xfs -f /dev/sdb
{% endhighlight %}


## 挂载磁盘

{% highlight shell %}
sudo echo '/dev/sdb /www xfs defaults 0 0' >> /etc/fstab

# 新建挂载目录
mkdir /www 

# 挂载磁盘
mount -a

# 查看挂载是否成功
df -h
{% endhighlight %}


>直接挂载: `mount /dev/sdb /www`


