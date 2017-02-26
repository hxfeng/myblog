---
title: linux 小工具使用技巧
date: 2017-02-22 23:57:54
tags: linux
---
工作中几乎每天都需要使用linux，刚开始接触linux觉得很高大上，适合装逼用，后面用着用着发现这东西不仅可以装逼还可以提高工作效率，开源界的各路高手为linux/unix写了非常多实用的小工具，这些工具配合起来使用可以极大的提升我们工作效率，今天主要记录一下join，cut,sort,paste,uniq,split 这几个小工具。
<!--more-->
首先跟大家说一下，linux下很多工作归根结底都是对文本的操作，比如我们要找到所有的文本文件，然后找到特定的内容保存。首先查找文本文件用到的是find,通过find我们可以找到很多路径，这些路径我们通过管道传递给grep awk join cut 这些小工具，作进一步的操作，最后将结果重定向到一个文件中保存。find awk grep这几个东西很强大我们后面会记录他的详细用法。
# join的用法
join 普通文件关联
首先看下join的文档
```
join --help
Usage: join [OPTION]... FILE1 FILE2
For each pair of input lines with identical join fields, write a line to
standard output.  The default join field is the first, delimited
by whitespace.  When FILE1 or FILE2 (not both) is -, read standard input.

  -a FILENUM        also print unpairable lines from file FILENUM, where
                      FILENUM is 1 or 2, corresponding to FILE1 or FILE2
  -e EMPTY          replace missing input fields with EMPTY
  -i, --ignore-case  ignore differences in case when comparing fields
  -j FIELD          equivalent to '-1 FIELD -2 FIELD'
  -o FORMAT         obey FORMAT while constructing output line
  -t CHAR           use CHAR as input and output field separator
  -v FILENUM        like -a FILENUM, but suppress joined output lines
  -1 FIELD          join on this FIELD of file 1
  -2 FIELD          join on this FIELD of file 2
  --check-order     check that the input is correctly sorted, even
                      if all input lines are pairable
  --nocheck-order   do not check that the input is correctly sorted
  --header          treat the first line in each file as field headers,
                      print them without trying to pair them
      --help     display this help and exit
      --version  output version information and exit
```
上面这个 -1 -2 可以指定以那个字段为KEY来关联，这个也可以用-j来指定
比如我们有两个文件a.txt,b.txt
a.txt           
1 22            
2 33            
3 44            


 b.txt
 1   a
 2   b
 3   c


我们将两个文件关联到一起只需要一下操作
```
join  a.txt b.txt

1 22 a
2 33 b
3 44 c
```
按列关联在一起哪个文件在前面那个列就在前面

# paste 合并

比如我们有上面两个文件用paste来合并结果如下
```
paste a.txt b.txt

1 22     1   a
2 33     2   b
3 44     3   c
```
paste也可以通过-s将文件按行来合并
```
paste -s a.txt  b.txt 
1 22    2 33    3 44
1 a     2 b     3 c
```
paste-选项可以格式化输出内容，即对每一个（-），从标准输入中读一次数据。
join和paste都有其他参数比如下面会将两个文件以冒号分连接在一起：

```
paste -d: a.txt b.txt

1 22:1   a
2 33:2   b
3 44:3   c
```

# cut 切分
```
cut -d" " -f 1 a.txt 
1 
2 
3 
```
f可以指定输出切分的字段，d可以指定字段分隔符
# sort 排序
sort 可以对文件中的记录按照一定的规则排序
c.txt
1
3
5
7
11
2
4
6
10
8
9
```
sort c.txt 
1
10
11
2
3
4
5
6
7
8
9
```
以字母序排列
```
sort -n c.txt 
1
2
3
4
5
6
7
8
9
10
11

```
按照数字顺序进行排序，sort默认的是生序排列通过 r选项可以逆序排列。
其他选项如:
-k可以指定排序的字段，
-t可以指定字段分割符。
-f会将小写字母都转换为大写字母来进行比较，亦即忽略大小写
-c会检查文件是否已排好序，如果乱序，则输出第一个乱序的行的相关信息，最后返回1
-C会检查文件是否已排好序，如果乱序，不输出内容，仅返回1
-M会以月份来排序，比如JAN小于FEB等等
-b会忽略每一行前面的所有空白部分，从第一个可见字符开始比较。

uniq 可以去掉文件中重复的列 其实sort的u选项也可以完成同样的操作.
# split 和 dd 切分文件
split可以将大文件切割成小文件,但是使用起来不是很方便个人用的少不展开说了。

dd 也可以完成切割我个人觉得他更优雅一些,下面是我对自己在打包docker镜像时的分割操作，当时是由于网站上传文件的大小限制太大了不能上传，所以用dd将其且分成小文件。
```
#dd if=ubunt.tar bs=1024 count=97000 skip=0  of=ubuntu.tar.1
#dd if=ubunt.tar bs=1024 count=97000 skip=97000  of=ubuntu.tar.2
#cat ubuntu.tar.1 ubuntu.tar.2 > ubuntu.tar
dd if=f21.tar bs=1024 count=97000 skip=0  of=fedora.tar.1
dd if=f21.tar bs=1024 count=97000 skip=97000  of=fedora.tar.2
dd if=f21.tar bs=1024 count=97000 skip=194000  of=fedora.tar.3
dd if=mysql.tar bs=1024 count=97000 skip=0  of=mysql.tar.1
dd if=mysql.tar bs=1024 count=97000 skip=97000  of=mysql.tar.2
dd if=mysql.tar bs=1024 count=97000 skip=194000  of=mysql.tar.
```
其中bs表示写出块的大小，count表示写出块的数量，skip表示跳过多少个块，of表示输出文件，if表示输入文件.
这几个工具有很多种用法，恰当的使用可以提高效率。
