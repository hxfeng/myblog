
systemctl 

Linux系统的启动方式有点复杂，而且总是有需要优化的地方。传统的Linux系统启动过程主要由著名的init进程（也被称为SysV init启动系统）处理，而基于init的启动系统被认为有效率不足的问题，systemd是Linux系统机器的另一种启动方式，宣称弥补了以传统Linux SysV init为基础的系统的缺点
systemd 的特性有：支持并行化任务；同时采用 socket 式与 D-Bus 总线式激活服务；按需启动守护进程（daemon）。利用 Linux 的 cgroups 监视进程；支持快照和系统恢复。维护挂载点和自己主动挂载点。各服务间基于依赖关系进行精密控制。
监视和控制systemd的主要命令是systemctl。

<-- more -->
该命令可用于查看系统状态和管理系统及服务。
详见man 1 systemctl

tips:
    - 在 systemctl 參数中加入 -H <username>@<主机名> 能够实现对其它机器的远程控制。
    - systemadm 是 systemd 的官方图形前端。官方软件仓库 提供了稳定版本号 systemd-ui。


# 基本工具
## 分析系统状态

显示系统状态:
```bash
$ systemctl status

● yutu.com
    State: running
     Jobs: 0 queued
   Failed: 0 units
    Since: Tue 2018-05-29 18:14:49 HKT; 4h 10min ago
   CGroup: /
           ├─1 /usr/lib/systemd/systemd --switched-root --system --deserialize 22
           ├─user.slice
           │ └─user-1000.slice
           │   └─session-1.scope
           │     ├─2057 gdm-session-worker [pam/gdm-password]
           │     ├─2072 /usr/bin/gnome-keyring-daemon --daemonize --login
           │     ├─2082 /usr/libexec/gnome-session-binary --session gnome-classic
           │     ├─2091 dbus-launch --sh-syntax --exit-with-session
           │     ├─2092 /usr/bin/dbus-daemon --fork --print-pid 5 --print-address 7 --session
           │     ├─2156 /usr/libexec/imsettings-daemon
           │     ├─2160 /usr/libexec/gvfsd
           │     ├─2165 /usr/libexec/gvfsd-fuse /run/user/1000/gvfs -f -o big_writes
           │     ├─2257 /usr/bin/ssh-agent /bin/sh -c exec -l /bin/bash -c "env GNOME_SHELL_SESSION_MODE=classic gnome-session --session gnome-classic"
           │     ├─2275 /usr/libexec/at-spi-bus-launcher
           │     ├─2280 /bin/dbus-daemon --config-file=/usr/share/defaults/at-spi2/accessibility.conf --nofork --print-address 3
...

```
输出激活的单元：
```bash
$ systemctl

$ systemctl list-units
```
输出执行失败的单元：

```bash
$ systemctl --failed
```
全部可用的单元文件存放在 
```bash
/etc/systemd/system/
/usr/lib/systemd/system/  
```
查看全部已安装服务：
```bash
$ systemctl list-unit-files
```
## 使用单元

一个单元配置文件能够描写叙述例如以下内容之中的一个：
系统服务（.service）
挂载点（.mount）
sockets（.sockets） 
系统设备（.device）
交换分区（.swap）
文件路径（.path）
启动目标（.target）
由 systemd 管理的计时器（.timer）

详情參阅 man 5 systemd.unit。
使用 systemctl 控制单元时，通常须要使用单元文件的全名，包括扩展名（比如 sshd.service）。可是有些单元能够在systemctl中使用简写方式。

    假设无扩展名，systemctl 默认把扩展名当作 .service
    比如 netcfg 和 netcfg.service 是等价的
    挂载点会自己主动转化为对应的 .mount 单元。比如 /home 等价于 home.mount
    设备会自己主动转化为对应的 .device 单元，所以 /dev/sda2 等价于 dev-sda2.device

    Note: 有一些单元的名称包括一个 @ 标记。 (e.g. name@string.service): 这意味着它是模板单元 name@.service 的一个 实例。 string 被称作实例标识符, 在 systemctl 调用模板单元时，会将其当作一个參数传给模板单元。模板单元会使用这个传入的參数取代模板中的 %I 指示符。
    在实例化之前。systemd 会先检查 name@string.suffix 文件是否存在（假设存在，应该就是直接使用这个文件。而不是模板实例化了）。

    大多数情况下，包换 @ 标记都意味着这个文件是模板。假设一个模板单元没有实例化就调用，该调用会返回失败，由于模板单元中的 %I 指示符没有被替换。

    Tip:
    下面的大部分命令都能够跟多个单元名, 具体信息參见 man systemctl。
    从systemd 220版本号開始, systemctl命令在enable、disable和mask子命令中添加了–now选项，能够实现激活的同一时候启动服务。取消激活的同一时候停止服务。


