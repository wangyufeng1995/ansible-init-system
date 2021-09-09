#!/bin/bash
# auth：骚猪
# data-2020-12-16

OpenSSL="openssl-1.1.1l" 
OpenSSH="openssh-8.7p1"
ZLIB="zlib-1.2.11"

dir=`cd $(dirname $0); pwd -P`
dir=`dirname $dir`
base_path=$dir/src

if [  -f ${base_path}/"${ZLIB}.tar.gz" -a  -f ${base_path}/"${OpenSSL}.tar.gz"  -a  -f ${base_path}/"${OpenSSH}.tar.gz"  ];then
        rpm -qa | grep openssh  | xargs rpm -e --nodeps
        cd ${base_path}
        tar xf ${ZLIB}.tar.gz
        cd ${ZLIB}
        ./configure --prefix=/usr/local/zlib
        make && make install
        echo '/usr/local/zlib/lib'  > /etc/ld.so.conf.d/zlib.conf
        ldconfig -v
        cd ${base_path}
        tar xf ${OpenSSL}.tar.gz
        cd ${OpenSSL}
        ./config --prefix=/usr/local/ssl -d shared
        make && make install
        echo '/usr/local/ssl/lib' > /etc/ld.so.conf.d/ssl.conf
        ldconfig -v
        cd ${base_path}
        tar xf ${OpenSSH}.tar.gz
        cd ${OpenSSH}
        ./configure --prefix=/usr/local/openssh --with-zlib=/usr/local/zlib --with-ssl-dir=/usr/local/ssl
        make && make install
fi

if [ -d "/usr/local/openssh/" ];then
        # 加载配置文件
        echo 'PermitRootLogin yes' >>/usr/local/openssh/etc/sshd_config
        echo 'PubkeyAuthentication yes' >>/usr/local/openssh/etc/sshd_config
        echo 'PasswordAuthentication yes' >>/usr/local/openssh/etc/sshd_config
        echo 'Port 22' >> /usr/local/openssh/etc/sshd_config
	echo 'UseDNS no' >> /usr/local/openssh/etc/sshd_config

        mv /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        cp /usr/local/openssh/etc/sshd_config /etc/ssh/sshd_config
        mv /usr/sbin/sshd /usr/sbin/sshd.bak
        cp /usr/local/openssh/sbin/sshd /usr/sbin/sshd
        mv /usr/bin/ssh /usr/bin/ssh.bak
        cp /usr/local/openssh/bin/ssh /usr/bin/ssh
        mv /usr/bin/ssh-keygen /usr/bin/ssh-keygen.bak
        cp /usr/local/openssh/bin/ssh-keygen /usr/bin/ssh-keygen
        mv /etc/ssh/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub.bak
        cp /usr/local/openssh/etc/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub
        cp /usr/local/openssh/etc/ssh_host_dsa_key.pub  /etc/ssh/ssh_host_dsa_key.pub

        cp -p contrib/redhat/sshd.init /etc/init.d/sshd
        chmod +x /etc/init.d/sshd

        #删除原有配置文件
        rm -rf /etc/ssh/sshd_config
        #创建软连接
        ln -s /usr/local/openssh/etc/sshd_config /etc/ssh/sshd_config

        chkconfig --add sshd
        chkconfig sshd on
        systemctl enable sshd
        systemctl restart sshd
if [[ "tcping 127.0.0.1 1221" || "tcping 127.0.0.1 22" ]];then 
	echo -e "\n"
else 
	echo "升级失败请检查端口,终端当前界面请使用23端口登陆"
fi

else
	echo "ERROR 请检查OpenSSL路径是否正确"
	cd ${base_path}
	rm -rf ${OpenSSL} ${ZLIB} ${OpenSSH}
fi

