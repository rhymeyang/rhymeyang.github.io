---
layout: post
title:  "Docker系列 14 容器如何访问外部世界"
date:   2017-08-06 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}

## 相关命令

{% highlight shell %}
docker build -t localtcpdump .
docker run --rm -v /opt/bin:/target localtcpdump
docker run --rm -v /opt/bin:/target ulexus/install-tcpdump

docker run -it busybox
ip r
{%endhighlight%}

容器与外部世界通信。这里涉及两个方向：
+ 容器访问外部世界
+ 外部世界访问容器

## 容器访问外部世界

在我们当前的实验环境下，docker host 是可以访问外网的。


{% highlight shell %}
docker run -it busybox
ip r

ping -c 3 www.bing.com
{%endhighlight%}

__容器默认就能访问外网__

d0httpd1 位于 docker0 这个私有 bridge 网络中（172.17.0.0/16），当 d0httpd1 从容器向外 ping 时，数据包是怎样到达 bing.com 的呢？

这里的关键就是 NAT。我们查看一下 docker host 上的 iptables 规则：

{% highlight shell %}
$ iptables -t nas -S
...
-A POSTROUTING -s 172.18.0.0/16 ! -o br-d430eab46516 -j MASQUERADE
-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
...
{% endhighlight %}

在 NAT 表中，有这么一条规则：

  -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE

其含义是：如果网桥 docker0 收到来自 172.17.0.0/16 网段的外出包，把它交给 MASQUERADE 处理。而 MASQUERADE 的处理方式是将包的源地址替换成 host 的地址发送出去，即做了一次网络地址转换（NAT）。

下面我们通过 `tcpdump` 查看地址是如何转换的。先查看 docker host 的路由表：


{% highlight shell %}
/ # ip r
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0 scope link  src 172.17.0.3 

{% endhighlight %}

默认路由通过 eth0 发出去，所以我们要同时监控 eth0 和 br-d430eab46516 上的 icmp（ping）数据包。

当 http2 ping bing.com 时，tcpdump 输出如下：

{% highlight shell %}
$ tcpdump -i docker0 -n icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on docker0, link-type EN10MB (Ethernet), capture size 262144 bytes
02:16:03.749073 IP 172.17.0.3 > 202.89.233.100: ICMP echo request, id 1792, seq 0, length 64
02:16:03.789452 IP 202.89.233.100 > 172.17.0.3: ICMP echo reply, id 1792, seq 0, length 64
02:16:04.749523 IP 172.17.0.3 > 202.89.233.100: ICMP echo request, id 1792, seq 1, length 64
02:16:04.789413 IP 202.89.233.100 > 172.17.0.3: ICMP echo reply, id 1792, seq 1, length 64
02:16:05.749962 IP 172.17.0.3 > 202.89.233.100: ICMP echo request, id 1792, seq 2, length 64
02:16:05.790665 IP 202.89.233.100 > 172.17.0.3: ICMP echo reply, id 1792, seq 2, length 64

{% endhighlight %}

docker0 收到 必须busybox 的 ping 包，源地址为容器 IP 172.17.0.3，这没问题，交给 MASQUERADE 处理。这时，在 eth0 上我们看到了变化：

{% highlight shell %}
# 机器没有设备 eth0
$ tcpdump -i eth0 -n icmp

{% endhighlight %}



