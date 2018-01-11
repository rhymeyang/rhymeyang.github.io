---
layout: post
title:  "Docker系列 4 镜像"
date:   2017-07-09 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}


镜像是 Docker 容器的基石，容器是镜像的运行实例，有了镜像才能启动容器。

## 镜像的内部结构

如果想创建自己的镜像，或者想理解 Docker 为什么是轻量级的，就非常有必要学习这部分知识了。


### hello-world - 最小的镜像

hello-world 是 Docker 官方提供的一个镜像，通常用来验证 Docker 是否安装成功。

+ `docker pull` 从 Docker Hub 下载
+ `docker images` 命令查看镜像的信息
+ `docker run` 运行

hello-world 的 Dockerfile 内容如下

{% highlight dockerfile %}
FROM scratch
COPY hello /
CMD ["/hello"]
{% endhighlight %}


只有短短三条指令。

+ `FROM scratch`: 此镜像是从白手起家，从 0 开始构建。
+ `COPY hello /`: 将文件“hello”复制到镜像的根目录。
+ `CMD ["/hello"]`: 容器启动时，执行 /hello   

镜像 hello-world 中就只有一个可执行文件 "hello"，其功能就是打印出 “Hello from Docker ......” 等信息。

/hello 就是文件系统的全部内容，连最基本的 /bin，/usr, /lib, /dev 都没有。

hello-world 虽然是一个完整的镜像，但它并没有什么实际用途。通常来说，我们希望镜像能提供一个基本的操作系统环境，用户可以根据需要安装和配置软件。这样的镜像我们称作 base 镜像。

## base 镜像

base 镜像有两层含义：

+ 不依赖其他镜像，从 scratch 构建。
+ 其他镜像可以之为基础进行扩展。

所以，能称作 base 镜像的通常都是各种 Linux 发行版的 Docker 镜像，比如 Ubuntu, Debian, CentOS 等。

我们以 CentOS 为例考察 base 镜像包含哪些内容。
下载镜像：

{% highlight shell %}
docker pull centos
{% endhighlight %}

查看镜像信息：

{% highlight shell %}
docker images centos
{% endhighlight %}
    
一个 CentOS 才 200MB ？

### rootfs

内核空间是 kernel，Linux 刚启动时会加载 bootfs 文件系统，之后 bootfs 会被卸载掉。

用户空间的文件系统是 `rootfs`，包含我们熟悉的 `/dev`, `/proc`, `/bin` 等目录。

对于 base 镜像来说，底层直接用 Host 的 kernel，自己只需要提供 rootfs 就行了。

而对于一个精简的 OS，rootfs 可以很小，只需要包括最基本的命令、工具和程序库就可以了。相比其他 Linux 发行版，CentOS 的 rootfs 已经算臃肿的了，alpine 还不到 10MB。

我们平时安装的 CentOS 除了 rootfs 还会选装很多软件、服务、图形桌面等，需要好几个 GB 就不足为奇了。


### base 镜像提供的是最小安装的 Linux 发行版。

下面是 CentOS 镜像的 Dockerfile 的内容：

{% highlight dockerfile %}
FROM scratch
ADD centos-7-docker.tar.xz /
CMD ["/bin/bash"]
{% endhighlight %}      

第二行 ADD 指令添加到镜像的 tar 包就是 CentOS 7 的 rootfs。在制作镜像时，这个 tar 包会自动解压到 / 目录下，生成 /dev, /porc, /bin 等目录。

>可在 Docker Hub 的镜像描述页面中查看 Dockerfile 。

### 支持运行多种 Linux OS

不同 Linux 发行版的区别主要就是 rootfs。

比如 Ubuntu 14.04 使用 `upstart` 管理服务，`apt` 管理软件包；而 CentOS 7 使用 `systemd` 和 `yum`。这些都是用户空间上的区别，Linux kernel 差别不大。

所以 Docker 可以同时支持多种 Linux 镜像，模拟出多种操作系统环境。

