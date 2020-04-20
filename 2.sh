#!/bin/bash

blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
version_lt(){
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; 
}
#copy from ��ˮ�ݱ� ss scripts
if [[ -f /etc/redhat-release ]]; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
fi
function install(){
cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    server {
        listen       80;
        server_name  $your_domain;
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    }
}
EOF
	#����αװվ
	rm -rf /usr/share/nginx/html/*
	cd /usr/share/nginx/html/
	wget https://github.com/atrandys/v2ray-ws-tls/raw/master/web.zip >/dev/null 2>&1
    	unzip web.zip >/dev/null 2>&1
	systemctl stop nginx
	sleep 5
	#����https֤��
	if [ ! -d "/usr/src" ]; then
	    mkdir /usr/src
	fi
	mkdir /usr/src/trojan-cert /usr/src/trojan-temp
	curl https://get.acme.sh | sh
	~/.acme.sh/acme.sh  --issue  -d $your_domain  --standalone
    	~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /usr/src/trojan-cert/private.key \
        --fullchain-file /usr/src/trojan-cert/fullchain.cer
	if test -s /usr/src/trojan-cert/fullchain.cer; then
	systemctl start nginx
        cd /usr/src
	#wget https://github.com/trojan-gfw/trojan/releases/download/v1.13.0/trojan-1.13.0-linux-amd64.tar.xz
	wget https://api.github.com/repos/trojan-gfw/trojan/releases/latest >/dev/null 2>&1
	latest_version=`grep tag_name latest| awk -F '[:,"v]' '{print $6}'`
	rm -f latest
	wget https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-linux-amd64.tar.xz >/dev/null 2>&1
	tar xf trojan-${latest_version}-linux-amd64.tar.xz >/dev/null 2>&1
	#����trojan�ͻ���
	wget https://github.com/atrandys/trojan/raw/master/trojan-cli.zip >/dev/null 2>&1
	wget -P /usr/src/trojan-temp https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-win.zip >/dev/null 2>&1
	unzip trojan-cli.zip >/dev/null 2>&1
	unzip /usr/src/trojan-temp/trojan-${latest_version}-win.zip -d /usr/src/trojan-temp/ >/dev/null 2>&1
	cp /usr/src/trojan-cert/fullchain.cer /usr/src/trojan-cli/fullchain.cer
	mv -f /usr/src/trojan-temp/trojan/trojan.exe /usr/src/trojan-cli/ 
	trojan_passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
	cat > /usr/src/trojan-cli/config.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$your_domain",
    "remote_port": 443,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "fullchain.cer",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF
	rm -rf /usr/src/trojan/server.conf
	cat > /usr/src/trojan/server.conf <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/usr/src/trojan-cert/fullchain.cer",
        "key": "/usr/src/trojan-cert/private.key",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF
	cd /usr/src/trojan-cli/
	zip -q -r trojan-cli.zip /usr/src/trojan-cli/
	trojan_path=$(cat /dev/urandom | head -1 | md5sum | head -c 16)
	mkdir /usr/share/nginx/html/${trojan_path}
	mv /usr/src/trojan-cli/trojan-cli.zip /usr/share/nginx/html/${trojan_path}/
	#���������ű�
	
cat > ${systempwd}trojan.service <<-EOF
[Unit]  
Description=trojan  
After=network.target  
   
[Service]  
Type=simple  
PIDFile=/usr/src/trojan/trojan/trojan.pid
ExecStart=/usr/src/trojan/trojan -c "/usr/src/trojan/server.conf"  
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=1s
   
[Install]  
WantedBy=multi-user.target
EOF

	chmod +x ${systempwd}trojan.service
	systemctl start trojan.service
	systemctl enable trojan.service
	~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /usr/src/trojan-cert/private.key \
        --fullchain-file /usr/src/trojan-cert/fullchain.cer \
	--reloadcmd  "systemctl restart trojan"
	green "======================================================================"
	green "Trojan�Ѱ�װ��ɣ���ʹ��������������trojan�ͻ��ˣ��˿ͻ��������ú����в���"
	green "1��������������ӣ���������򿪣����ؿͻ��ˣ�ע����������ӽ���1��Сʱ��ʧЧ"
	blue "http://${your_domain}/$trojan_path/trojan-cli.zip"
	green "2�������ص�ѹ������ѹ�����ļ��У���start.bat���򿪲�����Trojan�ͻ���"
	green "3����stop.bat���ر�Trojan�ͻ���"
	green "4��Trojan�ͻ�����Ҫ������������ʹ�ã�����switchyomega��"
	green "======================================================================"
	else
        red "==================================="
	red "https֤��û������ɹ����Զ���װʧ��"
	green "��Ҫ���ģ�������ֶ��޸�֤������"
	green "1. ����VPS"
	green "2. ����ִ�нű���ʹ���޸�֤�鹦��"
	red "==================================="
	fi
}
function install_trojan(){
nginx_status=`ps -aux | grep "nginx: worker" |grep -v "grep"`
if [ -n "$nginx_status" ]; then
    systemctl stop nginx
fi
$systemPackage -y install net-tools socat
Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
Port443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`
if [ -n "$Port80" ]; then
    process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
    red "==========================================================="
    red "��⵽80�˿ڱ�ռ�ã�ռ�ý���Ϊ��${process80}�����ΰ�װ����"
    red "==========================================================="
    exit 1
fi
if [ -n "$Port443" ]; then
    process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
    red "============================================================="
    red "��⵽443�˿ڱ�ռ�ã�ռ�ý���Ϊ��${process443}�����ΰ�װ����"
    red "============================================================="
    exit 1
fi
CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
if [ "$CHECK" != "SELINUX=disabled" ]; then
    green "��⵽SELinux����״̬����ӷ���80/443�˿ڹ���"
    yum install -y policycoreutils-python >/dev/null 2>&1
    semanage port -m -t http_port_t -p tcp 80
    semanage port -m -t http_port_t -p tcp 443
fi
if [ "$release" == "centos" ]; then
    if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
    red "==============="
    red "��ǰϵͳ����֧��"
    red "==============="
    exit
    fi
    if  [ -n "$(grep ' 5\.' /etc/redhat-release)" ] ;then
    red "==============="
    red "��ǰϵͳ����֧��"
    red "==============="
    exit
    fi
    firewall_status=`systemctl status firewalld | grep "Active: active"`
    if [ -n "$firewall_status" ]; then
        green "��⵽firewalld����״̬����ӷ���80/443�˿ڹ���"
        firewall-cmd --zone=public --add-port=80/tcp --permanent
	firewall-cmd --zone=public --add-port=443/tcp --permanent
	firewall-cmd --reload
    fi
    rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
elif [ "$release" == "ubuntu" ]; then
    if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
    red "==============="
    red "��ǰϵͳ����֧��"
    red "==============="
    exit
    fi
    if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
    red "==============="
    red "��ǰϵͳ����֧��"
    red "==============="
    exit
    fi
    ufw_status=`systemctl status ufw | grep "Active: active"`
    if [ -n "$ufw_status" ]; then
        ufw allow 80/tcp
        ufw allow 443/tcp
    fi
    apt-get update
elif [ "$release" == "debian" ]; then
    ufw_status=`systemctl status ufw | grep "Active: active"`
    if [ -n "$ufw_status" ]; then
        ufw allow 80/tcp
        ufw allow 443/tcp
    fi
    apt-get update
fi
$systemPackage -y install  nginx wget unzip zip curl tar >/dev/null 2>&1
systemctl enable nginx
systemctl stop nginx
green "======================="
blue "������󶨵���VPS������"
green "======================="
read your_domain
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
if [ $real_addr == $local_addr ] ; then
	green "=========================================="
	green "       ����������������ʼ��װtrojan"
	green "=========================================="
	sleep 1s
        install
	
else
        red "===================================="
	red "����������ַ�뱾VPS IP��ַ��һ��"
	red "����ȷ�Ͻ����ɹ����ǿ�ƽű���������"
	red "===================================="
	read -p "�Ƿ�ǿ������ ?������ [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
            green "ǿ�Ƽ������нű�"
	    sleep 1s
	    install
	else
	    exit 1
	fi
fi
}

function repair_cert(){
systemctl stop nginx
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
if [ -n "$Port80" ]; then
    process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
    red "==========================================================="
    red "��⵽80�˿ڱ�ռ�ã�ռ�ý���Ϊ��${process80}�����ΰ�װ����"
    red "==========================================================="
    exit 1
fi
green "======================="
blue "������󶨵���VPS������"
blue "�����֮ǰʧ��ʹ�õ�����һ��"
green "======================="
read your_domain
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
if [ $real_addr == $local_addr ] ; then
    ~/.acme.sh/acme.sh  --issue  -d $your_domain  --standalone
    ~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /usr/src/trojan-cert/private.key \
        --fullchain-file /usr/src/trojan-cert/fullchain.cer \
	--reloadcmd  "systemctl restart trojan"
    if test -s /usr/src/trojan-cert/fullchain.cer; then
        green "֤������ɹ�"
	green "�뽫/usr/src/trojan-cert/�µ�fullchain.cer���طŵ��ͻ���trojan-cli�ļ���"
	systemctl restart trojan
	systemctl start nginx
    else
    	red "����֤��ʧ��"
    fi
else
    red "================================"
    red "����������ַ�뱾VPS IP��ַ��һ��"
    red "���ΰ�װʧ�ܣ���ȷ��������������"
    red "================================"
fi	
}

function remove_trojan(){
    red "================================"
    red "����ж��trojan"
    red "ͬʱж�ذ�װ��nginx"
    red "================================"
    systemctl stop trojan
    systemctl disable trojan
    rm -f ${systempwd}trojan.service
    if [ "$release" == "centos" ]; then
        yum remove -y nginx
    else
        apt autoremove -y nginx
    fi
    rm -rf /usr/src/trojan*
    rm -rf /usr/share/nginx/html/*
    green "=============="
    green "trojanɾ�����"
    green "=============="
}

function update_trojan(){
    /usr/src/trojan/trojan -v 2>trojan.tmp
    curr_version=`cat trojan.tmp | grep "trojan" | awk '{print $4}'`
    wget https://api.github.com/repos/trojan-gfw/trojan/releases/latest >/dev/null 2>&1
    latest_version=`grep tag_name latest| awk -F '[:,"v]' '{print $6}'`
    rm -f latest
    rm -f trojan.tmp
    if version_lt "$curr_version" "$latest_version"; then
        green "��ǰ�汾$curr_version,���°汾$latest_version,��ʼ��������"
        mkdir trojan_update_temp && cd trojan_update_temp
        wget https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-linux-amd64.tar.xz >/dev/null 2>&1
        tar xf trojan-${latest_version}-linux-amd64.tar.xz >/dev/null 2>&1
        mv ./trojan/trojan /usr/src/trojan/
        cd .. && rm -rf trojan_update_temp
        systemctl restart trojan
	/usr/src/trojan/trojan -v 2>trojan.tmp
	green "trojan������ɣ���ǰ�汾��`cat trojan.tmp | grep "trojan" | awk '{print $4}'`"
	rm -f trojan.tmp
    else
        green "��ǰ�汾$curr_version,���°汾$latest_version,��������"
    fi
   
   
}

start_menu(){
    clear
    green " ======================================="
    green " ���ܣ�һ����װtrojan      "
    green " ϵͳ��centos7+/debian9+/ubuntu16.04+"
    green " ��վ��www.atrandys.com              "
    green " Youtube��Randy's ����                "
    blue " ������"
    red " *�벻Ҫ���κ���������ʹ�ô˽ű�"
    red " *�벻Ҫ����������ռ��80��443�˿�"
    red " *���ǵڶ���ʹ�ýű�������ִ��ж��trojan"
    green " ======================================="
    echo
    green " 1. ׼������ѡ��� ��װtrojan"
    red " 2. �����ˣ�ѡ���  ж��trojan"
    green " 3. �汾�����ˣ�  ����trojan"
    green " 4.֤�������⣿  �޸�֤��"
    blue " 0. �����˰ݰ�"
    echo
    read -p "���������� :" num
    case "$num" in
    1)
    install_trojan
    ;;
    2)
    remove_trojan 
    ;;
    3)
    update_trojan 
    ;;
    4)
    repair_cert 
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "��������ȷ����"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu
function bbr_boost_sh(){
    bash <(curl -L -s -k "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh")
}

start_menu(){
    clear
    green " ===================================="
    green "  Jeffern Trojan һ����װ�Զ��ű�      "
    green " ϵͳ��centos7+/debian9+/ubuntu16.04+"
    green " Twitter:@jeffern12               "
    green " ===================================="
    echo
    red " ===================================="
    yellow " 1. ���� ��ʼ��װTrojan"
    red " ===================================="
    yellow " 2. ���Ӹ��ٶȰ� һ����װBBR PLUS"
    red " ===================================="
    yellow " 0. �����ˣ��ݰݣ�"
    red " ===================================="
    echo
    read -p "����������:" num
    case "$num" in
    1)
    install_trojan
    ;;
    2)
    bbr_boost_sh 
    0)
    exit 1
    ;;
    *)
    clear
    red "��������ȷ����"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu