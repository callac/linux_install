#!/bin/bash

#已完成【
# 修复漏洞
# 时间同步
# 允许最大文件打开数
# 添加用户并设置密码
# 设置主机名
# 安装oh-my-zsh
# 安装最新版nginx
# 安装docker
# 更改docker源为国内镜像仓库
# 】

#TODO MySQL安装待定，目前只用了ubuntu系统，centos后续补充

red='\033[31m'
green='\033[32m'
yellow='\033[33m'
magenta='\033[35m'
cyan='\033[36m'
none='\033[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

# Root
[[ $(id -u) != 0 ]] && echo -e "\n 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit 1

cmd="apt-get"

sys_bit=$(uname -m)

case $sys_bit in
i[36]86)
        v2ray_bit="32"
        caddy_arch="386"
        ;;
x86_64)
        v2ray_bit="64"
        caddy_arch="amd64"
        ;;
*armv6*)
        v2ray_bit="arm"
        caddy_arch="arm6"
        ;;
*armv7*)
        v2ray_bit="arm"
        caddy_arch="arm7"
        ;;
*aarch64* | *armv8*)
        v2ray_bit="arm64"
        caddy_arch="arm64"
        ;;
*)
        echo -e "
        哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}

        备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
        " && exit 1
        ;;
esac

# 笨笨的检测方法
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then

        if [[ $(command -v yum) ]]; then

                cmd="yum"

        fi

else

        echo -e "
        哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}

        备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
        " && exit 1

fi

#修复漏洞
patch_upgrade()
{
    # centos:
    # yum update

    # yum update kernel
    # yum update kernel-devel
    # yum update kernel-firmware
    # yum update kernel-headers

    # yum update kernel-tools
    # yum update kernel-tools-libs
    # yum update python-perf 


    # ubuntu:
    apt-get update
    apt-get dist-upgrade -y
    apt update && apt install linux-image-generic

    echo 
    echo -e "补丁修复升级完成，${red}脚本可不敢随意重启${none}，需要您手动 ${red}reboot ${none}重启生效"

}

#时间同步
sys_timezone() {
    IS_OPENVZ=
    if hostnamectl status | grep -q openvz; then
        IS_OPENVZ=1
    fi

    echo
    timedatectl set-timezone Asia/Shanghai
    timedatectl set-ntp true
    echo -e "已将你的主机设置为Asia/Shanghai时区并通过systemd-timesyncd自动同步时间。同步后的时间为${green} `date +"%Y-%m-%d %H:%M:%S"` ${none}"
    echo

    if [[ $IS_OPENVZ ]]; then
        echo
        echo -e "你的主机环境为 ${yellow}Openvz${none} ，建议使用${yellow}v2ray mkcp${none}系列协议。"
        echo -e "注意：${yellow}Openvz${none} 系统时间无法由虚拟机内程序控制同步。"
        echo -e "如果主机时间跟实际相差${yellow}超过90秒${none}，v2ray将无法正常通信，请发ticket联系vps主机商调整。"
    fi
}


#设置最大打开文件数 所有用户都生效
set_max_open_files(){
    if cat /etc/security/limits.conf |grep -v '#' |grep nofile ; then
        echo
        echo -e "${yellow} 你已经设置过了，就不要再执行了，当前的数值是: ${red}`ulimit -n`${none},如果没有生效，请检查下是否忘记重启了 ${none}"
    else
        echo
        limits=/etc/security/limits.conf
        echo "root soft nofile 65535" >> $limits
        echo "root hard nofile 65535" >> $limits
        echo "* soft nofile 65535" >> $limits
        echo "* hard nofile 65535" >> $limits
        echo -e "最大文件打开数已经设置到最大，需要您手动 ${red}reboot ${none}重启生效"
    fi
}


#添加用户并设置密码
add_user()
{
    echo  "starting add user ..."
    read -p "Username:" username
    read -p "Password:" password
    useradd $username
    # CentOS:
    # echo $password |passwd --stdin $username
    # ubuntu:
    echo "$username:$password"|chpasswd
    echo "user created !!!"
}


