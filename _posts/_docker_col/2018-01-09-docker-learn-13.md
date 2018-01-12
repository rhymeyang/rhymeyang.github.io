---
layout: post
title:  "Docker系列 13 理解容器之间的连通性"
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

docker network connect my_net2 0397b68b16ee

docker run -d -it --name=web1 httpd
{%endhighlight%}


当前 docker host 的网络拓扑结构如下图所示，今天我们将讨论这几个容器之间的连通性。

![docker host 的网络拓扑结构 @x60]({{ '/net_con_str.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

两个 busybox 容器都挂在 my_net2 上，应该能够互通，我们验证一下：

{% highlight shell %}
$ docker exec -it 88099301221b sh
/ # ping -c 3 172.22.16.2
PING 172.22.16.2 (172.22.16.2): 56 data bytes
64 bytes from 172.22.16.2: seq=0 ttl=64 time=0.048 ms
64 bytes from 172.22.16.2: seq=1 ttl=64 time=0.048 ms
64 bytes from 172.22.16.2: seq=2 ttl=64 time=0.048 ms

--- 172.22.16.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.048/0.048/0.048 ms
{%endhighlight%}

可见同一网络中的容器、网关之间都是可以通信的。

my_net2 与默认 bridge 网络能通信吗？

从拓扑图可知，两个网络属于不同的网桥，应该不能通信，我们通过实验验证一下，让 busybox 容器 ping httpd 容器：

{% highlight shell %}
/ # ping -c 4 172.17.0.3
PING 172.17.0.3 (172.17.0.3): 56 data bytes

--- 172.17.0.3 ping statistics ---
4 packets transmitted, 0 packets received, 100% packet loss
{%endhighlight%}

确实 ping 不通，符合预期。

“等等！不同的网络如果加上路由应该就可以通信了吧？”我已经听到有读者在建议了。

这是一个非常非常好的想法。

确实，如果 host 上对每个网络的都有一条路由，同时操作系统上打开了 ip forwarding，host 就成了一个路由器，挂接在不同网桥上的网络就能够相互通信。下面我们来看看 docker host 满不满足这些条件呢？

ip r 查看 host 上的路由表：

{% highlight shell %}
$ ip r
default via 192.168.1.1 dev ens33  proto static  metric 100 
172.17.0.0/16 dev docker0  proto kernel  scope link  src 172.17.0.1 
172.18.0.0/16 dev br-bb411a0ddf01  proto kernel  scope link  src 172.18.0.1 
172.22.16.0/24 dev br-7d07ffb21af0  proto kernel  scope link  src 172.22.16.1 
192.168.1.0/24 dev ens33  proto kernel  scope link  src 192.168.1.108  metric 100 

$ ip route
default via 192.168.1.1 dev ens33  proto static  metric 100 
172.17.0.0/16 dev docker0  proto kernel  scope link  src 172.17.0.1 
172.18.0.0/16 dev br-bb411a0ddf01  proto kernel  scope link  src 172.18.0.1 
172.22.16.0/24 dev br-7d07ffb21af0  proto kernel  scope link  src 172.22.16.1 
192.168.1.0/24 dev ens33  proto kernel  scope link  src 192.168.1.108  metric 100 
{%endhighlight%}


172.17.0.0/16 和 172.22.16.0/24 两个网络的路由都定义好了。再看看 ip forwarding：

{% highlight shell %}
$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
{%endhighlight%}
    
ip forwarding 也已经启用了。

条件都满足，为什么不能通行呢？

我们还得看看 iptables：

{% highlight shell %}
$ iptables-save
......
-A DOCKER-ISOLATION -i docker0 -o br-7d07ffb21af0 -j DROP
-A DOCKER-ISOLATION -i br-7d07ffb21af0 -o docker0 -j DROP
-A DOCKER-ISOLATION -i br-bb411a0ddf01 -o br-7d07ffb21af0 -j DROP
-A DOCKER-ISOLATION -i br-7d07ffb21af0 -o br-bb411a0ddf01 -j DROP
-A DOCKER-ISOLATION -i docker0 -o br-bb411a0ddf01 -j DROP
-A DOCKER-ISOLATION -i br-bb411a0ddf01 -o docker0 -j DROP
-A DOCKER-ISOLATION -j RETURN
......
{% endhighlight %}

原因就在这里了：iptables DROP 掉了网桥 docker0 与 br-7d07ffb21af0 之间双向的流量。

从规则的命名 DOCKER-ISOLATION 可知 docker 在设计上就是要隔离不同的 netwrok。

那么接下来的问题是：怎样才能让 busybox 与 httpd 通信呢？

答案是：为 httpd 容器添加一块 net_my2 的网卡。这个可以通过`docker network connect` 命令实现。


{% highlight shell %}
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
88099301221b        busybox             "sh"                     About an hour ago   Up About an hour                        romantic_spence
3613c3918ea3        busybox             "sh"                     About an hour ago   Up About an hour                        admiring_poitras
07d6759fa9fe        httpd               "httpd-foreground"       14 hours ago        Up 14 hours         80/tcp              festive_kirch
0397b68b16ee        httpd               "httpd-foreground"       14 hours ago        Up 14 hours         80/tcp              laughing_fermat
b305cc1b397d        progrium/stress     "/usr/bin/stress -..."   15 hours ago        Up 15 hours                             objective_keller


docker network connect my_net2 0397b68b16ee

$ docker exec -it 0397b68b16ee bash
root@0397b68b16ee:/usr/local/apache2# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
20: eth0@if21: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:03 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.3/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:3/64 scope link 
       valid_lft forever preferred_lft forever
34: eth1@if35: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:16:10:03 brd ff:ff:ff:ff:ff:ff
    inet 172.22.16.3/24 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe16:1003/64 scope link 
       valid_lft forever preferred_lft forever


{% endhighlight %}


容器中增加了一个网卡 eth1，分配了 my_net2 的 IP 172.22.16.3。现在 busybox 应该能够访问 httpd 了，验证一下：


{% highlight shell %}
$ docker exec -it 88099301221b sh
/ # ping -c 3 172.22.16.3
PING 172.22.16.3 (172.22.16.3): 56 data bytes
64 bytes from 172.22.16.3: seq=0 ttl=64 time=0.217 ms
64 bytes from 172.22.16.3: seq=1 ttl=64 time=0.083 ms
64 bytes from 172.22.16.3: seq=2 ttl=64 time=0.060 ms

--- 172.22.16.3 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.060/0.120/0.217 ms
/ # wget 172.22.16.3
Connecting to 172.22.16.3 (172.22.16.3:80)
index.html           100% |***********************************************************************************************|    45   0:00:00 ETA
/ # cat index.html 
<html><body><h1>It works!</h1></body></html>

{% endhighlight %}


busybox 能够 ping 到 httpd，并且可以访问 httpd 的 web 服务。当前网络结构如图所示：

![网络结构 @x60]({{ '/net_con_str_2.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})


## 容器间通信的三种方式

容器之间可通过 IP，Docker DNS Server 或 joined 容器三种方式通信。

### IP 通信

从上一节的例子可以得出这样一个结论：两个容器要能通信，必须要有属于同一个网络的网卡。

满足这个条件后，容器就可以通过 IP 交互了。具体做法是在容器创建时通过 `--network` 指定相应的网络，或者通过 `docker network connect` 将现有容器加入到指定网络。

### Docker DNS Server

通过 IP 访问容器虽然满足了通信的需求，但还是不够灵活。因为我们在部署应用之前可能无法确定 IP，部署之后再指定要访问的 IP 会比较麻烦。对于这个问题，可以通过 docker 自带的 DNS 服务解决。

从 Docker 1.10 版本开始，docker daemon 实现了一个内嵌的 DNS server，使容器可以直接通过“容器名”通信。方法很简单，只要在启动时用 --name 为容器命名就可以了。

下面启动两个容器 bbox1 和 bbox2：

{% highlight shell %}
docker run -it --network=my_net2 --name=bbox1 busybox
docker run -it --network=my_net2 --name=bbox2 busybox
{% endhighlight %}

然后，bbox2 就可以直接 ping 到 bbox1 了：


{% highlight shell %}
$ docker  exec  -it bbox2 sh
/ # ping -c 3 bbox1
PING bbox1 (172.22.16.5): 56 data bytes
64 bytes from 172.22.16.5: seq=0 ttl=64 time=0.108 ms
64 bytes from 172.22.16.5: seq=1 ttl=64 time=0.370 ms
64 bytes from 172.22.16.5: seq=2 ttl=64 time=0.125 ms

--- bbox1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.108/0.201/0.370 ms

{% endhighlight %}

使用 docker DNS 有个限制：只能在 user-defined 网络中使用。也就是说，默认的 bridge 网络是无法使用 DNS 的。下面验证一下：

创建 bbox3 和 bbox4，均连接到 bridge 网络。

{% highlight shell %}
docker run -it --name=bbox3 busybox

docker run -it --name=bbox4 busybox
{% endhighlight %}

bbox4 无法 ping 到 bbox3。

### joined 容器

joined 容器是另一种实现容器间通信的方式。

joined 容器非常特别，它可以使两个或多个容器共享一个网络栈，共享网卡和配置信息，joined 容器之间可以通过 127.0.0.1 直接通信。请看下面的例子：

先创建一个 httpd 容器，名字为 web1。

{% highlight shell %}
docker run -d -it --name=web1 httpd
{% endhighlight %}
    

然后创建 busybox 容器并通过 `--network=container:web1` 指定 jointed 容器为 web1：

请注意 busybox 容器中的网络配置信息，下面我们查看一下 web1 的网络：

{% highlight shell %}
$ docker run -d  --name=web1 httpd
89201c8e8dc54b5933be88fb8646af314ca8b46c1a41d301128f548cd3065f56
$ docker run -it --network=container:web1 busybox
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
42: eth0@if43: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:2/64 scope link 
       valid_lft forever preferred_lft forever


$ docker exec -it web1 bash
root@89201c8e8dc5:/usr/local/apache2# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
42: eth0@if43: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:2/64 scope link 
       valid_lft forever preferred_lft forever

{% endhighlight %}

busybox 和 web1 的网卡 mac 地址与 IP 完全一样，它们共享了相同的网络栈。busybox 可以直接用 127.0.0.1 访问 web1 的 http 服务。

joined 容器非常适合以下场景：

1. 不同容器中的程序希望通过 loopback 高效快速地通信，比如 web server 与 app server。
2. 希望监控其他容器的网络流量，比如运行在独立容器中的网络监控程序。


