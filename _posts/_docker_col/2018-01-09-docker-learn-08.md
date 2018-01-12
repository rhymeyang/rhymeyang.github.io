---
layout: post
title:  "Docker系列 8 如何运行容器？"
date:   2017-08-05 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}


## 运行容器

`docker run` 是启动容器的方法。在讨论 Dockerfile 时我们已经学习到，可用三种方式指定容器启动时执行的命令：

+ `CMD` 指令。
+ `ENDPOINT` 指令。
+ 在 `docker run` 命令行中指定。

例如下面的例子：


{% highlight shell %}
[root@dockerserver ~]# docker run centos pwd
/
[root@dockerserver ~]# 
{% endhighlight %}

容器启动时执行 `pwd`，返回的 `/` 是容器中的当前目录。 执行 `docker ps` 或 `docker container ls` 可以查看 `Docker host` 中当前运行的容器：

{% highlight shell %}
[root@dockerserver ~]# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
[root@dockerserver ~]# docker container ls
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

[root@dockerserver ~]# docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
e0be46060424        centos              "pwd"               3 minutes ago       Exited (0) 3 minutes ago 

[root@dockerserver ~]# docker container ls -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
e0be46060424        centos              "pwd"               3 minutes ago       Exited (0) 3 minutes ago                     
[root@dockerserver ~]# 
{% endhighlight %}

`-a` 会显示所有状态的容器，可以看到，之前的容器已经退出了，状态为Exited。

## 让容器长期运行

容器的生命周期依赖于启动时执行的命令，只要该命令不结束，容器也就不会退出。

理解了这个原理，我们就可以通过执行一个长期运行的命令来保持容器的运行状态。例如执行下面的命令：


{% highlight shell %}
$ docker run centos /bin/bash -c "while true; do sleep 1; done"

$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
eecca9576653        centos              "/bin/bash -c 'whi..."   44 seconds ago      Up 44 seconds  
{% endhighlight %}

`while` 语句让 bash 不会退出。不过这种方法有个缺点：它占用了一个终端。

可以加上参数 -d 以后台方式启动容器。

{% highlight shell %}
$ docker run -d centos /bin/bash -c "while true; do sleep 1; done"
71cc983f0be3be4188edc861269ae05057ae070a8e0c210db71a48541bad8d54
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
71cc983f0be3        centos              "/bin/bash -c 'whi..."   6 seconds ago       Up 5 seconds                            romantic_wiles
{% endhighlight %}

CONTAINER ID 是容器的 “短ID”，前面启动容器时返回的是 “长ID”。短ID是长ID的前12个字符。

`NAMES` 字段显示容器的名字，在启动容器时可以通过 `--name` 参数显示地为容器命名，如果不指定，docker 会自动为容器分配名字。

对于容器的后续操作，我们需要通过 “长ID”、“短ID” 或者 “名称” 来指定要操作的容器。
比如停止一个容器：

{% highlight shell %}
docker stop 71cc983f0be3
{% endhighlight %}

容器常见的用途是运行后台服务，例如前面我们已经看到的 http server  

{% highlight shell %}
docker run --name myhttp -d httpd
docker history httpd
{% endhighlight %}

这一次我们用 `--name` 指定了容器的名字。 我们还看到容器运行的命令是httpd-foreground，通过 docker history 可知这个命令是通过 CMD 指定的。

{% highlight shell %}
docker run --name myhttp -d httpd
Unable to find image 'httpd:latest' locally
latest: Pulling from library/httpd
9f0706ba7422: Downloading [==============>                                    ] 15.68 MB/52.61 MB
9f0706ba7422: Pull complete 
47bacf36113f: Pull complete 
56798d8e5a30: Pull complete 
94b25413538a: Pull complete 
97d879f4e260: Pull complete 
2a4f7e960a3e: Pull complete 
12f5eb531290: Pull complete 
Digest: sha256:8f58a3ef340038615498cead8b83fa3b31e4fe5c16961c6c3635e973ac9303ed
Status: Downloaded newer image for httpd:latest
a088fcb283345b36f17a679a326d1507d300e07f5a3c00123613afc055c12e0c


docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
a088fcb28334        httpd               "httpd-foreground"       8 minutes ago       Up 8 minutes        80/tcp              myhttp
71cc983f0be3        centos              "/bin/bash -c 'whi..."   40 minutes ago      Up 40 minutes                           romantic_wiles