#设置交换分区
change_swap()
{
    if [[ -f /SwapDir/swap ]] ; then
        echo
        echo -e "${yellow} Your system swap is : ${none}"
        free -h
        echo -e "${red}你已经执行过了，我不允许你再执行${none}"
        echo
    else
        echo
        echo -e "${yellow} Your current swap is ${none}"
        free -h
        mkdir /SwapDir
        cd /SwapDir
        echo -e "${yellow}4G以内的物理内存，SWAP 设置为内存的2倍 ${none}"
        echo -e "${yellow}4-8G的物理内存，SWAP 等于内存大小 ${none}"
        echo -e "${yellow}8-64G 的物理内存，SWAP 设置为8G ${none}"
        echo -e "${yellow}64-256G物理内存，SWAP 设置为16G ${none}"
        echo -e "${red} Only one chance!!! ${none}"
        echo -e "${red} Only one chance!!! ${none}"
        echo -e "${red} Only one chance!!! ${none}"
        read -p "please input your swapfile size:(M)" size
        dd if=/dev/zero of=/SwapDir/swap bs=1M count=$size
        chmod 0600 swap
        mkswap /SwapDir/swap
        swapon /SwapDir/swap
        myFile=/etc/fstab.bak
        cd /etc
        if [ -f "$myFile" ];then
            rm -rf fstab.bak 
        else
            cp /etc/fstab /etc/fstab.bak 
        fi
        echo "/SwapDir/swap swap swap defaults 0 0">>/etc/fstab
        echo -e "${red} Done\!Congratulation\！System swap add successful\！ ${none}"
        echo -e "${yellow} Your system swap is \: ${none}"
        free -h
    fi

}

#设置主机名
set_hostname()
{
    echo "start set your hostname ..."
    read -p "please input your hostname: " hostname
    hostnamectl set-hostname $hostname
    echo "your hostname is set to" $hostname
}

#安装oh-my-zsh
install_ohmyzsh()
{
    echo "starting install oh-my-zsh ..."
    apt-get install zsh -y
    apt-get install git -y
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    echo "oh-my-zsh installed !!!"
}

#安装最新版nginx，并影藏版本信息，增加json日志格式，目前主要是ubuntu的
install_nginx(){
    echo "starting install nginx ..."
    if [[ -f /etc/nginx/nginx.conf ]] ; then
        echo
        echo -e "${yellow}你已经安装过nginx了，最好卸载后再来安装${none}"
    else
        apt-get install software-properties-common -y
        add-apt-repository ppa:nginx/stable -y
        apt-get update
        apt-get install nginx -y
        # 隐藏nginx版本号
        sed -i "s/.*server_tokens.*/        server_tokens off;/" /etc/nginx/nginx.conf
        # 增加 json日志格式
        cat > ./tmp_json.config <<eof
        log_format json '{"@timestamp":"\$time_iso8601",'
         '"slbip":"\$remote_addr",'
         '"clientip":"\$http_x_forwarded_for",'
         '"serverip":"\$server_addr",'
         '"size":\$body_bytes_sent,'
         '"responsetime":\$request_time,'
         '"domain":"\$host",'
         '"method":"\$request_method",'
         '"request":"\$request",'
         '"request_body":"\$request_body",'
         '"requesturi":"\$request_uri",'
         '"url":"\$uri",'
         '"appversion":"\$HTTP_APP_VERSION",'
         '"referer":"\$http_referer",'
         '"agent":"\$http_user_agent",'
         '"status":"\$status",'
         '"devicecode":"\$HTTP_HA"}';

eof

        sed -i '22r tmp_json.config' /etc/nginx/nginx.conf
        rm ./tmp_json.config

        #重新加载nginx
        service nginx restart

    fi
    
}

#安装supervisor
install_supervisor(){
   echo "starting install nginx ..."
    if [[ -f /etc/supervisor/supervisord.conf ]] ; then
        echo
        echo "${yellow}你已经安装过supervisor了，无需重新安装${none}"
    else
        apt-get update
        apt-get install supervisor -y
    fi   
}

#安装docker，这里还有卸载没处理，后续优化
install_docker()
{
    # centos版本的安装
    # echo "installing docker ..."
    # curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    # echo "docker installed !!!!!!!!!!!"
    # systemctl start docker && systemctl enable docker
    # echo "installing docker-compose ......"
    # wget https://github.com/docker/compose/releases/download/1.23.2/docker-compose-Linux-x86_64
    # mv docker-compose-Linux-x86_64 /usr/bin/docker-compose
    # chmod +x /usr/bin/docker-compose
    # echo "docker-compose installed !!!"


    # ubuntu版本
    echo "installing docker ..."
    apt-get remove docker docker-engine docker.io
    apt update
    echo "docker installed !!!!!!!!!!!"
    apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
    apt-get update
    apt-get install docker-ce -y
    echo "docker installed !!!"
    echo "docker version"
    docker -v

}