>base 镜像只是在用户空间与发行版一致，kernel 版本与发型版是不同的。
例如 CentOS 7 使用 3.x.x 的 kernel，如果 Docker Host 是 Ubuntu 16.04（比如我们的实验环境），那么在 CentOS 容器中使用的实际是是 Host 4.x.x 的 kernel。 

内核版本信息

{% highlight shell %}
uname -r
{% endhighlight %}   
    

容器只能使用 Host 的 kernel，并且不能修改。
所有容器都共用 host 的 kernel，在容器中没办法对 kernel 升级。如果容器对 kernel 版本有要求（比如应用只能在某个 kernel 版本下运行），则不建议用容器，这种场景虚拟机可能更合适。   

## 镜像的分层结构 

Docker 支持通过扩展现有镜像，创建新的镜像。

实际上，Docker Hub 中 99% 的镜像都是通过在 base 镜像中安装和配置需要的软件构建出来的。比如我们现在构建一个新的镜像，Dockerfile 如下：

{% highlight dockerfile %}
FROM debian
RUN apt-get install emacs
RUN apt-get install apache2
CMD ["/bin/bash"]
{% endhighlight %}  

1. 新镜像不再是从 scratch 开始，而是直接在 Debian base 镜像上构建。
2. 安装 emacs 编辑器。
3. 安装 apache2。
4. 容器启动时运行 bash。

新镜像是从 base 镜像一层一层叠加生成的。每安装一个软件，就在现有镜像的基础上增加一层。

为什么 Docker 镜像要采用这种分层结构呢？

最大的一个好处就是 - __共享资源__。

比如：有多个镜像都从相同的 base 镜像构建而来，那么 Docker Host 只需在磁盘上保存一份 base 镜像；同时内存中也只需加载一份 base 镜像，就可以为所有容器服务了。而且镜像的每一层都可以被共享，我们将在后面更深入地讨论这个特性。

这时可能就有人会问了：如果多个容器共享一份基础镜像，当某个容器修改了基础镜像的内容，比如 /etc 下的文件，这时其他容器的 /etc 是否也会被修改？

答案是不会！
修改会被限制在单个容器内。
这就是我们接下来要学习的容器 `Copy-on-Write` 特性。

### 可写的容器层

当容器启动时，一个新的可写层被加载到镜像的顶部。
这一层通常被称作“容器层”，“容器层”之下的都叫“镜像层”。

所有对容器的改动 - 无论添加、删除、还是修改文件都只会发生在容器层中。

__只有容器层是可写的，容器层下面的所有镜像层都是只读的。__


下面我们深入讨论容器层的细节。

镜像层数量可能会很多，所有镜像层会联合在一起组成一个统一的文件系统。如果不同层中有一个相同路径的文件，比如 /a，上层的 /a 会覆盖下层的 /a，也就是说用户只能访问到上层中的文件 /a。在容器层中，用户看到的是一个叠加之后的文件系统。

1. 添加文件<br/>容器中创建文件时，新文件被添加到容器层中。
2. 读取文件 <br/>在容器中读取某个文件时，Docker 会从上往下依次在各镜像层中查找此文件。一旦找到，立即将其复制到容器层，然后打开并读入内存。
3. 修改文件 <br/>在容器中修改已存在的文件时，Docker 会从上往下依次在各镜像层中查找此文件。一旦找到，立即将其复制到容器层，然后修改之。
4. 删除文件 <br/>在容器中删除文件时，Docker 也是从上往下依次在镜像层中查找此文件。找到后，会在容器层中记录下此删除操作。

只有当需要修改时才复制一份数据，这种特性被称作 Copy-on-Write。可见，容器层保存的是镜像变化的部分，不会对镜像本身进行任何修改。

这样就解释了我们前面提出的问题：容器层记录对镜像的修改，所有镜像层都是只读的，不会被容器修改，所以镜像可以被多个容器共享。


## 构建镜像

对于 Docker 用户来说，最好的情况是不需要自己创建镜像。几乎所有常用的数据库、中间件、应用软件等都有现成的 Docker 官方镜像或其他人和组织创建的镜像，我们只需要稍作配置就可以直接使用。