docker history httpd
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
b1e597b50dd7        7 days ago          /bin/sh -c #(nop)  CMD ["httpd-foreground"]     0 B
<missing>           7 days ago          /bin/sh -c #(nop)  EXPOSE 80/tcp                0 B
<missing>           7 days ago          /bin/sh -c #(nop) COPY file:761e313354b918...   133 B
<missing>           7 days ago          /bin/sh -c set -x  && buildDeps="   bzip2 ...   9.68 MB
<missing>           7 days ago          /bin/sh -c #(nop)  ENV HTTPD_ASC_URL=https...   0 B 
<missing>           7 days ago          /bin/sh -c #(nop)  ENV HTTPD_BZ2_URL=https...   0 B
<missing>           7 days ago          /bin/sh -c #(nop)  ENV HTTPD_SHA1=bd6d138c...   0 B
<missing>           7 days ago          /bin/sh -c #(nop)  ENV HTTPD_VERSION=2.4.25     0 B
<missing>           7 days ago          /bin/sh -c apt-get update  && apt-get inst...   44.2 MB
<missing>           7 days ago          /bin/sh -c {   echo 'deb http://deb.debian...   161 B
<missing>           7 days ago          /bin/sh -c #(nop)  ENV OPENSSL_VERSION=1.0...   0 B
<missing>           7 days ago          /bin/sh -c #(nop)  ENV NGHTTP2_VERSION=1.1...   0 B
<missing>           7 days ago          /bin/sh -c #(nop) WORKDIR /usr/local/apache2    0 B
<missing>           7 days ago          /bin/sh -c mkdir -p "$HTTPD_PREFIX"  && ch...   0 B
<missing>           7 days ago          /bin/sh -c #(nop)  ENV PATH=/usr/local/apa...   0 B
<missing>           7 days ago          /bin/sh -c #(nop)  ENV HTTPD_PREFIX=/usr/l...   0 B
<missing>           9 days ago          /bin/sh -c echo 'deb http://deb.debian.org...   55 B
<missing>           9 days ago          /bin/sh -c #(nop)  CMD ["bash"]                 0 B
<missing>           9 days ago          /bin/sh -c #(nop) ADD file:9c48682ff75c756...   123 MB     
{% endhighlight %}

## 两种进入容器的方法

我们经常需要进到容器里去做一些工作，比如查看日志、调试、启动其他进程等。有两种方法进入容器：`attach` 和 `exec`。

### docker attach

通过 docker attach 可以 attach 到容器启动命令的终端，例如：

{% highlight shell %}
docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
e787420eca98        centos              "/bin/bash -c 'whi..."   9 seconds ago       Up 8 seconds                            elegant_hawking
[root@dockerclient docker]# docker attach e7874
{% endhighlight %}


>注：可通过 Ctrl+p 然后 Ctrl+q 组合键退出 attach 终端。

### docker exec

通过 `docker exec` 进入相同的容器：

{% highlight shell %}
docker exec -it e7874 bash
{% endhighlight %}

说明如下：

1. `-it` 以交互模式打开 pseudo-TTY，执行 bash，其结果就是打开了一个 bash 终端。
2. 进入到容器中，容器的 hostname 就是其 “短ID”。
3. 可以像在普通 Linux 中一样执行命令。`ps -elf` 显示了容器启动进程while 以及当前的 bash 进程。
4. 执行 exit 退出容器，回到 docker host。

{% highlight shell %}
docker exec -it <container> bash|sh 是执行 exec 最常用的方式。
{% endhighlight %}

### attach VS exec

attach 与 exec 主要区别如下:

+ `attach` 直接进入容器 __启动命令__ 的终端，不会启动新的进程。
+ `exec` 则是在容器中打开新的终端，并且可以启动新的进程。
+ 如果想直接在终端中查看启动命令的输出，用 `attach`；其他情况使用 `exec`。

查看启动命令输出，使用 `docker logs`

{% highlight shell %}
docker logs -f 1328d892ae5c
{% endhighlight %}

`-f` 的作用与 `tail -f` 类似，能够持续打印输出。    


## 运行容器的最佳实践

按用途容器大致可分为两类：服务类容器和工具类的容器。

1. 服务类容器以 daemon 的形式运行，对外提供服务。比如 web server，数据库等。通过 `-d` 以后台方式启动这类容器是非常合适的。如果要排查问题，可以通过 `exec -it` 进入容器。
2. 工具类容器通常给能我们提供一个临时的工作环境，通常以 `run -it` 方式运行，比如：

{% highlight shell %}
docker run -it busybox
{% endhighlight %}

工具类容器多使用基础镜像，例如 busybox、debian、ubuntu 等。


### 容器运行小结
容器运行相关的知识点：

1. 当 CMD 或 Entrypoint 或 docker run 命令行指定的命令运行结束时，容器停止。
2. 通过 `-d` 参数在后台启动容器。
3. 通过 `exec -it` 可进入容器并执行命令。


指定容器的三种方法：  

1. 短ID。
2. 长ID。
3. 容器名称。 可通过 `--name` 为容器命名。重命名容器可执行docker rename。

容器按用途可分为两类：

1. 服务类的容器。
2. 工具类的容器。