常用命令：
 systemctl start <Units>
 systemctl stop <Units>
 systemctl restart <Units>
 systemctl reload <Units>
 systemctl status <Units>
 systemctl is-enabled <Units>
 systemctl enable <Units>
 systemctl disable <Units>
 systemctl mask <Units>
 systemctl unmask <Units>
 systemctl help <Units>
 systemctl daemon-reload 

# 电源管理

安装 polkit 后才干够一般用户身份使用电源管理。
假设你正登录在一个本地的systemd-logind用户会话。且当前没有其它活动的会话。那么下面命令无需root权限就可以执行。否则（比如。当前有还有一个用户登录在某个tty），systemd 将会自己主动请求输入rootpassword。
重新启动：

$ systemctl reboot

退出系统并停止电源：

$ systemctl poweroff

待机：

$ systemctl suspend

休眠：

$ systemctl hibernate

混合休眠模式（同一时候休眠到硬盘并待机）：

$ systemctl hybrid-sleep

### 编写单元文件

systemd 单元文件的语法来源于 XDG桌面入口配置文件.desktop文件。最初的源头则是Microsoft Windows的.ini文件。

单元文件能够从两个地方载入。优先级从低到高各自是：
/usr/lib/systemd/system/: 软件包安装的单元
/etc/systemd/system/: 系统管理员安装的单元
当systemd执行在用户模式下时，使用的载入路径是全然不同的。
systemd 单元名仅能包括 ASCII 字符, 下划线和点号. 其它字符须要用 C-style “\x2d” 替换. 參阅 man systemd.unit 和 man systemd-escape.}}

单元文件的语法，能够參考系统已经安装的单元，也能够參考man systemd.service中的EXAMPLES章节。

    tips:
    以 # 开头的凝视可能也能用在 unit-files 中, 可是仅仅能在新行中使用。 不要在 systemd 的參数后面使用行末凝视， 否则 unit 将会启动失败。

# 处理依赖关系

使用systemd时，可通过正确编写单元配置文件来解决其依赖关系。

典型的情况是，单元A要求单元B在A启动之前执行。在此情况下。向单元A配置文件里的 [Unit] 段加入 Requires=B 和 After=B 就可以。若此依赖关系是可选的，可加入 Wants=B 和 After=B。请注意 Wants= 和 Requires= 并不意味着 After=，即假设 After= 选项没有制定，这两个单元将被并行启动。
依赖关系通常被用在服务（service）而不是目标（target）上。比如， network.target 通常会被某个配置网络接口的服务引入，所以，将自己定义的单元排在该服务之后就可以，由于 network.target 已经启动。
服务类型

编写自己定义的 service 文件时，能够选择几种不同的服务启动方式。启动方式可通过配置文件 [Service] 段中的 Type= 參数进行设置。

    Type=simple（默认值）：systemd觉得该服务将马上启动。服务进程不会fork。

    假设该服务要启动其它服务，不要使用此类型启动。除非该服务是socket激活型。

    Type=forking：systemd觉得当该服务进程fork，且父进程退出后服务启动成功。对于常规的守护进程（daemon），除非你确定此启动方式无法满足需求。使用此类型启动就可以。使用此启动类型应同一时候指定 PIDFile=，以便systemd能够跟踪服务的主进程。
    Type=oneshot：这一选项适用于仅仅执行一项任务、随后马上退出的服务。可能须要同一时候设置 RemainAfterExit=yes 使得 systemd 在服务进程退出之后仍然觉得服务处于激活状态。
    Type=notify：与 Type=simple 相同，但约定服务会在就绪后向 systemd 发送一个信号。

    这一通知的实现由 libsystemd-daemon.so 提供。

    Type=dbus：若以此方式启动。当指定的 BusName 出如今DBus系统总线上时。systemd觉得服务就绪。
    Type=idle: systemd会等待全部任务处理完毕后。才開始执行idle类型的单元。

    其它行为和Type=simple 相似。

type的很多其它解释能够參考 systemd.service(5)。
改动现存单元文件

比如。假设想加入一个额外的依赖。创建这么一个文件就可以：

/etc/systemd/system/<unit>.d/customdependency.conf
[Unit]
Requires=<新依赖>
After=<新依赖>

