---
layout: post
title:  "Docker系列 6 镜像命名的最佳实践"
date:   2017-07-30 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}


我们已经学会构建自己的镜像了。接下来的问题是如何在多个 Docker Host 上使用镜像。

这里有几种可用的方法：

+ 用相同的 Dockerfile 在其他 host 构建镜像。
+ 将镜像上传到公共 Registry（比如 Docker Hub），Host 直接下载使用。
+ 搭建私有的 Registry 供本地 Host 使用。

第一种方法没什么特别的，前面已经讨论很多了。我们将讨论如何使用公共和私有 Registry 分发镜像。


### 为镜像命名

无论采用何种方式保存和分发镜像，首先都得给镜像命名。

当我们执行 `docker build` 命令时已经为镜像取了个名字，例如前面：

{% highlight shell %}
docker build -t ubuntu-with-vi
{% endhighlight %}

这里的 `ubuntu-with-vi` 就是镜像的名字。通过 dock images 可以查看镜像的信息。

![Docker image @x100]({{ '/docker_name.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

这里注意到 `ubuntu-with-vi` 对应的是 `REPOSITORY`，而且还有一个叫 `latest` 的 `TAG`。


实际上一个特定镜像的名字由两部分组成：repository 和 tag。

    [image name] = [repository]:[tag]

如果执行 docker build 时没有指定 tag，会使用默认值 latest。其效果相当于：

{% highlight shell %}
docker build -t ubuntu-with-vi:latest
{% endhighlight %}

`tag` 常用于描述镜像的版本信息，比如 httpd 镜像：

![httpd @x100]({{ '/http_info.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

当然 `tag` 可以是任意字符串，比如 ubuntu 镜像：

![ubuntu info @x100]({{ '/ubuntu_info.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})


>__小心 latest tag__
>
千万别被 latest tag 给误导了。latest 其实并没有什么特殊的含义。当没指明镜像 tag 时，Docker 会使用默认值 latest，仅此而已。

虽然 Docker Hub 上很多 repository 将 latest 作为最新稳定版本的别名，但这只是一种约定，而不是强制规定。

所以我们在使用镜像时最好还是避免使用 latest，明确指定某个 tag，比如 httpd:2.3，ubuntu:xenial。

### tag 使用最佳实践

借鉴软件版本命名方式能够让用户很好地使用镜像。

一个高效的版本命名方案可以让用户清楚地知道当前使用的是哪个镜像，同时还可以保持足够的灵活性。

每个 repository 可以有多个 tag，而多个 tag 可能对应的是同一个镜像。下面通过例子为大家介绍 Docker 社区普遍使用的 tag 方案。

假设我们现在发布了一个镜像 myimage，版本为 v1.9.1。那么我们可以给镜像打上四个 tag：1.9.1、1.9、1 和 latest。

![tag 1.9.1 @x100]({{ '/image_1.9.1.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})


我们可以通过 docker tag 命令方便地给镜像打 tag。


{% highlight shell %}
docker tag myimage-v1.9.1 myimage:1

docker tag myimage-v1.9.1 myimage:1.9

docker tag myimage-v1.9.1 myimage:1.9.1

docker tag myimage-v1.9.1 myimage:latest
{% endhighlight %}

<br/>
过了一段时间，我们发布了 v1.9.2。这时可以打上 1.9.2 的 tag，并将 1.9、1 和 latest 从 v1.9.1 移到 v1.9.2。

![tag 1.9.2 @x100]({{ '/image_1.9.2.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})


命令为：

{% highlight shell %}
docker tag myimage-v1.9.2 myimage:1

docker tag myimage-v1.9.2 myimage:1.9

docker tag myimage-v1.9.2 myimage:1.9.2

docker tag myimage-v1.9.2 myimage:latest
{% endhighlight %}

之后，v2.0.0 发布了。这时可以打上 2.0.0、2.0 和 2 的 tag，并将 latest 移到 v2.0.0。

命令为：

{% highlight shell %}
docker tag myimage-v2.0.0 myimage:2

docker tag myimage-v2.0.0 myimage:2.0

docker tag myimage-v2.0.0 myimage:2.0.0

docker tag myimage-v2.0.0 myimage:latest
{% endhighlight %}


这种 tag 方案使镜像的版本很直观，用户在选择非常灵活：

+ myimage:1 始终指向 1 这个分支中最新的镜像。
+ myimage:1.9 始终指向 1.9.x 中最新的镜像。
+ myimage:latest 始终指向所有版本中最新的镜像。

如果想使用特定版本，可以选择 myimage:1.9.1、myimage:1.9.2 或 myimage:2.0.0。

Docker Hub 上很多 repository 都采用这种方案，所以大家一定要熟悉。


