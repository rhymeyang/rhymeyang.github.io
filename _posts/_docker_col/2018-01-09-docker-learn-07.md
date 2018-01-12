---
layout: post
title:  "Docker系列 7 Registry"
date:   2017-07-30 01:08:04 +0800 
excerpted: |
    Docker 笔记
tags: ['linux', 'docker']
categories: docker_col
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}

## 使用公共 Registry

保存和分发镜像的最直接方法就是使用 Docker Hub。

Docker Hub 是 Docker 公司维护的公共 Registry。用户可以将自己的镜像保存到 Docker Hub 免费的 repository 中。如果不希望别人访问自己的镜像，也可以购买私有 repository。

除了 Docker Hub，quay.io 是另一个公共 Registry，提供与 Docker Hub 类似的服务。

下面介绍如何用 Docker Hub 存取我们的镜像。

+ 首先得在 Docker Hub 上注册一个账号。
+ 在 Docker Host 上登录。
+ 修改镜像的 repository 使之与 Docker Hub 账号匹配。
Docker Hub 为了区分不同用户的同名镜像，镜像的 registry 中要包含用户名，完整格式为：[username]/xxx:tag
我们通过 `docker tag` 命令重命名镜像。
    - >Docker 官方自己维护的镜像没有用户名，比如 httpd。
+ 通过 docker push 将镜像上传到 Docker Hub。

Docker 会上传镜像的每一层。因为 cloudman6/httpd:v1 这个镜像实际上跟官方的 httpd 镜像一模一样，Docker Hub 上已经有了全部的镜像层，所以真正上传的数据很少。同样的，如果我们的镜像是基于 base 镜像的，也只有新增加的镜像层会被上传。如果想上传同一 repository 中所有镜像，省略 tag 部分就可以了，例如：`docker push cloudman6/httpd`
+ 登录 https://hub.docker.com，在Public Repository 中就可以看到上传的镜像。
如果要删除上传的镜像，只能在 Docker Hub 界面上操作。
+ 这个镜像可被其他 Docker host 下载使用了。

## 搭建本地 Registry

Docker 已经将 Registry 开源了，同时在 Docker Hub 上也有官方的镜像 registry。下面我们就在 Docker 中运行自己的 registry。

### 启动 registry 容器。

    docker run -d -p 5000:5000 registry

如配置镜像存储到 Amazon S3 服务

    sudo docker run \
         -e SETTINGS_FLAVOR=s3 \
         -e AWS_BUCKET=acme-docker \
         -e STORAGE_PATH=/registry \
         -e AWS_KEY=AKIAHSHB43HS3J92MXZ \
         -e AWS_SECRET=xdDowwlK7TJajV1Y7EoOZrmuPEJlHYcNP2k4j49T \
         -e SEARCH_BACKEND=sqlalchemy \
         -p 5000:5000 \
         registry

指定本地路径（如 /home/user/registry-conf ）下的配置文件

{% highlight shell %}
sudo docker run -d -p 5000:5000 -v /home/user/registry-conf:/registry-conf -e DOCKER_REGISTRY_CONFIG=/registry-conf/config.yml registry

docker run -d -p 5000:5000 -v /media/backup/dockerrepo:/var/lib/registry registry

docker run -d -v /disk2/dockrepo:/var/lib/registry -p 5000:5000 registry
{% endhighlight %}

默认情况下，仓库会被创建在容器的 /var/lib/registry（v1 中是/tmp/registry）下。可以通过 `-v` 参数来将镜像文件存放在本地的指定路径。 例如下面的例子将上传的镜像放到 /opt/data/registry 目录。    

