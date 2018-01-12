---
layout: post
title:  "Docker系列 5 Dockerfile 常用指令"
date:   2017-07-30 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}


## FROM

指定 base 镜像。

## MAINTAINER
设置镜像的作者，可以是任意字符串。

## COPY
将文件从 build context 复制到镜像。

COPY 支持两种形式：

1. COPY src dest
2. COPY ["src", "dest"]

>注意：src 只能指定 build context 中的文件或目录。

## ADD
与 COPY 类似，从 build context 复制文件到镜像。不同的是，如果 src 是归档文件（tar, zip, tgz, xz 等），文件会被自动解压到 dest。

## ENV
设置环境变量，环境变量可被后面的指令使用。例如：

{% highlight dockerfile %}
ENV MY_VERSION 1.3
RUN apt-get install -y mypackage=$MY_VERSION
{% endhighlight %}


## EXPOSE

指定容器中的进程会监听某个端口，Docker 可以将该端口暴露出来。我们会在容器网络部分详细讨论。


## VOLUME

将文件或目录声明为 volume。我们会在容器存储部分详细讨论。

## WORKDIR
为后面的 RUN, CMD, ENTRYPOINT, ADD 或 COPY 指令设置镜像中的当前工作目录。   

## RUN
在容器中运行指定的命令。

## CMD
容器启动时运行指定的命令。
Dockerfile 中可以有多个 CMD 指令，但只有最后一个生效。CMD 可以被 docker run 之后的参数替换。

## ENTRYPOINT
设置容器启动时运行的命令。
Dockerfile 中可以有多个 ENTRYPOINT 指令，但只有最后一个生效。CMD 或 docker run 之后的参数会被当做参数传递给 ENTRYPOINT。

## 实例

{% highlight dockerfile %}
# dockerfile example
FROM busybox
MAINTAINER yy@163.com
WORKDIR /testdir
RUN touch tmpfile1
COPY ["tmpfile2", "."]
ADD ["bunch.tar.gz", "."]
ENV WELCOME "You are in my container. Welcome"
{% endhighlight %}

>Dockerfile 支持以“#”开头的注释。

构建镜像：

{% highlight shell %}
ls
Dockerfile bunch.tar.gz tmpfile2

docker build -t my-image   .
{% endhighlight %}

运行容器，验证镜像内容：

{% highlight shell %}
docker run -it my-image   

ls   # in container
bunch tmpfile1 tmpfile2
{% endhighlight %}


1. 进入容器，当前目录即为 WORKDIR。如果 WORKDIR 不存在，Docker 会自动为我们创建。
2. WORKDIR 中保存了我们希望的文件和目录：
目录 bunch：由 `ADD` 指令从 build context 复制的归档文件 bunch.tar.gz，已经自动解压。
文件 tmpfile1：由 RUN 指令创建。
文件 tmpfile2：由 COPY 指令从 build context 复制。
3. ENV 指令定义的环境变量已经生效。


## RUN vs CMD vs ENTRYPOINT

`RUN`、`CMD` 和 `ENTRYPOINT` 这三个 Dockerfile 指令看上去很类似，很容易混淆。本节将通过实践详细讨论它们的区别。
简单的说：

1. `RUN` 执行命令并创建新的镜像层，RUN 经常用于安装软件包。
2. `CMD` 设置容器启动后默认执行的命令及其参数，但 CMD 能够被 docker run 后面跟的命令行参数替换。
3. `ENTRYPOINT` 配置容器启动时运行的命令。

### Shell 和 Exec 格式

我们可用两种方式指定 RUN、CMD 和 ENTRYPOINT 要运行的命令：Shell 格式和 Exec 格式，二者在使用上有细微的区别。

__Shell 格式__

     <instruction> <command>

如：

{% highlight dockerfile %}
RUN apt-get install python3  

CMD echo "Hello world"  

ENTRYPOINT echo "Hello world" 
{% endhighlight %}

当指令执行时，shell 格式底层会调用 `/bin/sh -c <command>` 。

例如下面的 Dockerfile 片段：

{% highlight dockerfile %}
ENV name Cloud Man  

ENTRYPOINT echo "Hello, $name" 
{% endhighlight %}

执行 `docker run <image>` 将输出：

    Hello, Cloud Man
 
注意环境变量 `name` 已经被值 `Cloud Man` 替换。

下面来看 Exec 格式。


__Exec 格式__

    <instruction> ["executable", "param1", "param2", ...]

例如：

{% highlight dockerfile %}
RUN ["apt-get", "install", "python3"]  

CMD ["/bin/echo", "Hello world"]  

ENTRYPOINT ["/bin/echo", "Hello world"] 
{% endhighlight %}


当指令执行时，会直接调用 `<command>`，不会被 shell 解析。

例如下面的 Dockerfile 片段：

{% highlight dockerfile %}
ENV name Cloud Man  

