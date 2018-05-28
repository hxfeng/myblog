---
title: vpn  安装
date: 2018-05-29 05:07:28
category:
tags:
---




### 推荐适用国外主机
https://www.vultr.com/
#安装影梭
```bash
wget --no-check-certificate https://down.upx8.com/shell/shadowsocks-go.sh
chmod +x shadowsocks-go.sh
./shadowsocks-go.sh 2>&1 | tee shadowsocks-go.log
```

### 卸载方法：

./shadowsocks-go.sh uninstall

### 多端口多用户密码配置

编辑配置文件  /etc/shadowsocks/config.json

原有内容删除，插入以下配置
```bash
{
"server":"0.0.0.0",
"local_address":"127.0.0.1",
"local_port":1080,
"port_password":{
"8989":"password",
"7979":"password",
"6969":"password"
},
"timeout":300,
"method":"aes-256-cfb",
"fast_open": false
}
```
### 启动服务
```bash
/etc/init.d/shadowsocks restart
```
### 常用命令：
```bash
/etc/init.d/shadowsocks start 
/etc/init.d/shadowsocks stop 
/etc/init.d/shadowsocks restart 
/etc/init.d/shadowsocks status
```

### 防火墙端口打开
如果只能用第一个账号，其他2个账号都不能用，那是防火墙对另外的端口做了限制，此时可以让防火墙不拦截 7979和6969端口

具体命令：
```bash
firewall-cmd --zone=public --add-port=7979/tcp --permanent
firewall-cmd --reload
```
这时候你可以试试7979的这个账号是不是可以用了
同样再设置6969
```
firewall-cmd --zone=public --add-port=6969/tcp --permanent
firewall-cmd --reload
```
如果有人问怎么用ss客户端登录，先去下载：
https://github.com/shadowsocks/shadowsocks-windows/releases

安装后打开，然后设置，服务器地址和端口号记得对应

然后代理模式选择PAC，这样省流量，你也可以全局，反正500G一个月足够用了： 



