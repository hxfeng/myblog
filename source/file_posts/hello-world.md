---
title: hexo小试牛刀
date: 2017-02-21 23:57:54
tag: hexo
---
欢迎大家关注我的空间，这是我用hexo写的第一篇博客，主要介绍下hexo的基本用法,后续我将在这里记录我学习和生活中值得记录下来的一些东西，仅仅给自己一些记录，当然如果有人看到了觉得有用那也挺好。
## 入门
<!--more-->
###  创建一篇文章

``` bash
$ hexo new "My New Post"
```

详情请查阅: [Writing](https://hexo.io/docs/writing.html)

### 创建完成就可以通过server来查看结果

``` bash
$ hexo server
```

详情请查阅: [Server](https://hexo.io/docs/server.html)

### 生成静态文件

``` bash
$ hexo generate
```

详情请查阅: [Generating](https://hexo.io/docs/generating.html)

### 发布到远程仓库

``` bash
$ hexo deploy
```

想请参考: [Deployment](https://hexo.io/docs/deployment.html)
关于hexo的更多信息请登陆: [hexo](https://hexo.io/docs)

## 使用next
```
$ cd your-hexo-site
$ git clone https://github.com/iissnan/hexo-theme-next themes/next
```
从Next的Gihub仓库中获取最新版本。
启用
需要修改/root/_config.yml配置项theme：
```
# Extensions
## Plugins: http://hexo.io/plugins/
## Themes: http://hexo.io/themes/
theme: next
```
验证是否启用
```
$ hexo s --debug
```
ENOSPC Error (Linux)
```
  Sometimes when running the command $ hexo server it returns an error:

  Error: watch ENOSPC ...

  It can be fixed by running $ npm dedupe or, if that doesn’t help, try the following in the Linux console:

  $ echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
```
  This will increase the limit for the number of files you can watch.
