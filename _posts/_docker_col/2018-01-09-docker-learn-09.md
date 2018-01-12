---
layout: post
title:  "Docker系列 9 容器常用操作"
date:   2017-08-05 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}

## stop/start/restart 容器

+ `docker stop` 停止运行的容器。
    - 容器在 `docker host` 中实际上是一个进程，`docker stop` 命令本质上是向该进程发送一个 `SIGTERM` 信号。如果想快速停止容器，可使用 `docker kill` 命令，其作用是向容器进程发送 `SIGKILL` 信号。
+ `docker start` 重新启动停止状态的容器。
    - `docker start` 会保留容器的第一次启动时的所有参数。
+ `docker restart` 可以重启容器
    - 依次执行 `docker stop` 和`docker start`。
    - 容器可能会因某种错误而停止运行。对于服务类容器，我们通常希望在这种情况下容器能够自动重启。启动容器时设置 `--restart` 就可以达到这个效果。
    - `docker run -d --restart=always httpd`
        + `--restart=always` 意味着无论容器因何种原因退出（包括正常退出），就立即重启。该参数的形式还可以是 `--restart=on-failure:3`，意思是如果启动进程退出代码非0，则重启容器，最多重启3次。

## pause/unpause 容器


有时我们只是希望暂时让容器暂停工作一段时间，比如要对容器的文件系统打个快照，或者 dcoker host 需要使用 CPU，这时可以执行 `docker pause`

处于暂停状态的容器不会占用 CPU 资源，直到通过 docker unpause 恢复运行。

{% highlight shell %}
docker pause name
docker unpause name
{% endhighlight %}

## 删除容器

使用 docker 一段时间后，host 上可能会有大量已经退出了的容器。

{% highlight shell %}
docker ps -a
{% endhighlight %}

这些容器依然会占用 host 的文件系统资源，如果确认不会再重启此类容器，可以通过 docker rm 删除。

{% highlight shell %}
docker rm idnum
{% endhighlight %}

`docker rm` 一次可以指定多个容器，如果希望批量删除所有已经退出的容器，可以执行如下命令：

{% highlight shell %}
docker rm -v $(docker ps -aq -f status=exited)
{% endhighlight %}

>docker rm 是删除容器，而 docker rmi 是删除镜像。

## 一张图搞懂容器所有操作

下图状态机总结了容器各种状态之间是如何转换的

![docker状态转换 @x100]({{ '/docker_status.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})


如果掌握了前面的知识，要看懂这张图应该不难。不过有两点还是需要补充一下：

### 可以先创建容器，稍后再启动。 

![create docker @x100]({{ '/create_docker.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

1. docker create 创建的容器处于 Created 状态。
2. docker start 将以后台方式启动容器。 docker run 命令实际上是 docker create 和 docker start 的组合。

### 只有当容器的启动进程 退出 时，`--restart` 才生效。

退出包括正常退出或者非正常退出。这里举了两个例子：启动进程正常退出或发生 OOM，此时 docker 会根据 `--restart` 的策略判断是否需要重启容器。但如果容器是因为执行 `docker stop` 或`docker kill` 退出，则不会自动重启。








