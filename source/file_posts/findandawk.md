---
title: find awk 和 grep 使用总结
date: 2017-02-23 23:57:54
tags: linux
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

## grep
Linux系统中grep命令是一种强大的文本搜索工具，它能使用正则表达式搜索文本，并把匹 配的行打印出来。grep全称是Global Regular Expression Print，表示全局正则表达式版本，它的使用权限是所有用户。
1. 格式
grep [options]

1. 主要参数
```
[options]主要参数：
－c：只输出匹配行的计数。
－I：不区分大小写(只适用于单字符)。
－h：查询多文件时不显示文件名。
－l：查询多文件时只输出包含匹配字符的文件名。
－n：显示匹配行及行号。
－s：不显示不存在或无匹配文本的错误信息。
－v：显示不包含匹配文本的所有行。
pattern正则表达式主要参数：
\： 忽略正则表达式中特殊字符的原有含义。
^：匹配正则表达式的开始行。
$: 匹配正则表达式的结束行。
\<：从匹配正则表达式单词边界。
\>：到匹配正则表达式单词边界。
[ ]：单个字符，如[A]即A符合要求 。
[ - ]：范围，如[A-Z]，即A、B、C一直到Z都符合要求 。
.：所有的单个字符。
* ：有字符，长度可以为0。
```
1. grep命令使用简单实例
$ grep ‘ERROR’ d*
匹配当前目录所有以d开头的文件中包含ERROR的行。
$ grep ‘ERROR’ a.log b.log c.log
显示在a.log b.log c.log 文件中匹配ERROR的行。
$ grep ‘[a-z]\{5\}’ a.log
显示所有包含每个字符串至少有5个连续小写字符的字符串的行。
$ grep ‘w\(es\)t.*\1′ a.log
如果west被匹配，则es就被存储到内存中，并标记为1，然后搜索任意个字符(.*)，这些字符后面紧跟着 另外一个es(\1)，找到就显示该行。如果用egrep或grep -E，就不用”\”号进行转义，直接写成’w(es)t.*\1′就可以了。

1. grep高级使用技巧
假设您正在’/usr/local/spark/’目录下搜索带字符 串’spark’的文件：
$ grep “spark” /usr/local/spark/*
默认情况下，’grep’只搜索当前目录。遇到子目录，’grep’报出：
grep: spark: Is a directory
-r选项可以第归搜索：grep -r
也可以忽略子目录：grep -d skip

1. grep其他参数：
grep -i pattern files ：不区分大小写地搜索。默认情况区分大小写，
grep -l pattern files ：只列出匹配的文件名，
grep -L pattern files ：列出不匹配的文件名，
grep -w pattern files ：只匹配整个单词，而不是字符串的一部分(如匹配’food’，而不是’foo’)，
grep -C number pattern files ：匹配的上下文分别显示[number]行，
如 grep -C 3 "hexo" source/_posts/* 查找hexo输出hexo前后各三行
grep pattern1 | pattern2 files ：显示匹配 pattern1 或 pattern2 的行，
grep pattern1 files | grep pattern2 ：显示既匹配 pattern1 又匹配 pattern2 的行。
grep -n pattern files  即可显示行号信息
grep -c pattern files  即可查找总行数

1. grep 正则表达式：
\< 和 \> 分别标注单词的开始与结尾。
例如：
grep good * 会匹配 ‘goodddd’、’ggood’、’good’等，
grep ‘\<good’ * 匹配’goodddd’和’good’，但不是’ggood’，
grep ‘\<good\>’ 只匹配’good’。
‘^’：指匹配的字符串在行首，
‘$’：指匹配的字符串在行 尾，
11. grep正则表达式可以使用类名
可以使用国际模式匹配的类名：
[[:upper:]]   [A-Z]
[[:lower:]]   [a-z]
[[:digit:]]   [0-9]
[[:alnum:]]   [0-9a-zA-Z]
[[:space:]]   空格或tab
[[:alpha:]]   [a-zA-Z]
grep '#[[:upper:]][[:upper:]]' data.doc     #查询以#开头紧跟着两个大写字
grep 在linux下使用很多，功能很全面，尤其是正则表达式使用得当可以很好的提升工作效率。