As another example, in order to replace the ExecStart directive for a unit that is not of type oneshot, create the following file:

/etc/systemd/system/unit.d/customexec.conf
[Service]
ExecStart=
ExecStart=new command

想知道为什么改动 ExecStart 前必须将其置空，參见 ([1]).
下面是自己主动重新启动服务的一个样例:

/etc/systemd/system/unit.d/restart.conf
[Service]
Restart=always
RestartSec=30

然后执行下面命令使更改生效：

 systemctl daemon-reload
 systemctl restart <单元>

此外，把旧的单元文件从 /usr/lib/systemd/system/ 拷贝到 /etc/systemd/system/，然后进行改动，也能够达到相同效果。

在 /etc/systemd/system/ 文件夹中的单元文件的优先级总是高于 /usr/lib/systemd/system/ 文件夹中的同名单元文件。注意，当 /usr/lib/ 中的单元文件因软件包升级变更时，/etc/ 中自己定义的单元文件不会同步更新。此外，你还得执行 systemctl reenable 。手动又一次启用该单元。因此。建议使用前面一种利用 *.conf 的方法。

    小贴士: 用 systemd-delta 命令来查看哪些单元文件被覆盖、哪些被改动。

    系统维护的时候须要及时了解哪些单元已经有了更新。

安装 vim-systemd 软件包，能够使 unit 配置文件在 Vim 下支持语法高亮。
目标（target）

启动级别（runlevel）是一个旧的概念。

如今，systemd 引入了一个和启动级别功能相似又不同的概念——目标（target）。不像数字表示的启动级别，每一个目标都有名字和独特的功能，而且能同一时候启用多个。一些目标继承其它目标的服务，并启动新服务。

systemd 提供了一些模仿 sysvinit 启动级别的目标。仍能够使用旧的 telinit 启动级别 命令切换。

获取当前目标

不要使用 runlevel 命令了：

$ systemctl list-units --type=target
创建服务

用service来管理服务的时候，是在/etc/init.d/目录中创建一个脚本文件，来管理服务的启动和停止，在systemctl中，也类似，文件目录有所不同，在/lib/systemd/system目录下创建一个脚本文件tomcat，里面的内容如下：

[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking
PIDFile=/usr/local/tomcat/pid
ExecStart=/usr/local/tomcat/bin/catalina.sh start
ExecReload=/usr/local/tomcat/bin/catalina.sh restart
ExecStop=/usr/local/tomcat/bin/catalina.sh stop

[Install]
WantedBy=multi-user.target


[Unit] 表示这是基础信息
    Description 是描述
    After 是在那个服务后面启动，一般是网络服务启动后启动
[Service] 表示这里是服务信息
    Type 是服务类型
    PIDFile 是服务的pid文件路径， 开启后，必须在tomcat的bin/catalina.sh中加入CATALINA_PID参数
    ExecStart 是启动服务的命令
    ExecReload 是重启服务的命令
    ExecStop 是停止服务的指令
[Install] 表示这是是安装相关信息
    WantedBy 是以哪种方式启动：multi-user.target表明当系统以多用户方式（默认的运行级别）启动时，这个服务需要被自动运行。

2. 创建软链接

创建软链接是为了下一步系统初始化时自动启动服务

ln -s /lib/systemd/system/tomcat.service /etc/systemd/system/multi-user.target.wants/tomcat.service


如果创建软连接的时候出现异常，不要担心，看看/etc/systemd/system/multi-user.target.wants/ 目录是否正常创建软链接为准，有时候报错只是提示一下，其实成功了。

$ ll /etc/systemd/system/multi-user.target.wants/
total 8
drwxr-xr-x  2 root root 4096 Mar 30 15:46 ./
drwxr-xr-x 13 root root 4096 Mar 13 14:18 ../
lrwxrwxrwx  1 root root   31 Nov 23 14:43 tomcat.service -> /lib/systemd/system/tomcat.service


3. 刷新配置

刚刚配置的服务需要让systemctl能识别，就必须刷新配置

$ systemctl daemon-reload

如果没有权限可以使用sudo

$ sudo systemctl daemon-reload

4. 启动、重启、停止

启动tomcat

$ systemctl start tomcat

重启tomcat

$ systemctl restart tomcat

停止tomcat

$ systemctl stop tomcat

5. 开机自启动

tomcat服务加入开机启动

$ systemctl enable tomcat


禁止开机启动

$ systemctl disable tomcat

6. 查看状态

$ systemctl status tomcat
