---
layout: post
title:  "Docker系列 11 实现容器的底层技术"
date:   2017-08-06 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}


`cgroup` 和 `namespace` 是最重要的两种技术。cgroup 实现资源限额， namespace 实现资源隔离。

## cgroup

`cgroup` 全称 `Control Group`。Linux 操作系统通过 cgroup 可以设置进程使用 CPU、内存 和 IO 资源的限额。相信你已经猜到了：前面我们看到的`--cpu-shares`、`-m`、`--device-write-bps` 实际上就是在配置 cgroup。

cgroup 到底长什么样子呢？我们可以在 `/sys/fs/cgroup` 中找到它。还是用例子来说明，启动一个容器，设置 `--cpu-shares=512`：

{% highlight shell %}
$ docker run -it --cpu-shares 512 progrium/stress -c 1
stress: info: [1] dispatching hogs: 1 cpu, 0 io, 0 vm, 0 hdd
stress: dbug: [1] using backoff sleep of 3000us
stress: dbug: [1] --> hogcpu worker 1 [5] forked
{% endhighlight %}

<br/>

查看容器ID

{% highlight shell %}
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
b305cc1b397d        progrium/stress     "/usr/bin/stress -..."   53 seconds ago      Up 52 seconds                           objective_keller
{% endhighlight %}

在 `/sys/fs/cgroup/cpu/docker` 目录中，Linux 会为每个容器创建一个 cgroup 目录，以容器长ID 命名：

{% highlight shell %}
$ pwd
/sys/fs/cgroup/cpu/docker/b305cc1b397d861bd39cf655b118b24b8d0f0125acccc825450af2be423c5d6b

$ cat cpu.shares 
512
{% endhighlight %}

目录中包含所有与 cpu 相关的 cgroup 配置，文件 cpu.shares 保存的就是 `--cpu-shares` 的配置，值为 512。

同样的，/sys/fs/cgroup/memory/docker 和 /sys/fs/cgroup/blkio/docker 中保存的是内存以及 Block IO 的 cgroup 配置。

## namespace
在每个容器中，我们都可以看到文件系统，网卡等资源，这些资源看上去是容器自己的。拿网卡来说，每个容器都会认为自己有一块独立的网卡，即使 host 上只有一块物理网卡。这种方式非常好，它使得容器更像一个独立的计算机。

Linux 实现这种方式的技术是 namespace。namespace 管理着 host 中全局唯一的资源，并可以让每个容器都觉得只有自己在使用它。换句话说，namespace 实现了容器间资源的隔离。


Linux 使用了六种 namespace，分别对应六种资源：`Mount`、`UTS`、`IPC`、`PID`、`Network` 和 `User`，下面我们分别讨论。

### Mount namespace

Mount namespace 让容器看上去拥有整个文件系统。

容器有自己的 `/` 目录，可以执行 mount 和 umount 命令。当然我们知道这些操作只在当前容器中生效，不会影响到 host 和其他容器。

### UTS namespace

简单的说，UTS namespace 让容器有自己的 hostname。 默认情况下，容器的 hostname 是它的短ID，可以通过 `-h` 或 `--hostname` 参数设置。

{% highlight shell %}
$ docker run -h myhost -it centos
$ hostname
myhost
{% endhighlight %}

### IPC namespace
IPC namespace 让容器拥有自己的共享内存和信号量（semaphore）来实现进程间通信，而不会与 host 和其他容器的 IPC 混在一起。

### PID namespace
我们前面提到过，容器在 host 中以进程的形式运行。例如当前 host 中运行了两个容器：

通过 `ps axf` 可以查看容器进程：

{% highlight shell %}
$ ps axf
   PID TTY      STAT   TIME COMMAND
   ...
  3112 ?        Ssl    1:04 /usr/bin/dockerd -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock
  3115 ?        Ssl    0:13  \_ docker-containerd -l unix:///var/run/docker/libcontainerd/docker-containerd.sock --metrics-interval=0 --start-ti
  8475 ?        Sl     0:00      \_ docker-containerd-shim b305cc1b397d861bd39cf655b118b24b8d0f0125acccc825450af2be423c5d6b /var/run/docker/libc
  8489 pts/2    Ss+    0:00          \_ /usr/bin/stress --verbose -c 1
  8502 pts/2    R+    16:46              \_ /usr/bin/stress --verbose -c 1
{% endhighlight %}


所有容器的进程都挂在 dockerd 进程下，同时也可以看到容器自己的子进程。 如果我们进入到某个容器，ps 就只能看到自己的进程了：

{% highlight shell %}
$ docker exec -it b305cc1b397d bash
$ ps axf
   PID TTY      STAT   TIME COMMAND
     6 ?        Ss     0:00 bash
    12 ?        R+     0:00  \_ ps axf
     1 ?        Ss+    0:00 /usr/bin/stress --verbose -c 1
     5 ?        R+    22:28 /usr/bin/stress --verbose -c 1
{% endhighlight %}  


而且进程的 PID 不同于 host 中对应进程的 PID，容器中 PID=1 的进程当然也不是 host 的 init 进程。也就是说：容器拥有自己独立的一套 PID，这就是 PID namespace 提供的功能。

### Network namespace
Network namespace 让容器拥有自己独立的网卡、IP、路由等资源。

### User namespace

User namespace 让容器能够管理自己的用户，host 不能看到容器中创建的用户。

在容器中创建了用户 cloud，但 host 中并不会创建相应的用户。

## 小结

本章首先通过大量实验学习了容器的各种操作以及容器状态之间如何转换，然后讨论了限制容器使用 CPU、内存和 Block IO 的方法，最后学习了实现容器的底层技术：cgroup 和 namespace。

下面是容器的常用操作命令：

+ `create`      创建容器  
+ `run`         运行容器  
+ `pause`       暂停容器  
+ `unpause`     取消暂停继续运行容器  
+ `stop`        发送 SIGTERM 停止容器  
+ `kill`        发送 SIGKILL 快速停止容器  
+ `start`       启动容器  
+ `restart`     重启容器  
+ `attach`      attach 到容器启动进程的终端  
+ `exec`        在容器中启动新进程，通常使用 "-it" 参数  
+ `logs`        显示容器启动进程的控制台输出，用 "-f" 持续打印  
+ `rm`          从磁盘中删除容器




