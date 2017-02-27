---
title: find awk 和 grep 使用总结
---
find awk 和 grep 使用总结
使用linux工作经常会用到find这个工具去查找文件，找到的文件可以通过awk进行操作，也可以配合grep
一起操作，这三个工具一起使用基本上可以高效的完成linux下百分之九十的文本处理工作，今天主要记录一下这三个
工具的使用方法。
<!--more-->
## find
如果我什么参数也不给，find会打印出当前目录下所有的文件和目录名
``` bash
find
.
./_posts
./_posts/hello-world.md
./_posts/findandawk.md
./_posts/test.md
```
这里有几个默认的参数
1. 默认查找的目录为当前目录
1. 默认查找匹配所有记录
1. 默认打印输出匹配到的记录-print
上面的这个find与下面的find输出一致

``` bash
find  ./ -print -name "*"
./
./-name
./_posts
./_posts/hello-world.md
./_posts/findandawk.md
./_posts/test.md
```
-print0可以去掉换行
``` bash
find  ./ -print0 -name "*"
././-name./_posts./_posts/hello-world.md./_posts/findandawk.md./_posts/test.md
```
-printf 可以格式化输出
```bash
find . -type f -printf " %Tc %p\n"
 Mon 27 Feb 2017 08:54:40 PM CST ./-name
 Mon 27 Feb 2017 12:31:29 AM CST ./_posts/hello-world.md
 Mon 27 Feb 2017 09:01:12 PM CST ./_posts/findandawk.md
 Sat 25 Feb 2017 01:56:06 AM CST ./_posts/test.md
```
格式化输出的参数有很多这里不一一列举具体可以参考手册 man find 看更多printf的相关内容
当然输出不是find的主要功能，find 主要还是查找功能。
find 可以按照文件名称，文件类型，权限权限，访问时间等等多种维度去查找,但是我们一般使用最多的是按照文件名称来查找的
```bash
按文件名查找
find ./ -name "*.md"
./_posts/hello-world.md
./_posts/findandawk.md
./_posts/test.md
按文件类型查找
find ./ -type f -name "*.md"
./_posts/hello-world.md
./_posts/findandawk.md
./_posts/test.md

一天以前的文件
find ./ -mtime +1
```
find还有一个exec的参数可以对找到的文件执行相应的操作，但是这个有一定的危险如果你执行的动作是
删除的话请慎重使用，但是rm在-exec里出现的使用频率往往很高
```bash
用ls列出找到的文件
./ -mtime +1 -exec ls -l {} \;
-rw-rw-r--. 1 fangqing fangqing 5456 Feb 25 01:56 ./_posts/test.md
强制删除当前目录下所有日志，这个动作很危险，要注意检查防止误操作
find ./ -name "*.log"  -exec rm -f {} \;
```
find的用法和参数实在是太多，有些高级技巧在需要的时候我就查一下手册，上面find的这些查找参数可以满足日常百分之九十的查找工作。
# awk
awk是一门脚本语言，awk是三位作者名字的首字母，关于awk起源的内容不写了。
awk是linux下文本处理的瑞士军刀，你可以通过awk把字符串按照你想要的格式进行切分、合并、拼接、转换
甚至算术运算。
首先需要记录一下awk的几个内置变量
```bash
awk
    ARGC        参数数量
    ARGIND      当前处理文件在ARGV中的索引
    ARGV        命令行参数数组
    FILENAME    当前处理文件的文件名
    FS          输入字段的分割符
    NF          记录字段数量.
    NR          当前输入的记录数量.
    OFMT        数字输出格式, 默认为"%.6g".
    OFS         输出字段分隔符.
    ORS         输出记录分割符.
    RS          输入记录分割符号.
```
这几个变量对awk处理文本有很大影响基本常用就是这几个变量下面记录几个案例
```bash
./ -print -name "*" -exec ls -l {} \; |awk '{print $NF}'
./
-name
_posts
./-name
./-name
./_posts
findandawk.md
hello-world.md
test.md
./_posts/hello-world.md
./_posts/hello-world.md
./_posts/findandawk.md
./_posts/findandawk.md
./_posts/test.md
./_posts/test.md
````
-F 可以指定字段分隔符，不指定时默认为空白字符，$NF输出最后一个字段.
未完待续。。。。
