---
layout: post
title:  "Jekyll 环境配置"
date:   2018-01-01 01:08:04 +0800
excerpted: |
    CentOS中使用YUM安装的Ruby版本太低, 重新安装...
tags: ['前端','环境配置','linux', 'centos','jekyll','ruby']
categories: general
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}



## 环境

{% highlight shell %}
uname -a
{% endhighlight %}

>Linux mainCentOS.XXX 3.10.0-693.5.2.el7.x86_64 #1 SMP Fri Oct 20 20:32:50 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux



## 升级 Ruby

卸载默认版本

{% highlight shell %}
sudo yum remove ruby ruby-devel
{% endhighlight %}

安装

{% highlight shell %}
sudo yum groupinstall "Development Tools"
sudo yum install openssl-devel
wget http://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.0.tar.gz
tar xvf ruby-2.4.0.tar.gz
cd ruby-2.4.0
./configure
make
sudo make install
{% endhighlight %}

## 安装 Jekyll


{% highlight shell %}
sudo yum install gem
gem install jekyll bundler
{% endhighlight %}

### 版本查询

{% highlight shell %}
ruby -v

jekyll --version
{% endhighlight %}

>tags 大小写没转换，目前只使用小写

## 相关资源

+ [模板](http://jekyllthemes.org)
+ [本站模板](https://williamcanin.me/typing-jekyll-template/)
    - [related code](https://github.com/williamcanin/typing-jekyll-template)
+ [文档](http://jekyllcn.com)
+ [document](https://jekyllrb.com/docs/quickstart/)
+ [Liquid 模板语言中文文档](https://liquid.bootcss.com)

<div style="display:none;">
>Note
+ 直接把Home设置到postlist中，有错误提示：
>
>    Access to Font at 'http://localhost:9000/test/assets/vendor-off/fonts/gloria-hallelujah/GloriaHallelujah.ttf' from origin 'http://127.0.0.1:9000' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://127.0.0.1:9000' is therefore not allowed access.
</div>