![start registry @x100]({{ '/registry_container.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})


我们使用的镜像是 registry:2。

+ `-d` 是后台启动容器。
+ `-p` 将容器的 5000 端口映射到 Host 的 5000 端口。5000 是 registry 服务端口。端口映射我们会在容器网络章节详细讨论。
+ `-v` 将容器 /var/lib/registry 目录映射到 Host 的 /myregistry，用于存放镜像数据。-v 的使用我们会在容器存储章节详细讨论。

### 通过 docker tag 重命名镜像，使之与 registry 匹配。

    docker tag cloudman6/httpd:v1 registry.example.net:5000/cloudman6/httpd:v1

我们在镜像的前面加上了运行 registry 的主机名称和端口。

前面已经讨论了镜像名称由 repository 和 tag 两部分组成。而 repository 的完整格式为：`[registry-host]:[port]/[username]/xxx`

只有 Docker Hub 上的镜像可以省略 [registry-host]:[port] 

### 3. 通过 docker push 上传镜像。  

![Docker push @x100]({{ '/docker_push_reg.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})

### 4. 现在已经可通过 docker pull 从本地 registry 下载镜像了。

![Docker pull @x100]({{ '/docker_pull_reg.jpg' | prepend: '/assets/img/used/docker'| absolute_url }})



### 5. 查询镜像

{% highlight shell %}
curl -X GET http://vickyRepo:5000/v2/_catalog
{% endhighlight %}


除了镜像的名称长一些（包含 registry host 和 port），使用方式完全一样。

以上是搭建本地 registry 的简要步骤。当然 registry 也支持认证，https 安全传输等特性，具体可以参考官方文档 https://docs.docker.com/registry/configuration/

## Docker 镜像小结

下面是镜像的常用操作子命令：

+ images    显示镜像列表
+ history   显示镜像构建历史
+ commit    从容器创建新镜像
+ build     从 Dockerfile 构建镜像
+ tag       给镜像打 tag
+ pull      从 registry 下载镜像
+ push      将 镜像 上传到 registry
+ rmi       删除 Docker host 中的镜像
+ search    搜索 Docker Hub 中的镜像


### rmi

rmi 只能删除 host 上的镜像，不会删除 registry 的镜像。

如果一个镜像对应了多个 tag，只有当最后一个 tag 被删除时，镜像才被真正删除。例如 host 中 debian 镜像有两个 tag：

删除其中 debian:latest 只是删除了 latest tag，镜像本身没有删除。

### search

search 让我们无需打开浏览器，在命令行中就可以搜索 Docker Hub 中的镜像。

当然，如果想知道镜像都有哪些 tag，还是得访问 Docker Hub。

至此，Docker 镜像已经讨论完了，下节我们深入讨论容器。

## 本地安装


 Ubuntu 或 CentOS 等发行版，可以直接通过源安装。

### Ubuntu

{% highlight shell %}
sudo apt-get install -y build-essential python-dev libevent-dev python-pip liblzma-dev
sudo pip install docker-registry
{% endhighlight %}



### CentOS

{% highlight shell %}
sudo yum install -y python-devel libevent-devel python-pip gcc xz-devel
#sudo python-pip install docker-registry
sudo yum install -y swig openssl
sudo pip install --upgrade pip
sudo pip install docker-registry
{% endhighlight %}

### 源码安装

{% highlight shell %}
$ sudo apt-get install build-essential python-dev libevent-dev python-pip libssl-dev liblzma-dev libffi-dev
$ git clone https://github.com/docker/docker-registry.git
$ cd docker-registry
$ sudo python setup.py install
{% endhighlight %}


也可从[docker-registry ](https://github.com/docker/docker-registry)  项目下载源码进行安装。


然后修改配置文件，主要修改 dev 模板段的 storage_path 到本地的存储仓库的路径。

{% highlight shell %}
$ cp config/config_sample.yml config/config.yml
{% endhighlight %}

之后启动 Web 服务。

{% highlight shell %}
$ sudo gunicorn -c contrib/gunicorn.py docker_registry.wsgi:application
{% endhighlight %}

或者

{% highlight shell %}
sudo gunicorn --access-logfile - --error-logfile - -k gevent -b 0.0.0.0:5000 -w 4 --max-requests 100 docker_registry.wsgi:application
{% endhighlight %}

此时使用 curl 访问本地的 5000 端口，看到输出 docker-registry 的版本信息说明运行成功。

>注：config/config_sample.yml 文件是示例配置文件。


## issue (docker-registry)

{% highlight shell %}
pip install docker-registry

Error : Unable to find 'openssl/opensslv.h'
{% endhighlight %}

安装openssl的头文件   

{% highlight shell %}
yum install openssl-devel

pip install docker-registry

swig -python -I/usr/include/python2.7 -I/usr/include -I/usr/include/openssl -includeall -modern -o SWIG/_m2crypto_wrap.c SWIG/_m2crypto.i
/usr/include/openssl/opensslconf.h:36: Error: CPP #error ""This openssl-devel package does not work your architecture?"". Use the -cpperraswarn option to continue swig processing.
{% endhighlight %}

查看一下安装的文件是否x86和x64位的头文件都有

{% highlight shell %}
ls /usr/include/openssl/
{% endhighlight %}

{% highlight c %}
#include "opensslconf-sparc.h"
#elif defined(__x86_64__)
#include "opensslconf-x86_64.h"    #原来是这样写的，说明默认去找x86_64位的头文件
#else
#error "This openssl-devel package does not work your architecture?"
#endif
 
#undef openssl_opensslconf_multilib_redirection_h   
{% endhighlight %}

<br/>
默认去找x86_64位的头文件报了错，那就说明希望去找x86的文件了，修改方法如下

{% highlight c %}

#include "opensslconf-sparc.h"
#elif defined(__x86_64__)
#include "opensslconf-x86_64.h"    #原来是这样写的，说明默认去找x86_64位的头文件
#else
#include "opensslconf.h"     #去掉了原来的error提示，改成了安装opensslconf.h文件。
#endif
 
#undef openssl_opensslconf_multilib_redirection_h   
{% endhighlight %}

再次运行

{% highlight shell %}
pip install docker-registry
{% endhighlight %}

## issue docker(https)

    # docker push 192.168.1.108:5000/reg:init
    The push refers to a repository [192.168.1.108:5000/reg]
    Get https://192.168.1.108:5000/v1/_ping: http: server gave HTTP response to HTTPS client

解决：

    Create or modify /etc/docker/daemon.json on the client machine

    { "insecure-registries":["myregistry.example.com:5000"] }
    Restart docker daemon

    sudo /etc/init.d/docker restart


If you are using Windows and you get this error you need to create a file here: 

    "C:\ProgramData\docker\config\daemon.json"  
    { "insecure-registries":["myregistry.example.com:5000"] }



## 参考

+ [error: command 'swig' failed with exit status 1](https://my.oschina.net/lionel45/blog/664017)
+ [registry API](https://docs.docker.com/registry/spec/api/)
+ [官方文档](https://docs.docker.com/registry/configuration/)