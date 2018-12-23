#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi
clear
echo "+----------------------------------------------------------+"
echo "|            Wanglelecc for WAF,  Written by Licess             |"
echo "+----------------------------------------------------------+"
echo "|Usage: ./install.sh                                        |"
echo "+----------------------------------------------------------+"
cur_dir=$(pwd)
action=$1


Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

Set_Timezone()
{
    Echo_Blue "Setting timezone..."
    rm -rf /etc/localtime
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

InstallNTP()
{
    Echo_Blue "[+] Installing ntp..."
    yum install -y ntp
    ntpdate -u pool.ntp.org
    date
    start_time=$(date +%s)
}

RemoveAMP()
{
    Echo_Blue "[-] Yum remove packages..."
    rpm -qa|grep httpd
    rpm -e httpd httpd-tools --nodeps
    rpm -qa|grep mysql
    rpm -e mysql mysql-libs --nodeps
    rpm -qa|grep php
    rpm -e php-mysql php-cli php-gd php-common php --nodeps

    Remove_Error_Libcurl

    yum -y remove httpd*
    yum -y remove mysql-server mysql mysql-libs
    yum -y remove php*
    yum clean all
}

Get_RHEL_Version()
{
    if grep -Eqi "release 5." /etc/redhat-release; then
        echo "Current Version: RHEL Ver 5"
        RHEL_Ver='5'
    elif grep -Eqi "release 6." /etc/redhat-release; then
        echo "Current Version: RHEL Ver 6"
        RHEL_Ver='6'
    elif grep -Eqi "release 7." /etc/redhat-release; then
        echo "Current Version: RHEL Ver 7"
        RHEL_Ver='7'
    fi

}

Modify_Source()
{
    Get_RHEL_Version
    \cp ${cur_dir}/config/CentOS-Base-163.repo /etc/yum.repos.d/CentOS-Base-163.repo
    sed -i "s/\$releasever/${RHEL_Ver}/g" /etc/yum.repos.d/CentOS-Base-163.repo
    sed -i "s/RPM-GPG-KEY-CentOS-6/RPM-GPG-KEY-CentOS-${RHEL_Ver}/g" /etc/yum.repos.d/CentOS-Base-163.repo
    yum clean all
    yum makecache
}

Remove_Error_Libcurl()
{
    if [ -s /usr/local/lib/libcurl.so ]; then
        rm -f /usr/local/lib/libcurl*
    fi
}

Disable_Selinux()
{
    if [ -s /etc/selinux/config ]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

WAF_Init(){

    Modify_Source
    InstallNTP
    RemoveAMP
    Disable_Selinux

    # 关闭firewall
    systemctl stop firewalld.service
    systemctl disable firewalld.service

    echo "Update OS..."
    yum -y update

    echo "Installing dependent packages..."
    for packages in iptables-services subversion htop sysstat vim make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel patch wget crontabs libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel unzip tar bzip2 bzip2-devel libzip-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap diffutils ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel xz expat-devel libaio-devel rpcgen libtirpc-devel readline-devel pcre-devel postgresql-devel curl;
    do yum -y install $packages; done

    systemctl restart iptables.service
    systemctl enable iptables.service

    VIMRC_DIR='/etc/vimrc'
    TestVimrc=`grep "set fileencodings=utf-8,gbk" ${VIMRC_DIR} | wc -l`
    if [ "${TestVimrc}" -lt 1 ];then
        # 配置VIM
            cat >>${VIMRC_DIR}<<EOF
set fileencodings=utf-8,gbk
set nocompatible
syntax on
colorscheme desert
set number
set cursorline
set ruler
set shiftwidth=4
set softtabstop=4
set tabstop=4
set nobackup
set autochdir
filetype plugin indent on
set backupcopy=yes
set ignorecase smartcase
set nowrapscan
set incsearch
set hlsearch
set noerrorbells
set novisualbell
set showmatch
set matchtime=2
set magic
set hidden
set guioptions-=T
set guioptions-=m
set smartindent
set backspace=indent,eol,start
set cmdheight=1
set laststatus=2
set statusline=\ %<%F[%1*%M%*%n%R%H]%=\ %y\ %0(%{&fileformat}\ %{&encoding}\ %c:%l/%L%)\
set foldenable
set foldmethod=syntax
set foldcolumn=0
setlocal foldlevel=1
set foldclose=all
nnoremap <space> @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<CR>
EOF
    fi
}

Install_Pcre()
{
    echo "Installing pcre..."
    cd ${cur_dir}/src/
    tar -zxf pcre-8.42.tar.gz
    cd pcre-8.42
    ./configure --prefix=/usr/local/pcre
    make
    make install
}

Install_Openssl()
{
    echo "Installing openssl..."
    cd ${cur_dir}/src/
    tar -zxf openssl-1.1.0h.tar.gz
    cd openssl-1.1.0h
    ./config -fPIC --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
    make depend
    make
    make install

    TestPathIsOpenssl=`grep "/usr/local/openssl/bin" /etc/profile | wc -l`
if [ "${TestPathIsOpenssl}" -lt 1 ];then
cat >>/etc/profile<<EOF
export PATH=$PATH:/usr/local/openssl/bin
EOF
sysctl -p
fi
}

Install_Zlib(){
    echo "Installing zlib..."
    cd ${cur_dir}/src/
    tar -zxf zlib-1.2.11.tar.gz
    cd zlib-1.2.11
    ./configure --prefix=/usr/local/zlib
    make
    make install
}

Add_Iptables_Rules()
{
    if [ -s /sbin/iptables ]; then
        /sbin/iptables -I INPUT 1 -i lo -j ACCEPT
        /sbin/iptables -I INPUT 2 -m state --state ESTABLISHED,RELATED -j ACCEPT
        /sbin/iptables -I INPUT 3 -p tcp --dport 22122 -j ACCEPT
        /sbin/iptables -I INPUT 4 -p tcp --dport 80 -j ACCEPT
        /sbin/iptables -I INPUT 5 -p tcp --dport 443 -j ACCEPT
        /sbin/iptables -I INPUT 6 -p tcp --dport 3306 -j DROP
        /sbin/iptables -I INPUT 7 -p tcp --dport 6379 -j DROP
        /sbin/iptables -I INPUT 8 -p icmp -m icmp --icmp-type 9 -j ACCEPT

        service iptables save
        systemctl restart iptables.service
    fi
}

Install_OpenResty(){
    echo "Installing openResty..."
    groupadd www
    useradd -g www www -s /bin/false

    cd ${cur_dir}/src/
    tar -zxf openresty-1.13.6.2.tar.gz
    chmod -R 777 openresty-1.13.6.2
    cd openresty-1.13.6.2

    ./configure --prefix=/usr/local/openresty --with-luajit --without-http_redis2_module --with-http_iconv_module  --with-http_postgres_module --user=www --group=www --with-http_gzip_static_module --with-http_stub_status_module --with-openssl=${cur_dir}/src/openssl-1.1.0h --with-zlib=${cur_dir}/src/zlib-1.2.11 --with-pcre=${cur_dir}/src/pcre-8.42
    make
    make install

    Add_Iptables_Rules

    mkdir -p /usr/local/openresty/nginx/conf/ssl
    mkdir -p /usr/local/openresty/nginx/conf/vhost
    mkdir -p /usr/local/openresty/nginx/conf/lua
    mkdir -p /opt/verynginx

    \cp -f ${cur_dir}/config/nginx /etc/rc.d/init.d/nginx
    \cp -f ${cur_dir}/config/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
    \cp -f ${cur_dir}/config/access.lua /usr/local/openresty/nginx/conf/lua/access.lua
    \cp -f ${cur_dir}/config/proxy.conf /usr/local/openresty/nginx/conf/proxy.conf

    \cp -rf ${cur_dir}/config/verynginx /opt/verynginx/verynginx
    chown -R www.www /opt/verynginx/
    chmod 755 -R /opt/verynginx/

    chmod 775 /etc/rc.d/init.d/nginx
    chkconfig nginx on
    /etc/rc.d/init.d/nginx start

    mkdir -p /www/web
    mkdir -p /www/logs/nginx
    mkdir -p /www/logs/php
    mkdir -p /www/logs/mysql
    chown -R www.www /www
    chmod 755 -R /www
    chmod 777 -R /www/logs

	echo "openresty install success."
}


Install_Redis(){
    echo "Installing Resis..."

    if [ -s /usr/local/redis/bin/redis-server ]; then
        echo "Redis server already exists."
    else
        cd ${cur_dir}/src/
        tar -zxf redis-4.0.11.tar.gz
        cd redis-4.0.11
        make PREFIX=/usr/local/redis install

        mkdir -p /usr/local/redis/etc/
        \cp redis.conf  /usr/local/redis/etc/
        sed -i 's/daemonize no/daemonize yes/g' /usr/local/redis/etc/redis.conf
        if ! grep -Eqi '^bind[[:space:]]*127.0.0.1' /usr/local/redis/etc/redis.conf; then
            sed -i 's/^# bind 127.0.0.1/bind 127.0.0.1/g' /usr/local/redis/etc/redis.conf
        fi
        sed -i 's#^pidfile /var/run/redis_6379.pid#pidfile /var/run/redis.pid#g' /usr/local/redis/etc/redis.conf
        cd ../
		
		\cp ${cur_dir}/config/redis /etc/init.d/redis
		chmod +x /etc/init.d/redis
		/etc/init.d/redis start
		
		echo "redis install success."
    fi
}

Update_Ssh_Port(){
    echo "Installing dependent packages..."
    sed -i 's/^#Port 22/Port 22122/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
    sed -i 's#^-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT#-A INPUT -p tcp -m state --state NEW -m tcp --dport 22122 -j ACCEPT#' /etc/sysconfig/iptables

    mkdir -p /root/.ssh
    chmod 700 -R /root/.ssh

    cat >>/root/.ssh/authorized_keys<<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRZefPLqNhgCa++HsLHhYWfZW4TtFI40k9+i8esB46+aurQZzNx4Ij4euZNz2WlXg8OA+/6itTQMhszVgOVqEZhaiFKtB7SfFRr8HVEpnEeYIUXqswXhn8zt+7cn9NrpWa2oi1m5QYP9pz5DjsxktRKo33K6USXMBqHB62mc8JE7CwJLkXej5q8mGrRMikEb/nCujS4uk99cP0/s8cRYXblLh3d9XNvCek5k/gd3qUBx0xBqooU+0Vv4FEkcw690vWi0nNpRdycjB47MkWlwWeRvR4e7D6c9B8pF0pXT8FWe31ryWsdlBj8aQWA2/T993wAQ2FndJo/bQA+4URdt5J wanglele@gmail.com
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPYjJ1fgAOzf90L3hFn1IAiyOE8xIfCpkroBw85p2HadYxgMHEdR0hJPYLwN91LN3CY8B2l0mq+/fdGdSQmb4IFxL2atdgH8w/T3b6qszilQLqE4Y+bRCtQGRgEOL/cV6i1C5ltZGd6x9PmwHxi0KtqOYL+rF5z7t/bcBnenCoTyPfsbse039b7TQmCfAjAY9Ciy1utcZ0PzdD3d8QfLQjusux4Vycp6/xrqMu1kI/saBQmMVPS6VLNoTnazQgQe6b3svC/dCLSiYbzYK+F+ABcdw8G0pV2/JvR3UAkqZfGaNHlRhVLCC++MSpl8cXl55tPPDztFX7jTC6+iIXToKJ wanglelecc@gmail.com
EOF
    chmod 600 /root/.ssh/authorized_keys
    /etc/init.d/sshd restart
    systemctl restart iptables.service
    systemctl enable iptables.service
	
	echo "ssh update success"
}

Install_Nginx(){
    WAF_Init
    Install_Pcre
    Install_Openssl
    Install_Zlib
    Install_Redis
    Install_OpenResty
#    Update_Ssh_Port
}

case "${action}" in
nginx)
    Install_Nginx 2>&1 | tee /root/nginx-install.log
;;
sshd)
    Update_Ssh_Port 2>&1 | tee /root/sshd-update.log
;;
*)
    echo "Usage: raiing {nginx|sshd}"
esac