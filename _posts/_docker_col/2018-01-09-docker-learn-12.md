---
layout: post
title:  "Docker系列 12 容器网络"
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

yum install bridge-utils

brctl show
docker network ls

docker network create --driver bridge my_net

docker run -it --network=none busybox
docker run -it --network=host busybox

docker network create --driver bridge --subnet 172.22.16.0/24 --gateway 172.22.16.1 my_net2

docker run -it --network=my_net2 --ip 172.22.16.88 busybox

docker pull httpd:2.2
{%endhighlight%}

sequence 

+ docker run -it --network=host --name='hostbusy1' busybox 
+ docker run -it --name='d0busy1' busybox
+ docker run -it --name='d0httpd1' httpd:2.2

## none 和 host 网络的适用场景

+ Docker 提供的几种原生网络
+ 创建自定义网络
+ 容器之间通信
+ 容器与外界交互

Docker 网络从覆盖范围可分为单个 host 上的容器网络和跨多个 host 的网络，本章重点讨论前一种。

Docker 安装时会自动在 host 上创建三个网络，我们可用 docker network ls 命令查看：

{% highlight shell %}
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
2ac6093c3709        bridge              bridge              local
5dc87272633f        host                host                local
773b33d8d6e3        none                null                local
{% endhighlight %}


### none 网络

故名思议，none 网络就是什么都没有的网络。挂在这个网络下的容器除了 `lo`，没有其他任何网卡。容器创建时，可以通过 `--network=none` 指定使用 none 网络。

{% highlight shell %}
$ docker run -it --network=none busybox
/ # ifconfig
lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

{% endhighlight %}


这样一个封闭的网络有什么用呢？

其实还真有应用场景。封闭意味着隔离，一些对安全性要求高并且不需要联网的应用可以使用 none 网络。

比如某个容器的唯一用途是生成随机密码，就可以放到 none 网络中避免密码被窃取。

当然大部分容器是需要网络的，我们接着看 host 网络。


### host 网络

连接到 host 网络的容器共享 Docker host 的网络栈，容器的网络配置与 host 完全一样。可以通过 `--network=host` 指定使用 host 网络。

{% highlight shell %}
$ docker run -it --network=host busybox
/ # ip l
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast qlen 1000
    link/ether 00:0c:29:78:58:74 brd ff:ff:ff:ff:ff:ff
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue 
    link/ether 02:42:f9:2e:dc:f7 brd ff:ff:ff:ff:ff:ff
17: veth4ba89ce@if16: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue master docker0 
    link/ether da:69:0a:7b:a0:53 brd ff:ff:ff:ff:ff:ff
{% endhighlight %}


在容器中可以看到 host 的所有网卡，并且连 `hostname` 也是 host 的。host 网络的使用场景又是什么呢？

直接使用 Docker host 的网络最大的好处就是性能，如果容器对网络传输效率有较高要求，则可以选择 host 网络。当然不便之处就是牺牲一些灵活性，比如要考虑端口冲突问题，Docker host 上已经使用的端口就不能再用了。

Docker host 的另一个用途是让容器可以直接配置 host 网路。比如某些跨 host 的网络解决方案，其本身也是以容器方式运行的，这些方案需要对网络进行配置，比如管理 iptables。

## 学容器必须懂 bridge 网络 

本节学习应用最广泛也是默认的 bridge 网络。

Docker 安装时会创建一个 命名为 docker0 的 linux bridge。如果不指定`--network`，创建的容器默认都会挂到 docker0 上。

{% highlight shell %}
[root@dockerserver ~]# docker run -it --network=host busybox
/ # brctl show
bridge name bridge id   STP enabled interfaces
docker0   8000.0242f92edcf7 no    veth4ba89ce
{% endhighlight %}

当前 docker0 上没有任何其他网络设备，我们创建一个容器看看有什么变化。

{% highlight shell %}
[root@dockerserver ~]# brctl show
bridge name bridge id   STP enabled interfaces
docker0   8000.0242f92edcf7 no    veth4ba89ce
{%endhighlight%}