#更改docker源为国内镜像仓库
change_docker_mirror()
{
    cat >  /etc/docker/daemon.json <<EOF
{
"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF
    systemctl restart docker
    echo "docker mirror change successful"
}

#安装node_exporter,用于监控系统性能
install_node_exporter()
{

	port=9100
	grep_port=`netstat -tlpn | grep "\b${port}\b"`

    #因为是通过supervisor启动的，先判断是否安装了superviso
	if [[ ! -e /etc/supervisor/supervisord.conf ]] ; then
        echo
    	echo -e "${yellow}因为是通过supervisor安装的，请先执行install_supervisor相关序号后再来${none}"
	#
	elif [[ -e /var/node_exporter/node_exporter-0.17.0.linux-amd64/node_exporter ]] ; then #判断是否已经安装过
    	echo
    	echo -e "%{yellow}您已经安装过了，无需重复安装${node}"
	#
	elif [[ -n "$grep_port" ]] ; then  #判断9100端口是否被占用
    	echo
    	echo -e "${yellow}大佬，我需要用到${port}端口，已被您占用了，请您再检查下，检查命令是：netstat -tlpn | grep '\\\b${port}\\\b'${node}"
	else  #安装
    	wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz
    	mkdir /var/node_exporter
    	echo "decompression ..."
    	tar xf node_exporter-0.17.0.linux-amd64.tar.gz -C /var/node_exporter/
    	rm node_exporter-0.17.0.linux-amd64.tar.gz
		cat > /etc/supervisor/conf.d/node_exporter.conf <<eof
[program:node_exporter]
directory=/var/node_exporter/node_exporter-0.17.0.linux-amd64  ; 程序文件夹
command=/var/node_exporter/node_exporter-0.17.0.linux-amd64/node_exporter ; 启动程序的命令
user=root  ; 指定用户
priority=1 ; 优先级 默认：999，数值越小优先级越高
autostart=true    ; 是否随supervisor启动而自动启动
;startsecs=40    ; 启动正常运行多久，则为启动成功。默认为：1秒
stopasgroup=true    ; 默认为false,进程被杀死时，是否向这个进程组发送stop信号，包括子进程
killasgroup=true    ; 默认为false，向进程组发送kill信号，包括子进程
redirect_stderr=true    ; std_error日志重定向到std_out
stdout_logfile_maxbytes=50MB    ; 日志最大大小
stdout_logfile_backups=10    ; 日志最多保留数量
stdout_logfile=/var/log/supervisor/node_exporter.log    ; 日志路径

eof

		supervisorctl update
		echo "您已成功安装node_exporter"


	fi
	
}

#安装mysql,等待增加



print_systeminfo()
{
    echo "**********************************"
    echo -e "${yellow}Powered by callac${none}"
    echo -e "${yellow}Email: cq53767968@gmail.com${none}"
    echo "Hostname:" `hostname`
    # virtualization
    cat /proc/cpuinfo |grep vmx >> /dev/null
    if [ $? == 0 ]
    then
        echo "Supporting virtualization"
    else
        echo "Virtualization is not supported"
    fi
    echo "Cpu model:" `cat /proc/cpuinfo |grep "model name" | awk '{ print $4" "$5""$6" "$7 ; exit }'`
    echo "Memory:" `free -m |grep Mem | awk '{ print $2 }'` "M"
    echo -e "${red}Swap: " `free -m |grep Swap | awk '{ print $2 }'` "M${none}"
    echo -e "${red}ulimit: `ulimit -n`${none}"
    echo "Kernel version: " `cat /proc/version`
    echo -e "${red} 新机器建议1~5都执行一遍，其中第5个swap要根据实际情况判断执行 ${none}"
    echo "**********************************"
}

help()
{
    echo "1) patch_upgrade      6) add_user         11) change_docker_mirror"
    echo "2) sys_timezone        7) install_ohmyzsh        12) install_node_exporter"
    echo "3) set_max_open_files         8) install_nginx  13) exit"
    echo "4) set_hostname       9) install_supervisor  13) help"
    echo "5) change_swap                 10) install_docker"
}



main()
{
    print_systeminfo
    centos_funcs="patch_upgrade sys_timezone set_max_open_files set_hostname
                change_swap add_user install_ohmyzsh install_nginx install_supervisor install_docker change_docker_mirror install_node_exporter exit help"
    select centos_func in $centos_funcs:
    do
        case $REPLY in
        1) patch_upgrade
        ;;
        2) sys_timezone
        ;;
        3) set_max_open_files
        ;;
        4) set_hostname
        ;;
        5) change_swap
        ;;
        6) add_user
        ;;
        7) install_ohmyzsh
        ;;
        8) install_nginx
        ;;
        9) install_supervisor
        ;;
        10) install_docker
        ;;
        11) change_docker_mirror
        ;;
        12) install_node_exporter
        ;;
        13) exit
        ;;
        14) help
        ;;
        *) echo "please select a true num"
        ;;
        esac
    done
}

main
