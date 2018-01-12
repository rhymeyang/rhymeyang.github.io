---
layout: post
title:  "Docker系列 1 安装"
date:   2017-07-09 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['环境配置','linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}

## 安装

### SET UP THE REPOSITORY

#### 相关包

`yum-utils` provides the `yum-config-manager` utility, and `device-mapper-persistent-data` and `lvm2` are required by the `devicemapper` storage driver

{% highlight shell %}
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
{% endhighlight %}

#### set up the stable repository


{% highlight shell %}
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    
sudo yum makecache fast

sudo yum-config-manager --disable docker-ce-edge
{% endhighlight %}

>官方文档，路径错误

### INSTALL DOCKER CE 

{% highlight shell %}
sudo yum install docker-ce
{% endhighlight %}

On production systems, you should install a specific version of Docker CE instead of always using the latest. 

{% highlight shell %}
yum list docker-ce --showduplicates | sort -r

sudo yum install <FULLY-QUALIFIED-PACKAGE-NAME>
{% endhighlight %}

#### Start Docker

{% highlight shell %}
sudo systemctl start docker
sudo systemctl enable docker
{% endhighlight %}

#### Verify

{% highlight shell %}
sudo docker run hello-world
{% endhighlight %}


## 基本命令


{% highlight shell %}
sudo docker search centos # ubuntu, fedora
sudo docker pull centos
sudo docker pull httpd
# check if docker images downloaded
sudo docker images centos

# run docker
sudo docker run -i -t centos /bin/bash
sudo docker run -d -p 80:80 httpd

# current running list
sudo docker ps
{% endhighlight %}


### 命令过程

{% highlight shell %}
docker run -d -p 80:80 httpd   
{% endhighlight %}

其过程可以简单的描述为：

1. 从 Docker Hub 下载 httpd 镜像。镜像中已经安装好了 Apache HTTP Server。
2. 启动 httpd 容器，并将容器的 80 端口映射到 host 的 80 端口。
3. 下面我们可以通过浏览器验证容器是否正常工作。在浏览器中输入 http://[your ubuntu host IP]

## Uninstall Docker CE

Uninstall the Docker package

{% highlight shell %}
sudo yum remove docker-ce
{% endhighlight %}

Images, containers, volumes, or customized configuration files on your host are not automatically removed. To delete all images, containers, and volumes:

{% highlight shell %}
sudo rm -rf /var/lib/docker
{% endhighlight %}

## 相关资源

+ [官方文档 install docker](https://docs.docker.com/engine/installation/)
+ [server - centos](https://store.docker.com/editions/community/docker-ce-server-centos)