一个新的网络接口 `veth4ba89ce` 被挂到了 `docker0` 上， `veth4ba89ce` 就是新创建容器的虚拟网卡。

{% highlight shell %}
yum install bridge-utils
{% endhighlight %}


{% highlight shell %}
# busybox
$ docker exec -it 0397b68b16ee  /bin/sh
# httpd
$ docker exec -it d0httpd1 bash
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

{% endhighlight %}

容器有一个网卡 eth0@if21。大家可能会问了，为什么不是 veth4ba89ce 呢？

实际上 `eth0@if21` 和 `veth4ba89ce` 是一对 veth pair。veth pair 是一种成对出现的特殊网络设备，可以把它们想象成由一根虚拟网线连接起来的一对网卡，网卡的一头（eth0@if21）在容器中，另一头（veth4ba89ce）挂在网桥 docker0 上，其效果就是将 eth0@if21 也挂在了 docker0 上。

我们还看到 eth0@if21 已经配置了 IP 172.17.0.3，为什么是这个网段呢？让我们通过 docker network inspect bridge 看一下 bridge 网络的配置信息:

{% highlight shell %}
$ docker network inspect bridge
[
    {
        "Name": "bridge",
        "Id": "2ac6093c3709b3bd027129eb52aa4bc74f2e4e612f4050d2b493eb2926c8bf18",
        "Created": "2017-06-30T05:20:41.715140335-04:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Containers": {
            "0397b68b16eed56f18cb53e22dfc8e453e6faf8ec056f3519c62e531baebc011": {
                "Name": "laughing_fermat",
                "EndpointID": "0de8ef5773ff6d1edc44b91d5ccefdd43836d7a2aee090059b8d7bc59f1216a1",
                "MacAddress": "02:42:ac:11:00:03",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            },
            "07d6759fa9fe372b64097c769121a31c0c8347a0670e3d327d0641e7472e083b": {
                "Name": "festive_kirch",
                "EndpointID": "7ac97bfc80d6fd060b2dc6fb38f031767a97dcec3f573e76186b37903a484b4c",
                "MacAddress": "02:42:ac:11:00:04",
                "IPv4Address": "172.17.0.4/16",
                "IPv6Address": ""
            },
            "b305cc1b397d861bd39cf655b118b24b8d0f0125acccc825450af2be423c5d6b": {
                "Name": "objective_keller",
                "EndpointID": "62f55799f8e1e1113e40057d320d69f381e81dcee054de6f74673530dc406d5b",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]

{% endhighlight %}

原来 bridge 网络配置的 subnet 就是 172.17.0.0/16，并且网关是 172.17.0.1。这个网关在哪儿呢？大概你已经猜出来了，就是 docker0。


{% highlight shell %}
$ ifconfig docker0
docker0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 0.0.0.0
        inet6 fe80::42:f9ff:fe2e:dcf7  prefixlen 64  scopeid 0x20<link>
        ether 02:42:f9:2e:dc:f7  txqueuelen 0  (Ethernet)
        RX packets 3797  bytes 72475492 (69.1 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 7714  bytes 72806297 (69.4 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

{%endhighlight%}

当前容器网络拓扑结构如图所示：

![网络拓扑 @x60]({{ '/net_str.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

容器创建时，docker 会自动从 172.17.0.0/16 中分配一个 IP，这里 16 位的掩码保证有足够多的 IP 可以供容器使用。

除了 none, host, bridge 这三个自动创建的网络，用户也可以根据业务需要创建 user-defined 网络。

## 自定义容器网络

除了 none, host, bridge 这三个自动创建的网络，用户也可以根据业务需要创建 user-defined 网络。
Docker 提供三种 user-defined 网络驱动：bridge, overlay 和 macvlan。overlay 和 macvlan 用于创建跨主机的网络，我们后面有章节单独讨论。

可通过 bridge 驱动创建类似前面默认的 bridge 网络，例如：

![自定义bridge @x100]({{ '/self_defind_bridge.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

{% highlight shell %}
$ docker network create --driver bridge my_net
bb411a0ddf01733af862f574a7a7c4fa0ab9a3b321a36f281f14486b0a70e075
{%endhighlight%}

查看一下当前 host 的网络结构变化：

{% highlight shell %}
$ brctl show
bridge name bridge id   STP enabled interfaces
br-bb411a0ddf01   8000.0242d8f01793 no    
docker0   8000.0242f92edcf7 no    veth4ba89ce
              veth846b10b
              veth9d22376

{% endhighlight %}

新增了一个网桥 br-bb411a0ddf01 ，这里 bb411a0ddf01 正好新建 bridge 网络 my_net 的短 id。执行 `docker network inspect` 查看一下 `my_net` 的配置信息：


{% highlight shell %}
$ docker network inspect my_net
[
    {
        "Name": "my_net",
        "Id": "bb411a0ddf01733af862f574a7a7c4fa0ab9a3b321a36f281f14486b0a70e075",
        "Created": "2017-06-30T12:05:17.870472472-04:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]

{% endhighlight %}


这里 172.18.0.0/16 是 Docker 自动分配的 IP 网段。

我们可以自己指定 IP 网段吗？
答案是：可以。


只需在创建网段时指定 `--subnet` 和 `--gateway` 参数：


{% highlight shell %}
$ docker network create --driver bridge --subnet 172.22.16.0/24 --gateway 172.22.16.1 my_net2
7d07ffb21af0ed4616286afca0a213addff1b69502428313cf8de31bc113c190

$ docker network inspect my_net2
[
    {
        "Name": "my_net2",
        "Id": "7d07ffb21af0ed4616286afca0a213addff1b69502428313cf8de31bc113c190",
        "Created": "2017-06-30T12:10:57.061502441-04:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.22.16.0/24",
                    "Gateway": "172.22.16.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]

$ brctl show
bridge name bridge id   STP enabled interfaces
br-7d07ffb21af0   8000.0242031983bd no    
br-bb411a0ddf01   8000.0242d8f01793 no    
docker0   8000.0242f92edcf7 no    veth4ba89ce
              veth846b10b
              veth9d22376

{%endhighlight%}

这里我们创建了新的 bridge 网络 my_net2，网段为 172.22.16.0/24，网关为 172.22.16.1。与前面一样，网关在 my_net2 对应的网桥 br-7d07ffb21af0 上：


{% highlight shell %}
$ ifconfig br-7d07ffb21af0
br-7d07ffb21af0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.22.16.1  netmask 255.255.255.0  broadcast 0.0.0.0
        ether 02:42:03:19:83:bd  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

{%endhighlight%}

容器要使用新的网络，需要在启动时通过 --network 指定：


{% highlight shell %}
$ docker run -it --network=my_net2 busybox
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
26: eth0@if27: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether 02:42:ac:16:10:02 brd ff:ff:ff:ff:ff:ff
    inet 172.22.16.2/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe16:1002/64 scope link 
       valid_lft forever preferred_lft forever

{%endhighlight%}

容器分配到的 IP 为 172.22.16.2。

到目前为止，容器的 IP 都是 docker 自动从 subnet 中分配，我们能否指定一个静态 IP 呢？

答案是：可以，通过`--ip`指定。


{% highlight shell %}
$ docker run -it --network=my_net2 --ip 172.22.16.88 busybox
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
28: eth0@if29: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether 02:42:ac:16:10:58 brd ff:ff:ff:ff:ff:ff
    inet 172.22.16.88/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe16:1058/64 scope link 
       valid_lft forever preferred_lft forever
/ # 

{%endhighlight%}

>注：只有使用 `--subnet` 创建的网络才能指定静态 IP。

my_net 创建时没有指定 `--subnet`，如果指定静态 IP 报错如下：

{% highlight shell %}
$ docker run -it --network=my_net --ip 172.22.16.88 busybox
docker: Error response from daemon: User specified IP address is supported only when connecting to networks with user configured subnets.
{%endhighlight%}

好了，我们来看看当前 docker host 的网络拓扑结构。

![网络结构 @x60]({{ '/net_str_2.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})