使用现成镜像的好处除了省去自己做镜像的工作量外，更重要的是可以利用前人的经验。特别是使用那些官方镜像，因为 Docker 的工程师知道如何更好的在容器中运行软件。

当然，某些情况下我们也不得不自己构建镜像，比如：

+ 找不到现成的镜像，比如自己开发的应用程序。
+ 需要在镜像中加入特定的功能，比如官方镜像几乎都不提供 ssh。

所以本节我们将介绍构建镜像的方法。同时分析构建的过程也能够加深我们对前面镜像分层结构的理解。

Docker 提供了两种构建镜像的方法：

+ `docker commit` 命令
+ `Dockerfile` 构建文件

### docker commit

`docker commit` 命令是创建新镜像最直观的方法，其过程包含三个步骤：

1. 运行容器
2. 修改容器
3. 将容器保存为新的镜像

举个例子：在 ubuntu base 镜像中安装 vi 并保存为新镜像。

1. 运行容器 <br/> `docker run -it ubuntu`, it 交互模式
2. `apt-get install -y vim`
3. `docker ps` `docker commit randomname name`

Docker 并不建议用户通过docker commit 方式构建镜像。原因如下：

1. 这是一种手工创建镜像的方式，容易出错，效率低且可重复性弱。比如要在 debian base 镜像中也加入 vi，还得重复前面的所有步骤。
2. 更重要的：使用者并不知道镜像是如何创建出来的，里面是否有恶意程序。也就是说无法对镜像进行审计，存在安全隐患。


既然 docker commit 不是推荐的方法，我们干嘛还要花时间学习呢？

原因是：即便是用 Dockerfile（推荐方法）构建镜像，底层也 docker commit 一层一层构建新镜像的。学习 docker commit 能够帮助我们更加深入地理解构建过程和镜像的分层结构。

## Dockerfile 构建镜像

Dockerfile 是一个文本文件，记录了镜像构建的所有步骤。

第一个 Dockerfile

用 Dockerfile 创建上节的 ubuntu-with-vi，其内容则为：

{% highlight dockerfile %}
FROM ubuntu
RUN apt-get update && apt-get install -y vim
{% endhighlight %}  

下面我们运行 docker build 命令构建镜像并详细分析每个细节。

{% highlight shell build %}
pwd                     # ---> 1
/root

ls                      # ---> 2
Dockerfile

docker build -t ubuntu-with-vi-dockerfile .          # ---> 3
Sending build context to Docker daemon 32.26 kB    # ---> 4
Step 1 : FROM ubuntu                                   # ---> 5
---> f753707788c5  
Step 2 : RUN apt-get update && apt-get install -y vim # ---> 6
---> Running in 9f4d4166f7e3                # ---> 7
{% endhighlight %}  

1. 当前目录为 /root。
2. Dockerfile 准备就绪。
3. 运行 docker build 命令，`-t` 将新镜像命名为 ubuntu-with-vi-dockerfile，命令末尾的 . 指明 build context 为当前目录。Docker 默认会从 build context 中查找 Dockerfile 文件，我们也可以通过 `-f` 参数指定 Dockerfile 的位置。
4. 从这步开始就是镜像真正的构建过程。 首先 Docker 将 build context 中的所有文件发送给 Docker daemon。build context 为镜像构建提供所需要的文件或目录。<br/>
Dockerfile 中的 ADD、COPY 等命令可以将 build context 中的文件添加到镜像。此例中，build context 为当前目录 /root，该目录下的所有文件和子目录都会被发送给 Docker daemon。<br/>
所以，使用 build context 就得小心了，不要将多余文件放到 build context，特别不要把 /、/usr 作为 build context，否则构建过程会相当缓慢甚至失败。
5. Step 1：执行 FROM，将 ubuntu 作为 base 镜像。
ubuntu 镜像 ID 为 f753707788c5。
6. Step 2：执行 RUN，安装 vim

