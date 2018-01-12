---
layout: post
title:  "Docker系列 10 限制容器对内存的使用"
date:   2017-08-06 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}


限制容器对内存的使用

一个 docker host 上会运行若干容器，每个容器都需要 CPU、内存和 IO 资源。对于 KVM，VMware 等虚拟化技术，用户可以控制分配多少 CPU、内存资源给每个虚拟机。对于容器，Docker 也提供了类似的机制避免某个容器因占用太多资源而影响其他容器乃至整个 host 的性能。

## 内存限额

与操作系统类似，容器可使用的内存包括两部分：物理内存和 swap。 Docker 通过下面两组参数来控制容器内存的使用量。

1. `-m` 或 `--memory`：设置内存的使用限额，例如 100M, 2G。
2. `--memory-swap`：设置 内存+swap 的使用限额。

{% highlight shell %}
docker run -m 200M --memory-swap=300M centos
{% endhighlight %}

其含义是允许该容器最多使用 200M 的内存和 100M 的 swap。默认情况下，上面两组参数为 `-1`，即对容器内存和 swap 的使用没有限制。

下面我们将使用 progrium/stress 镜像来学习如何为容器分配内存。该镜像可用于对容器执行压力测试。执行如下命令：

{% highlight shell %}
docker run -it -m 200M --memory-swap=300M progrium/stress --vm 1 --vm-bytes 280M
{% endhighlight %}


+ `--vm 1`：启动 1 个内存工作线程。
+ `--vm-bytes 280M`：每个线程分配 280M 内存。

[压力测试工具](https://hub.docker.com/r/progrium/stress/)

因为 280M 在可分配的范围（300M）内，所以工作线程能够正常工作，其过程是：

+ 分配 280M 内存。
+ 释放 280M 内存。
+ 再分配 280M 内存。
+ 再释放 280M 内存。
+ 一直循环......    

如果让工作线程分配的内存超过 300M，结果如下：

![stress fail @x100]({{ '/stress_fail.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

分配的内存超过限额，stress 线程报错，容器退出。

如果在启动容器时只指定 -m 而不指定 --memory-swap，那么 --memory-swap 默认为 -m 的两倍，比如：

{% highlight shell %}
docker run -it -m 200M ubuntu
{% endhighlight %}

容器最多使用 200M 物理内存和 200M swap。


## 限制容器对CPU的使用

上节学习了如何限制容器对内存的使用，本节我们来看CPU。

默认设置下，所有容器可以平等地使用 host CPU 资源并且没有限制。

Docker 可以通过 `-c` 或 `--cpu-shares` 设置容器使用 CPU 的权重。如果不指定，默认值为 1024。

与内存限额不同，通过 `-c` 设置的 `cpu share` 并不是 CPU 资源的绝对数量，而是一个相对的权重值。某个容器最终能分配到的 CPU 资源取决于它的 cpu share 占所有容器 cpu share 总和的比例。


换句话说：__通过 cpu share 可以设置容器使用 CPU 的优先级。__

比如在 host 中启动了两个容器：

{% highlight shell %}
docker run --name "container_A" -c 1024 ubuntu

docker run --name "container_B" -c 512 ubuntu
{% endhighlight %}

container_A 的 cpu share 1024，是 container_B 的两倍。当两个容器都需要 CPU 资源时，container_A 可以得到的 CPU 是 container_B 的两倍。

需要特别注意的是，这种按权重分配 CPU 只会发生在 CPU 资源紧张的情况下。如果 container_A 处于空闲状态，这时，为了充分利用 CPU 资源，container_B 也可以分配到全部可用的 CPU。

下面我们继续用 progrium/stress 做实验。

### 1. 启动 container_A，cpu share 为 1024：

{% highlight shell %}
docker run --name container_A -it -c 1024 progrium/stress --cpu 1
{% endhighlight %}
    

`--cpu` 用来设置工作线程的数量。因为当前 host 只有 1 颗 CPU，所以一个工作线程就能将 CPU 压满。如果 host 有多颗 CPU，则需要相应增加 `--cpu` 的数量。    


### 2. 启动 container_B，cpu share 为 512： 

{% highlight shell %}
docker run --name container_B -it -c 512 progrium/stress --cpu 1
{% endhighlight %}
    

### 3. 在 host 中执行 top，查看容器对 CPU 的使用情况： 

container_A 消耗的 CPU 是 container_B 的两倍。


### 4. 现在暂停 container_A： 

`top` 显示 container_B 在 container_A 空闲的情况下能够用满整颗 CPU： 


## 限制容器的 Block IO

Block IO 是另一种可以限制容器使用的资源。Block IO 指的是磁盘的读写，docker 可通过设置权重、限制 bps 和 iops 的方式控制容器读写磁盘的带宽，下面分别讨论。

>注：目前 Block IO 限额只对 direct IO（不使用文件缓存）有效。

### block IO 权重
默认情况下，所有容器能平等地读写磁盘，可以通过设置 `--blkio-weight` 参数来改变容器 block IO 的优先级。

`--blkio-weight` 与 `--cpu-shares` 类似，设置的是相对权重值，默认为 500。在下面的例子中，container_A 读写磁盘的带宽是 container_B 的两倍。

{% highlight shell %}
docker run -it --name container_A --blkio-weight 600 ubuntu   

docker run -it --name container_B --blkio-weight 300 ubuntu
{% endhighlight %}


### 限制 bps 和 iops
`bps` 是 byte per second，每秒读写的数据量。
`iops` 是 io per second，每秒 IO 的次数。

可通过以下参数控制容器的 bps 和 iops：
+ `--device-read-bps`，限制读某个设备的 bps。
+ `--device-write-bps`，限制写某个设备的 bps。
+ `--device-read-iops`，限制读某个设备的 iops。
+ `--device-write-iops`，限制写某个设备的 iops。


下面这个例子限制容器写 /dev/sda 的速率为 30 MB/s

{% highlight shell %}
docker run -it --device-write-bps /dev/sda:30MB ubuntu
{% endhighlight %}

![block rate @x100]({{ '/io_test.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

通过 dd 测试在容器中写磁盘的速度。因为容器的文件系统是在 host /dev/sda 上的，在容器中写文件相当于对 host /dev/sda 进行写操作。另外，`oflag=direct` 指定用 direct IO 方式写文件，这样 `--device-write-bps` 才能生效。


结果表明，bps 25.6 MB/s 没有超过 30 MB/s 的限速。

作为对比测试，如果不限速，结果如下：

![block rate @x100]({{ '/io_test_unlimit.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