ENTRYPOINT ["/bin/echo", "Hello, $name"]
{% endhighlight %}


运行容器将输出：

    Hello, $name

注意环境变量“name”没有被替换。
如果希望使用环境变量，照如下修改

{% highlight dockerfile %}
ENV name Cloud Man  

ENTRYPOINT ["/bin/sh", "-c", "echo Hello, $name"]
{% endhighlight %}

运行容器将输出：

    Hello, Cloud Man

CMD 和 ENTRYPOINT 推荐使用 Exec 格式，因为指令可读性更强，更容易理解。RUN 则两种格式都可以


### RUN command

RUN 指令通常用于安装应用和软件包。

RUN 在当前镜像的顶部执行命令，并通过创建新的镜像层。Dockerfile 中常常包含多个 RUN 指令。

RUN 有两种格式：

1. Shell 格式：RUN
2. Exec 格式：RUN ["executable", "param1", "param2"]

下面是使用 RUN 安装多个包的例子：


{% highlight dockerfile %}
RUN apt-get update && apt-get install -y \  
 bzr \
 cvs \
 git \
 mercurial \
 subversion
{% endhighlight %}

>`apt-get update` 和 `apt-get install` 被放在一个 RUN 指令中执行，这样能够保证每次安装的是最新的包。如果 apt-get install 在单独的 RUN 中执行，则会使用 apt-get update 创建的镜像层，而这一层可能是很久以前缓存的。

### CMD  command

CMD 指令允许用户指定容器的默认执行的命令。

此命令会在容器启动且 `docker run` 没有指定其他命令时运行。

1. 如果 docker run 指定了其他命令，CMD 指定的默认命令将被忽略。
2. 如果 Dockerfile 中有多个 CMD 指令，只有最后一个 CMD 有效。

CMD 有三种格式：

1. Exec 格式：CMD ["executable","param1","param2"]<br/>这是 CMD 的推荐格式。
2. CMD ["param1","param2"] 为 ENTRYPOINT 提供额外的参数，此时 ENTRYPOINT 必须使用 Exec 格式。
3. Shell 格式：CMD command param1 param2

Exec 和 Shell 格式前面已经介绍过了。
第二种格式 `CMD ["param1","param2"]` 要与 Exec 格式 的 `ENTRYPOINT` 指令配合使用，其用途是为 ENTRYPOINT 设置默认的参数。我们将在后面讨论 ENTRYPOINT 时举例说明。

下面看看 CMD 是如何工作的。Dockerfile 片段如下：

{% highlight dockerfile %}
CMD echo "Hello world"
{% endhighlight %}

运行容器 docker run -it [image] 将输出：

    Hello world

但当后面加上一个命令，比如 docker run -it [image] /bin/bash，CMD 会被忽略掉，命令 bash 将被执行

### ENTRYPOINT command

ENTRYPOINT 指令可让容器以应用程序或者服务的形式运行。

ENTRYPOINT 看上去与 CMD 很像，它们都可以指定要执行的命令及其参数。不同的地方在于 ENTRYPOINT 不会被忽略，一定会被执行，即使运行 docker run 时指定了其他命令。

ENTRYPOINT 有两种格式：

1. Exec 格式：ENTRYPOINT ["executable", "param1", "param2"] 这是 ENTRYPOINT 的推荐格式。
2. Shell 格式：ENTRYPOINT command param1 param2

在为 ENTRYPOINT 选择格式时必须小心，因为这两种格式的效果差别很大。

#### Exec 格式

ENTRYPOINT 的 Exec 格式用于设置要执行的命令及其参数，同时可通过 CMD 提供额外的参数。

ENTRYPOINT 中的参数始终会被使用，而 CMD 的额外参数可以在容器启动时动态替换掉。

比如下面的 Dockerfile 片段：

{% highlight dockerfile %}
ENTRYPOINT ["/bin/echo", "Hello"]  

CMD ["world"]
{% endhighlight %}

当容器通过 `docker run -it [image]` 启动时，输出为：

    Hello world

而如果通过 `docker run -it [image] vicky` 启动，则输出为：

    Hello vicky

#### Shell 格式

ENTRYPOINT 的 Shell 格式会忽略任何 CMD 或 docker run 提供的参数。


## 最佳实践

使用 RUN 指令安装应用和软件包，构建镜像。

如果 Docker 镜像的用途是运行应用程序或服务，比如运行一个 MySQL，应该优先使用 Exec 格式的 ENTRYPOINT 指令。CMD 可为 ENTRYPOINT 提供额外的默认参数，同时可利用 docker run 命令行替换默认参数。

如果想为容器设置默认的启动命令，可使用 CMD 指令。用户可在 docker run 命令行中替换此默认命令。

到这里，我们已经具备编写 Dockerfile 的能力了。如果大家还觉得没把握，推荐一个快速掌握 Dockerfile 的方法：去 Docker Hub 上参考那些官方镜像的 Dockerfile。


