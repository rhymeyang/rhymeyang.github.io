---
layout: post
title:  "Docker系列 3 组件协作"
date:   2017-07-09 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}

## Docker 组件协作

{% highlight shell %}
docker run -d -p 80:80 httpd
{% endhighlight %}


1. Docker 客户端执行 docker run 命令。
2. Docker daemon 发现本地没有 httpd 镜像。
3. daemon 从 Docker Hub 下载镜像。
4. 下载完成，镜像 httpd 被保存到本地。
5. Docker daemon 启动容器。

`docker images` 可以查看到 httpd 已经下载到本地。

`docker ps` 或者 `docker container ls` 显示容器正在运行。

### 小结

Docker 借鉴了集装箱的概念。标准集装箱将货物运往世界各地，Docker 将这个模型运用到自己的设计哲学中，唯一不同的是：集装箱运输货物，而 Docker 运输软件。

每个容器都有一个软件镜像，相当于集装箱中的货物。容器可以被创建、启动、关闭和销毁。和集装箱一样，Docker 在执行这些操作时，并不关心容器里到底装的什么，它不管里面是 Web Server，还是 Database。

用户不需要关心容器最终会在哪里运行，因为哪里都可以运行。

开发人员可以在笔记本上构建镜像并上传到 Registry，然后 QA 人员将镜像下载到物理或虚拟机做测试，最终容器会部署到生产环境。

使用 Docker 以及容器技术，我们可以快速构建一个应用服务器、一个消息中间件、一个数据库、一个持续集成环境。因为 Docker Hub 上有我们能想到的几乎所有的镜像。

容器不但降低了我们学习新技术的门槛，更提高了效率。

如果你是一个运维人员，想研究负载均衡软件 HAProxy，只需要执行`docker run haproxy`，无需繁琐的手工安装和配置既可以直接进入实战。

如果你是一个开发人员，想学习怎么用 django 开发 Python Web 应用，执行 `docker run django`，在容器里随便折腾吧，不用担心会搞乱 Host 的环境。

