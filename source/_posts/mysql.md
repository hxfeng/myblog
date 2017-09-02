---
title: mysql
date: 2017-09-02 14:53:27
category: 技术
tags: sql
---
# 常用命令
1. 连接
可以通过命令行直接连接，也可以通过代码连接，通过代码连接时要选择合适的驱动，连接时编码格式不一致会导致查询乱码。
> 格式： mysql -h主机地址 -u用户名 －p用户密码
> jdbc:mysql://localhost:3306/test?useUnicode=true&characterEncoding=gbk

1. 修改密码
> 格式：mysqladmin -u用户名 -p旧密码 password 新密码

1. 添加用户
> 格式：
```shell
grant all on database.* to user@hostname identified by "xxxx"
```

1. 创建数据库
> 命令：create database <数据库名>

1. 显示信息
```sql
show databases
show tables
desc tablename
```
1. 删除表，删除库
> drop database xxx
> drop table  xxx

1. 删除符合条件的记录
> delete from xxx where xxx=xxx

1. 查看版本
> select version(); 

1. 显示时间
select now()

1. 创建表
> create table <表名> ( <字段名1> <类型1> [,..<字段名n> <类型n>]);

1. 插入数据
> 命令：insert into <表名> [( <字段名1>[,..<字段名n > ])] values ( 值1 )[, ( 值n )]

1. 修改表中数据
> 语法：update 表名 set 字段=新值,… where 条件

# root 远程连接问题

允许mysql远程访问,可以使用以下三种方式:

a、改use表。
```sql
mysql -u root –p
mysql>use mysql;
mysql>update user set host = '%' where user = 'root';
mysql>select host, user from user;
```

b、授权。
```sql
例如，你想root使用123456从任何主机连接到mysql服务器。
mysql>GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123456' WITH GRANT OPTION;
如果你想允许用户jack从ip为10.10.50.127的主机连接到mysql服务器，并使用654321作为密码
mysql>GRANT ALL PRIVILEGES ON *.* TO 'jack'@’10.10.50.127’ IDENTIFIED BY '654321' WITH GRANT OPTION;
mysql>FLUSH RIVILEGES
```
c:在安装mysql的机器上运行：
```sql
//进入MySQL服务器
mysql -h localhost -u root
//赋予任何主机访问数据的权限
mysql>GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION
//使修改生效
mysql>FLUSH PRIVILEGES
//退出MySQL服务器
mysql>EXIT
```
# 中文编码问题
MySQL会出现中文乱码的原因不外乎下列几点：
1. server本身设定问题，例如还停留在latin1
2. table的语系设定问题(包含character与collation)
3. 客户端程式的连线语系设定问题
强烈建议使用utf8!!!!  utf8可以兼容世界上所有字符!!!!
 **避免创建数据库及表出现中文乱码和查看编码方法**

## 创建数据库的时候指定字符编码格式：
```sql
CREATE DATABASE `test`  
CHARACTER SET 'utf8'  
COLLATE 'utf8_general_ci';  
```
## 建表的时候指定表的编码格式 
```sql
CREATE TABLE `database_user` (  
`ID` varchar(40) NOT NULL default '',  
`UserID` varchar(40) NOT NULL default '',  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;  
```
这3个设置好了，基本就不会出问题了,即建库和建表时都使用相同的编码格式。
但是如果你已经建了库和表可以通过以下方式进行查询。
## 查看默认的编码格式:
```sql
mysql> show variables like "%char%";  
+--------------------------+---------------+  
| Variable_name | Value |  
+--------------------------+---------------+  
| character_set_client | gbk |  
| character_set_connection | gbk |  
| character_set_database | utf8 |  
| character_set_filesystem | binary |  
| character_set_results | gbk |  
| character_set_server | utf8 |  
| character_set_system | utf8 |  
+--------------------------+-------------+  
```
注：以前2个来确定,可以使用set names utf8,set names gbk设置默认的编码格式;
执行SET NAMES utf8的效果等同于同时设定如下：
```sql
SET character_set_client='utf8';  
SET character_set_connection='utf8';  
SET character_set_results='utf8';  
```

## 查看test数据库的编码格式:
```sql
mysql> show create database test;  
+------------+------------------------------------------------------------------------------------------------+  
| Database | Create Database |  
+------------+------------------------------------------------------------------------------------------------+  
| test | CREATE DATABASE `test` /*!40100 DEFAULT CHARACTER SET gbk */ |  
+------------+------------------------------------------------------------------------------------------------+  
```
## 查看yjdb数据表的编码格式:
```sql
mysql> show create table yjdb;  
| yjdb | CREATE TABLE `yjdb` (  
`sn` int(5) NOT NULL AUTO_INCREMENT,  
`type` varchar(10) NOT NULL,  
`brc` varchar(6) NOT NULL,  
`teller` int(6) NOT NULL,  
`telname` varchar(10) NOT NULL,  
`date` int(10) NOT NULL,  
`count` int(6) NOT NULL,  
`back` int(10) NOT NULL,  
PRIMARY KEY (`sn`),  
UNIQUE KEY `sn` (`sn`),  
UNIQUE KEY `sn_2` (`sn`)  
) ENGINE=MyISAM AUTO_INCREMENT=1826 DEFAULT CHARSET=gbk ROW_FORMAT=DYNAMIC |  
```

## 避免导入数据有中文乱码的问题
1:将数据编码格式保存为utf-8
设置默认编码为utf8：
set names utf8;
设置数据库db_name默认为utf8:

> ALTER DATABASE `db_name` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;  
设置表tb_name默认编码为utf8:
> ALTER TABLE `tb_name` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;  
导入：
[sql] view plain copy
LOAD DATA LOCAL INFILE 'C:\\utf8.txt' INTO TABLE yjdb;  
导入：
```sql
LOAD DATA LOCAL INFILE '/gbk.txt' INTO TABLE yjdb;  
```
注：1.UTF8不要导入gbk，gbk不要导入UTF8;
## 解决网页中乱码的问题
 将网站编码设为 utf-8,这样可以兼容世界上所有字符。
 如果网站已经运作了好久,已有很多旧数据,不能再更改简体中文的设定,那么建议将页面的编码设为 GBK, GBK与GB2312的区别就在于:GBK能比GB2312显示更多的字符,要显示简体码的繁体字,就只能用GBK。
 1. 编辑/etc/my.cnf　,在[mysql]段加入default_character_set=utf8;
 2. 在编写Connection URL时，加上?useUnicode=true&characterEncoding=utf-8参;
 3. 在网页代码中加上一个"set names utf8"或者"set names gbk"的指令，告诉mysql连线内容都要使用 utf8或者gbk;