在上面的构建过程中，我们要特别注意指令 RUN 的执行过程 ⑦、⑧、⑨。Docker 会在启动的临时容器中执行操作，并通过 commit 保存为新的镜像。

### 查看镜像分层结构

ubuntu-with-vi-dockerfile 是通过在 base 镜像的顶部添加一个新的镜像层而得到的。

这个新镜像层的内容由 `RUN apt-get update && apt-get install -y vim` 生成。这一点我们可以通过 `docker history` 命令验证。

## 镜像的缓存特性

Docker 会缓存已有镜像的镜像层，构建新镜像时，如果某镜像层已经存在，就直接使用，无需重新创建。

举例说明。
在前面的 Dockerfile 中添加一点新内容，往镜像中复制一个文件：

{% highlight dockerfile %}
FROM ubuntu
RUN apt-get update && apt-get install -y vim
COPY testfile /
{% endhighlight %}  

 重点在这里：之前已经运行过相同的 RUN 指令，这次直接使用缓存中的镜像层 35ca89798937。

执行 COPY 指令。
其过程是启动临时容器，复制 testfile，提交新的镜像层 8d02784a78f4，删除临时容器。

在 ubuntu-with-vi-dockerfile 镜像上直接添加一层就得到了新的镜像 ubuntu-with-vi-dockerfile-2。

如果我们希望在构建镜像时不使用缓存，可以在 `docker build` 命令中加上 `--no-cache` 参数。

Dockerfile 中每一个指令都会创建一个镜像层，上层是依赖于下层的。无论什么时候，只要某一层发生变化，其上面所有层的缓存都会失效。

也就是说，如果我们改变 Dockerfile 指令的执行顺序，或者修改或添加指令，都会使缓存失效。

举例说明，比如交换前面 RUN 和 COPY 的顺序：

{% highlight dockerfile %}
FROM ubuntu
COPY testfile /
RUN apt-get update && apt-get install -y vim
{% endhighlight %}

虽然在逻辑上这种改动对镜像的内容没有影响，但由于分层的结构特性，Docker 必须重建受影响的镜像层。

从上面的输出可以看到生成了新的镜像层 bc87c9710f40，缓存已经失效。
除了构建时使用缓存，Docker 在下载镜像时也会使用。例如我们下载 httpd 镜像。

由 Dockerfile 可知 httpd 的 base 镜像为 debian，正好之前已经下载过 debian 镜像，所以有缓存可用。通过 docker history 可以进一步验证。

## 调试 Dockerfile

包括 Dockerfile 在内的任何脚本和程序都会出错。有错并不可怕，但必须有办法排查，所以本节讨论如何 debug Dockerfile。
先回顾一下通过 Dockerfile 构建镜像的过程：

1. 从 base 镜像运行一个容器。
2. 执行一条指令，对容器做修改。
3. 执行类似 docker commit 的操作，生成一个新的镜像层。
4. Docker 再基于刚刚提交的镜像运行一个新容器。
5. 重复 2-4 步，直到 Dockerfile 中的所有指令执行完毕。


从这个过程可以看出，如果 Dockerfile 由于某种原因执行到某个指令失败了，我们也将能够得到前一个指令成功执行构建出的镜像，这对调试 Dockerfile 非常有帮助。我们可以__运行最新的这个镜像定位指令失败的原因__。

{% highlight dockerfile %}
FROM busybox
RUN touch tmpfile
RUN /bin/bash -c echo "continue to build"
COPY testfile /
{% endhighlight %}


执行 docker build：

![Docker 架构 @x100]({{ '/debug_dockerfile_1.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})


Dockerfile 在执行第三步 RUN 指令时失败。我们可以利用第二步创建的镜像 22d31cc52b3e 进行调试，方式是通过 `docker run -it` 启动镜像的一个容器。

{% highlight shell %}
docker run -it 22d31cc52b3e
{% endhighlight %}

手工执行 RUN 指令很容易定位失败的原因是 busybox 镜像中没有 bash。虽然这是个极其简单的例子，但它很好地展示了调试 Dockerfile 的方法。   

