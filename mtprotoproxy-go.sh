#! /bin/bash
######################################################
# Anything wrong? Contact me via telegram: @CN_SZTL. #
######################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function set_fonts_colors(){
	clear
	# Font colors
	default_fontcolor="\033[0m"
	red_fontcolor="\033[31m"
	green_fontcolor="\033[32m"
	warning_fontcolor="\033[33m"
	info_fontcolor="\033[36m"
	# Background colors
	red_backgroundcolor="\033[41;37m"
	green_backgroundcolor="\033[42;37m"
	yellow_backgroundcolor="\033[43;37m"
	# Fonts
	error_font="${red_fontcolor}[Error]${default_fontcolor}"
	ok_font="${green_fontcolor}[OK]${default_fontcolor}"
	warning_font="${warning_fontcolor}[Warning]${default_fontcolor}"
	info_font="${info_fontcolor}[Info]${default_fontcolor}"
}

function check_os(){
	clear
	echo -e "正在检测当前是否为ROOT用户..."
	if [ ${EUID} -eq "0" ]; then
		clear
		echo -e "${ok_font}检测到当前为Root用户。"
	else
		clear
		echo -e "${error_font}当前并非ROOT用户，请先切换到ROOT用户后再使用本脚本。"
		exit 1
	fi
	clear
	echo -e "正在检测此系统是否被支持..."
	if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ]; then
		System_OS="CentOS"
		[ -n "$(grep ' 7\.' /etc/redhat-release)" ] && OS_Version=7
		[ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && OS_Version=6
		[ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && OS_Version=5
	elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ]; then
		System_OS="CentOS"
		OS_Version=6
	elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ]; then
		System_OS="Debian"
		[ ! -e "$(command -v lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
		OS_Version=$(lsb_release -sr | awk -F. '{print $1}')
	elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ]; then
		System_OS="Debian"
		[ ! -e "$(command -v lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
		OS_Version=$(lsb_release -sr | awk -F. '{print $1}')
	elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ]; then
		System_OS="Ubuntu"
		[ ! -e "$(command -v lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
		OS_Version=$(lsb_release -sr | awk -F. '{print $1}')
		[ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && OS_Version=16
	else
		clear
		echo -e "${error_font}目前暂不支持您使用的操作系统。"
		exit 1
	fi
	echo -e "${ok_font}该脚本支持您的系统。"
	clear
	echo -e "正在检测系统构架是否被支持..."
	if [[ "$(uname -m)" == "i686" ]] || [[ "$(uname -m)" == "i386" ]]; then
		System_Bit="32"
	elif [[ "$(uname -m)" == *"armv7"* ]] || [[ "$(uname -m)" == "armv6l" ]]; then
		System_Bit="arm"
	elif [[ "$(uname -m)" == *"armv8"* ]] || [[ "$(uname -m)" == "aarch64" ]]; then
		System_Bit="arm64"
	elif [[ "$(uname -m)" == *"x86_64"* ]]; then
		System_Bit="64"
	elif [[ "$(uname -m)" == *"mips64le"* ]]; then
		System_Bit="mips64le"
	elif [[ "$(uname -m)" == *"mips64"* ]]; then
		System_Bit="mips64"
	elif [[ "$(uname -m)" == *"mipsle"* ]]; then
		System_Bit="mipsle"
	elif [[ "$(uname -m)" == *"mips"* ]]; then
		System_Bit="mips"
	elif [[ "$(uname -m)" == *"s390x"* ]]; then
		System_Bit="s390x"
	else
		clear
		echo -e "${error_font}目前暂不支持此系统的构架。"
		exit 1
	fi
	clear
	echo -e "${ok_font}该脚本支持您的系统构架。"
	clear
	echo -e "正在检测进程守护安装情况..."
	if [ -n "$(command -v systemctl)" ]; then
		clear
		daemon_name="systemctl"
		echo -e "${ok_font}您的系统中已安装 systemctl。"
	elif [ -n "$(command -v chkconfig)" ]; then
		clear
		daemon_name="chkconfig"
		echo -e "${ok_font}您的系统中已安装 chkconfig。"
	elif [ -n "$(command -v update-rc.d)" ]; then
		clear
		daemon_name="update-rc.d"
		echo -e "${ok_font}您的系统中已安装 update-rc.d。"
	else
		clear
		echo -e "${error_font}您的系统中没有配置进程守护工具，安装无法继续！"
		exit 1
	fi
	clear
	echo -e "${ok_font}Support OS: ${System_OS}${OS_Version} $(uname -m) with ${daemon_name}."
}

function check_install_status(){
	install_type=$(cat /usr/local/mtprotoproxy/install_type.txt)
	if [ ! -n "${install_type}" ]; then
		install_status="${red_fontcolor}未安装${default_fontcolor}"
		mtprotoproxy_use_command="${red_fontcolor}未安装${default_fontcolor}"
		connect_status="${red_fontcolor}未安装${default_fontcolor}"
	else
		install_status="${green_fontcolor}已安装${default_fontcolor}"
	fi
	mtprotoproxy_program=$(find /usr/local/mtprotoproxy/mtprotoproxy.py)
	if [ ! -n "${mtprotoproxy_program}" ]; then
		mtprotoproxy_status="${red_fontcolor}未安装${default_fontcolor}"
	else
		mtprotoproxy_pid=$(ps -ef |grep "mtprotoproxy" |grep -v "grep" | grep -v ".sh"| grep -v "init.d" |grep -v "service" |awk '{print $2}')
		if [ ! -n "${mtprotoproxy_pid}" ]; then
			mtprotoproxy_status="${red_fontcolor}未运行${default_fontcolor}"
			connect_status="${red_fontcolor}未运行${default_fontcolor}"
			mtprotoproxy_use_command="${red_fontcolor}未运行${default_fontcolor}"
		else
			mtprotoproxy_status="${green_fontcolor}正在运行${default_fontcolor} | ${green_fontcolor}${mtprotoproxy_pid}${default_fontcolor}"
			Address="$(wget -qO- -t1 -T2 -4 https://api.ip.sb/ip)"
			if [ ! -n "${Address}" ]; then
				Address="$(wget -qO- -t1 -T2 https://ipinfo.io/ip)"
			fi
			if [ -n "${Address}" ]; then
				connect_base_status="$(wget -qO- -t1 "https://tcp.srun.in/tcp.php?ip=${Address}&port=$(cat /usr/local/mtprotoproxy/config.py | grep "PORT = " | awk -F "PORT = " '{print $2}')&type=1")"
				if [ "${connect_base_status}" == "OK" ]; then
					connect_status="${green_fontcolor}正常连通${default_fontcolor}"
				elif [ "${connect_base_status}" == "Port closed" ]; then
					connect_status="${warning_fontcolor}端口未开启${default_fontcolor}"
				elif [ "${connect_base_status}" == "No" ]; then
					connect_status="${red_fontcolor}无法连通${default_fontcolor}"
				else
					connect_status="${red_fontcolor}检测失败${default_fontcolor}"
				fi
			else
				connect_status="${red_fontcolor}检测失败${default_fontcolor}"
			fi
			if [ -n "$(cat "/usr/local/mtprotoproxy/running_log.log" | sed 's/tg: //g' | grep "tg://")" ]; then
				mtprotoproxy_use_command="\n${green_backgroundcolor}$(cat "/usr/local/mtprotoproxy/running_log.log" | sed 's/tg: //g' | grep "tg://")${default_fontcolor}"
			elif [ -n "$(cat /usr/local/mtprotoproxy/config.py | grep "tg" | awk -F "\"tg\": \"" '{print $2}' | sed 's/\",//g')" ]; then
				mtprotoproxy_use_command="${green_backgroundcolor}https://t.me/proxy?server=${Address}&port=$(cat /usr/local/mtprotoproxy/config.py | grep "PORT = " | awk -F "PORT = " '{print $2}')&secret=$(cat /usr/local/mtprotoproxy/config.py | grep "tg" | awk -F "\"tg\": \"" '{print $2}' | sed 's/\",//g')${default_fontcolor}"
			else
				mtprotoproxy_use_command="${green_backgroundcolor}$(cat /usr/local/mtprotoproxy/telegram_link.txt)${default_fontcolor}"
			fi
		fi
	fi
}

function echo_install_list(){
	clear
	echo -e "脚本当前安装状态：${install_status}
--------------------------------------------------------------------------------------------------
	1.安装MTProtoProxy
--------------------------------------------------------------------------------------------------
MTProtoProxy当前运行状态：${mtprotoproxy_status}
当前服务器连通状况[To CN]：${connect_status}
	2.更新脚本
	3.更新程序
	4.卸载程序

	5.启动程序
	6.关闭程序
	7.重启程序

	8.显示连接信息
	9.封禁IP
	10.解封IP
--------------------------------------------------------------------------------------------------
Telegram代理链接：${mtprotoproxy_use_command}
--------------------------------------------------------------------------------------------------"
	stty erase '^H' && read -p "请输入序号：" determine_type
	if [[ ${determine_type} -ge 1 ]] && [[ ${determine_type} -le 10 ]]; then
		data_processing
	else
		clear
		echo -e "${error_font}请输入正确的序号！"
		exit 1
	fi
}

function data_processing(){
	clear
	echo -e "正在处理请求中..."
	if [[ ${determine_type} = "2" ]]; then
		upgrade_shell_script
	elif [[ ${determine_type} = "3" ]]; then
		prevent_uninstall_check
		upgrade_program
		restart_service
		clear
		echo -e "${ok_font}MTProtoProxy更新成功。"
	elif [[ ${determine_type} = "4" ]]; then
		prevent_uninstall_check
		uninstall_program
	elif [[ ${determine_type} = "5" ]]; then
		prevent_uninstall_check
		start_service
	elif [[ ${determine_type} = "6" ]]; then
		prevent_uninstall_check
		stop_service
	elif [[ ${determine_type} = "7" ]]; then
		prevent_uninstall_check
		restart_service
	elif [[ ${determine_type} = "8" ]]; then
		prevent_uninstall_check
		echo_connetion_info
	elif [[ ${determine_type} = "9" ]]; then
		prevent_uninstall_check
		banned_ip
	elif [[ ${determine_type} = "10" ]]; then
		prevent_uninstall_check
		unbanned_ip
	else
		prevent_install_check
		os_update
		generate_base_config
		clear
		if [[ ${determine_type} = "1" ]]; then
			clear
			mkdir -p /usr/local/mtprotoproxy
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}建立文件夹成功。"
			else
				clear
				echo -e "${error_font}建立文件夹失败！"
				clear_install_reason="建立文件夹失败。"
				clear_install
				exit 1
			fi
			cd /usr/local/mtprotoproxy
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}进入文件夹成功。"
			else
				clear
				echo -e "${error_font}进入文件夹失败！"
				clear_install_reason="进入文件夹失败。"
				clear_install
				exit 1
			fi
			curl "https://raw.githubusercontent.com/shell-script/mtprotoproxy-onekey/master/program.zip" -o "/usr/local/mtprotoproxy/program.zip"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}下载MTProtoProxy成功。"
			else
				clear
				echo -e "${error_font}下载MTProtoProxy文件失败！"
				clear_install_reason="下载MTProtoProxy文件失败。"
				clear_install
				exit 1
			fi
			unzip program.zip
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}解压MTProtoProxy文件成功。"
			else
				clear
				echo -e "${error_font}解压MTProtoProxy文件失败！"
				clear_install_reason="解压MTProtoProxy文件失败。"
				clear_install
				exit 1
			fi
			rm -f program.zip
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}删除MTProtoProxy压缩包成功。"
			else
				clear
				echo -e "${error_font}删除MTProtoProxy压缩包失败！"
				clear_install_reason="删除MTProtoProxy压缩包失败。"
				clear_install
				exit 1
			fi
			clear
			chmod +x "/usr/local/mtprotoproxy/mtprotoproxy.py"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}设置MTProtoProxy执行权限成功。"
			else
				clear
				echo -e "${error_font}设置MTProtoProxy执行权限失败！"
				clear_install_reason="设置MTProtoProxy执行权限失败。"
				clear_install
				exit 1
			fi
			clear
			input_port
			clear
			stty erase '^H' && read -p "请输入Secret(可空)：" install_secret
			if [ ! -n "${install_secret}" ]; then
				install_secret="$(head -n 512 /dev/urandom | md5sum | head -c 32)"
			fi
			clear
			echo -e "${info_font}This is your mtproto proxy connection info:"
			echo -e "Host:Port | ${green_backgroundcolor}${Address}:${install_port}${default_fontcolor}"
			echo -e "Secret | ${green_backgroundcolor}${install_secret}${default_fontcolor}\n\n"
			stty erase '^H' && read -p "请输入Proxy Tag(可空)：" install_proxytag
			if [ -n "${install_proxytag}" ]; then
				install_proxytag="AD_TAG = \"${install_proxytag}\""
			fi
			cat <<-EOF > /usr/local/mtprotoproxy/config.py
PORT = ${install_port}

USERS = {
    "tg": "${install_secret}",
}

${install_proxytag}
			EOF
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}写入MTPrtoProxy配置文件成功。"
			else
				clear
				echo -e "${error_font}写入MTPrtoProxy配置文件失败！"
				clear_install_reason="写入MTPrtoProxy配置文件失败。"
				clear_install
				exit 1
			fi
			if [ "${daemon_name}" == "systemctl" ]; then
				curl "https://raw.githubusercontent.com/shell-script/mtprotoproxy-onekey/master/mtprotoproxy.service" -o "/etc/systemd/system/mtprotoproxy.service"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}下载进程守护文件成功。"
				else
					clear
					echo -e "${error_font}下载进程守护文件失败！"
					clear_install_reason="下载进程守护文件失败。"
					clear_install
					exit 1
				fi
				systemctl daemon-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载进程守护文件成功。"
				else
					clear
					echo -e "${error_font}重载进程守护文件失败！"
					clear_install_reason="重载进程守护文件失败。"
					clear_install
					exit 1
				fi
				systemctl enable mtprotoproxy.service
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}设置MTProtoProxy开启自启动成功。"
				else
					clear
					echo -e "${error_font}设置MTProtoProxy开启自启动失败！"
					clear_install_reason="设置MTProtoProxy开启自启动失败。"
					clear_install
					exit 1
				fi
			elif [ "${daemon_name}" == "update-rc.d" ] || [ "${daemon_name}" == "chkconfig" ]; then
				curl "https://raw.githubusercontent.com/shell-script/mtprotoproxy-onekey/master/mtprotoproxy.sh" -o "/etc/init.d/mtprotoproxy"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}下载进程守护文件成功。"
				else
					clear
					echo -e "${error_font}下载进程守护文件失败！"
					clear_install_reason="下载进程守护文件失败。"
					clear_install
					exit 1
				fi
				chmod +x "/etc/init.d/mtprotoproxy"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}设置进程守护文件执行权限成功。"
				else
					clear
					echo -e "${error_font}设置进程守护文件执行权限失败！"
					clear_install_reason="设置进程守护文件执行权限失败。"
					clear_install
					exit 1
				fi
				if [ "${System_OS}" == "CentOS" ]; then
					chkconfig --add mtprotoproxy
					chkconfig mtprotoproxy on
				elif [ "${System_OS}" == "Debian" ] || [ "${System_OS}" == "Ubuntu" ]; then
					update-rc.d -f mtprotoproxy defaults
				fi
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}设置MTProtoProxy开启自启动成功。"
				else
					clear
					echo -e "${error_font}设置MTProtoProxy开启自启动失败！"
					clear_install_reason="设置MTProtoProxy开启自启动失败。"
					clear_install
					exit 1
				fi
			fi
			echo "1" > /usr/local/mtprotoproxy/install_type.txt
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}写入安装信息成功。"
			else
				clear
				echo -e "${error_font}写入安装信息失败！"
				clear_install
				exit 1
			fi
			restart_service
			echo_mtprotoproxy_config
		fi
	fi
	echo -e "\n${ok_font}请求处理完毕。"
}

function upgrade_shell_script(){
	clear
	echo -e "正在更新脚本中..."
	filepath=$(cd "$(dirname "$0")"; pwd)
	filename=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
	curl "https://raw.githubusercontent.com/shell-script/mtprotoproxy-onekey/master/mtprotoproxy-go.sh" -o "${filename}/mtprotoproxy-go.sh"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}脚本更新成功，脚本位置：\"${green_backgroundcolor}${filename}/$0${default_fontcolor}\"，使用：\"${green_backgroundcolor}bash ${filename}/$0${default_fontcolor}\"。"
	else
		clear
		echo -e "${error_font}脚本更新失败！"
	fi
}

function prevent_uninstall_check(){
	clear
	echo -e "正在检查安装状态中..."
	install_type=$(cat /usr/local/mtprotoproxy/install_type.txt)
	if [ "${install_type}" = "" ]; then
		clear
		echo -e "${error_font}您未安装本程序。"
		exit 1
	else
		echo -e "${ok_font}您已安装本程序，正在执行相关命令中..."
	fi
}

function start_service(){
	clear
	echo -e "正在启动服务中..."
	install_type=$(cat /usr/local/mtprotoproxy/install_type.txt)
	if [ "${install_type}" -eq "1" ]; then
		if [[ ${mtprotoproxy_pid} -eq 0 ]]; then
			service mtprotoproxy start
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}MTProtoProxy 启动成功。"
			else
				clear
				echo -e "${error_font}MTProtoProxy 启动失败！"
			fi
		else
			clear
			echo -e "${error_font}MTProtoProxy 正在运行。"
		fi
	fi
}

function stop_service(){
	clear
	echo -e "正在停止服务中..."
	install_type=$(cat /usr/local/mtprotoproxy/install_type.txt)
	if [ "${install_type}" -eq "1" ]; then
		if [[ ${mtprotoproxy_pid} -eq 0 ]]; then
			clear
			echo -e "${error_font}MTProtoProxy 未在运行。"
		else
			service mtprotoproxy stop
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}MTProtoProxy 停止成功。"
			else
				clear
				echo -e "${error_font}MTProtoProxy 停止失败！"
			fi
		fi
	fi
}

function restart_service(){
	clear
	echo -e "正在重启服务中..."
	install_type=$(cat /usr/local/mtprotoproxy/install_type.txt)
	if [ "${install_type}" -eq "1" ]; then
		service mtprotoproxy restart
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}MTProtoProxy 重启成功。"
		else
			clear
			echo -e "${error_font}MTProtoProxy 重启失败！"
		fi
	fi
}

function echo_connetion_info(){
	clear
	echo -e "正在获取连接信息中..."
	connectiong_port="$(cat "/usr/local/mtprotoproxy/config.py" | grep "PORT = " | awk -F "PORT = " '{print $2}')"
	if [ ! -n "${connectiong_port}" ]; then
		connectiong_port="$(cat "/usr/local/mtproto/install_port.txt")"
	fi
	connectiong_ips="$(netstat -anp | grep 'ESTABLISHED' | grep 'python3' | grep 'tcp' | grep ":${connectiong_port}" | awk '{print $5}' | awk -F ":" '{print $1}' | sort -u | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")"
	connectiong_ips_with_port="$(netstat -anp | grep 'ESTABLISHED' | grep 'python3' | grep 'tcp' | grep ":${connectiong_port}" | awk '{print $5}' | sort -u)"
	if [ ! -n "${connectiong_ips}" ]; then
		connectiong_ips_number=0
	else
		connectiong_ips_number="$(echo -e "${connectiong_ips}" | wc -l)"
	fi
	clear
	echo -e "${info_font}目前共有 ${connectiong_ips_number} 位用户连接到了此MTProtoProxy。"
	if [ "${connectiong_ips_number}" -gt "0" ]; then
		echo -e "\n${info_font}连接IP如下："
		for((count_number = "${connectiong_ips_number}"; count_number >= 1; count_number--))
		do
			current_ip="$(echo "${connectiong_ips}" |sed -n "$count_number"p)"
			current_ip_address="$(wget -qO- -t1 -T2 http://freeapi.ipip.net/${current_ip}|sed 's/\"//g;s/,//g;s/\[//g;s/\]//g')"
			echo -e "${green_backgroundcolor}[${current_ip_address}]${connectiong_ips_with_port}${default_fontcolor}"
			sleep 1
		done
	fi
}

function banned_ip(){
	clear
	stty erase '^H' && read -r -p "请输入欲封禁的IP地址[IPv4/IPv6]：" wanna_banned_ip
	if [ "${wanna_banned_ip}" != "${wanna_banned_ip#*[0-9].[0-9]}" ]; then
		wanna_banned_ip_type="IPv4"
	elif [ "${wanna_banned_ip}" != "${wanna_banned_ip#*:[0-9a-fA-F]}" ]; then
		wanna_banned_ip_type="IPv6"
	else
		clear
		echo -e "IP地址不正确，请检查无误后再试。"
		exit 1
	fi
	clear
	echo -e "${info_font}封禁说明：1.禁止该IP访问所有端口 2.仅禁止该IP访问当前端口"
	stty erase '^H' && read -r -p "请输入禁止类型(1/2，默认：2)：" wanna_banned_type
	if [ ! -n "${wanna_banned_type}" ]; then
		wanna_banned_type=2
	fi
	if [ "${wanna_banned_type}" == "1" ]; then
		if [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "7" ]; then
			if [ "${wanna_banned_ip}" != "${wanna_banned_ip#*[0-9].[0-9]}" ]; then
				firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${wanna_banned_ip}' reject"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}禁止 ${wanna_banned_ip}访问所有端口 请求成功。"
				else
					clear
					echo -e "${error_font}禁止 ${wanna_banned_ip}访问所有端口 请求失败！"
					exit 1
				fi
				firewall-cmd --complete-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载firewalld规则成功。"
				else
					clear
					echo -e "${error_font}重载firewalld规则失败！"
					exit 1
				fi
				if [ -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "REJECT" | grep "all")" ]; then
					clear
					echo -e "${ok_font}禁止 ${wanna_banned_ip}访问所有端口 成功。"
				else
					clear
					echo -e "${error_font}禁止 ${wanna_banned_ip}访问所有端口 失败。"
					exit 1
				fi
			elif [ "${wanna_banned_ip}" != "${wanna_banned_ip#*:[0-9a-fA-F]}" ]; then
				firewall-cmd --permanent --add-rich-rule="rule family='ipv6' source address='${wanna_banned_ip}' reject"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}禁止 ${wanna_banned_ip}访问所有端口 请求成功。"
				else
					clear
					echo -e "${error_font}禁止 ${wanna_banned_ip}访问所有端口 请求失败！"
					exit 1
				fi
				firewall-cmd --complete-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载firewalld规则成功。"
				else
					clear
					echo -e "${error_font}重载firewalld规则失败！"
					exit 1
				fi
				if [ -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "REJECT" | grep "all")" ]; then
					clear
					echo -e "${ok_font}禁止 ${wanna_banned_ip}访问所有端口 成功。"
				else
					clear
					echo -e "${error_font}禁止 ${wanna_banned_ip}访问所有端口 失败。"
					exit 1
				fi
			else
				clear
				echo -e "IP地址不正确，请检查无误后再试。"
				exit 1
			fi
		elif [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "5" ] || [ "${OS_Version}" == "6" ]; then
			service iptables save
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存当前iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存当前iptables规则失败！"
			fi
			iptables -I INPUT -s "${wanna_banned_ip}" -j DROP
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}禁止 ${wanna_banned_ip}访问所有端口 请求成功。"
			else
				clear
				echo -e "${error_font}禁止 ${wanna_banned_ip}访问所有端口 请求失败！"
				exit 1
			fi
			service iptables save
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存iptables规则失败！"
			fi
			if [ -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "DROP" | grep "all")" ]; then
				clear
				echo -e "${ok_font}禁止 ${wanna_banned_ip}访问所有端口 成功。"
			else
				clear
				echo -e "${error_font}禁止 ${wanna_banned_ip}访问所有端口 失败。"
				exit 1
			fi
		elif [[ ${System_OS} =~ ^Debian$|^Ubuntu$ ]];then
			iptables-save > /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存当前iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存当前iptables规则失败！"
			fi
			echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置iptables启动规则成功。"
			else
				clear
				echo -e "${error_font}配置iptables启动规则失败！"
				exit 1
			fi
			chmod +x /etc/network/if-pre-up.d/iptables
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}设置iptables启动文件执行权限成功。"
			else
				clear
				echo -e "${error_font}设置iptables启动文件执行权限失败！"
				exit 1
			fi
			iptables-restore < /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}导入iptables规则成功。"
			else
				clear
				echo -e "${error_font}导入iptables规则失败！"
				exit 1
			fi
			iptables -I INPUT -s "${wanna_banned_ip}" -j DROP
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}禁止 ${wanna_banned_ip}访问所有端口 请求成功。"
			else
				clear
				echo -e "${error_font}禁止 ${wanna_banned_ip}访问所有端口 请求失败！"
				exit 1
			fi
			iptables-save > /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存iptables规则失败！"
			fi
			if [ -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "DROP" | grep "all")" ]; then
				clear
				echo -e "${ok_font}禁止 ${wanna_banned_ip}访问所有端口 成功。"
			else
				clear
				echo -e "${error_font}禁止 ${wanna_banned_ip}访问所有端口 失败。"
				exit 1
			fi
		else
			clear
			echo -e "${error_font}目前暂不支持您使用的操作系统。"
			exit 1
		fi
	elif [ "${wanna_banned_type}" == "2" ]; then
		wanna_banned_port="$(cat /usr/local/mtprotoproxy/config.py | grep "PORT = " | awk -F "PORT = " '{print $2}')"
		if [ ! -n "${wanna_banned_port}" ]; then
			wanna_banned_port="$(cat "/usr/local/mtproto/install_port.txt")"
		fi
		if [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "7" ]; then
			if [ "${wanna_banned_ip}" != "${wanna_banned_ip#*[0-9].[0-9]}" ]; then
				firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${wanna_banned_ip}' port port='${wanna_banned_port}' protocol=tcp reject"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求成功。"
				else
					clear
					echo -e "${error_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求失败！"
					exit 1
				fi
				firewall-cmd --complete-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载firewalld规则成功。"
				else
					clear
					echo -e "${error_font}重载firewalld规则失败！"
					exit 1
				fi
				if [ -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "REJECT" | grep "tcp")" ]; then
					clear
					echo -e "${ok_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 成功。"
				else
					clear
					echo -e "${error_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 失败。"
					exit 1
				fi
			elif [ "${wanna_banned_ip}" != "${wanna_banned_ip#*:[0-9a-fA-F]}" ]; then
				firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${wanna_banned_ip}' port port='${wanna_banned_port}' protocol=tcp reject"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求成功。"
				else
					clear
					echo -e "${error_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求失败！"
					exit 1
				fi
				firewall-cmd --complete-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载firewalld规则成功。"
				else
					clear
					echo -e "${error_font}重载firewalld规则失败！"
					exit 1
				fi
				if [ -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "${wanna_banned_port}" | grep "REJECT" | grep "tcp")" ]; then
					clear
					echo -e "${ok_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 成功。"
				else
					clear
					echo -e "${error_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 失败。"
					exit 1
				fi
			else
				clear
				echo -e "IP地址不正确，请检查无误后再试。"
				exit 1
			fi
		elif [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "5" ] || [ "${OS_Version}" == "6" ]; then
			service iptables save
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存当前iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存当前iptables规则失败！"
			fi
			iptables -I INPUT -s "${wanna_banned_ip}" -p tcp --dport "${wanna_banned_port}" -j DROP
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求成功。"
			else
				clear
				echo -e "${error_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求失败！"
				exit 1
			fi
			service iptables save
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存iptables规则失败！"
			fi
			if [ -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "${wanna_banned_port}" | grep "DROP" | grep "tcp")" ]; then
				clear
				echo -e "${ok_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 成功。"
			else
				clear
				echo -e "${error_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 失败。"
				exit 1
			fi
		elif [[ ${System_OS} =~ ^Debian$|^Ubuntu$ ]];then
			iptables-save > /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存当前iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存当前iptables规则失败！"
			fi
			echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置iptables启动规则成功。"
			else
				clear
				echo -e "${error_font}配置iptables启动规则失败！"
				exit 1
			fi
			chmod +x /etc/network/if-pre-up.d/iptables
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}设置iptables启动文件执行权限成功。"
			else
				clear
				echo -e "${error_font}设置iptables启动文件执行权限失败！"
				exit 1
			fi
			iptables-restore < /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}导入iptables规则成功。"
			else
				clear
				echo -e "${error_font}导入iptables规则失败！"
				exit 1
			fi
			iptables -I INPUT -s "${wanna_banned_ip}" -p tcp --dport "${wanna_banned_port}" -j DROP
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求成功。"
			else
				clear
				echo -e "${error_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求失败！"
				exit 1
			fi
			iptables-save > /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存iptables规则失败！"
			fi
			if [ -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "${wanna_banned_port}" | grep "DROP" | grep "tcp")" ]; then
				clear
				echo -e "${ok_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 成功。"
			else
				clear
				echo -e "${error_font}禁止${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 失败。"
				exit 1
			fi
		else
			clear
			echo -e "${error_font}目前暂不支持您使用的操作系统。"
			exit 1
		fi
	else
		clear
		echo -e "${error_font}输入错误，请检查后重试。"
		exit 1
	fi
}

function unbanned_ip(){
	clear
	stty erase '^H' && read -r -p "请输入欲解封的IP地址[IPv4/IPv6]：" wanna_banned_ip
	if [ "${wanna_banned_ip}" != "${wanna_banned_ip#*[0-9].[0-9]}" ]; then
		wanna_banned_ip_type="IPv4"
	elif [ "${wanna_banned_ip}" != "${wanna_banned_ip#*:[0-9a-fA-F]}" ]; then
		wanna_banned_ip_type="IPv6"
	else
		clear
		echo -e "IP地址不正确，请检查无误后再试。"
		exit 1
	fi
	clear
	echo -e "${info_font}解禁说明：1.解禁该IP访问所有端口 2.仅解禁该IP访问当前端口"
	stty erase '^H' && read -r -p "请输入禁止类型(1/2，默认：2)：" wanna_banned_type
	if [ ! -n "${wanna_banned_type}" ]; then
		wanna_banned_type=2
	fi
	if [ "${wanna_banned_type}" == "1" ]; then
		if [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "7" ]; then
			if [ "${wanna_banned_ip}" != "${wanna_banned_ip#*[0-9].[0-9]}" ]; then
				firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='${wanna_banned_ip}' reject"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}解禁 ${wanna_banned_ip}访问所有端口 请求成功。"
				else
					clear
					echo -e "${error_font}解禁 ${wanna_banned_ip}访问所有端口 请求失败！"
					exit 1
				fi
				firewall-cmd --complete-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载firewalld规则成功。"
				else
					clear
					echo -e "${error_font}重载firewalld规则失败！"
					exit 1
				fi
				if [ ! -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "REJECT" | grep "all")" ]; then
					clear
					echo -e "${ok_font}解禁 ${wanna_banned_ip}访问所有端口 成功。"
				else
					clear
					echo -e "${error_font}解禁 ${wanna_banned_ip}访问所有端口 失败。"
					exit 1
				fi
			elif [ "${wanna_banned_ip}" != "${wanna_banned_ip#*:[0-9a-fA-F]}" ]; then
				firewall-cmd --permanent --remove-rich-rule="rule family='ipv6' source address='${wanna_banned_ip}' reject"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}解禁 ${wanna_banned_ip}访问所有端口 请求成功。"
				else
					clear
					echo -e "${error_font}解禁 ${wanna_banned_ip}访问所有端口 请求失败！"
					exit 1
				fi
				firewall-cmd --complete-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载firewalld规则成功。"
				else
					clear
					echo -e "${error_font}重载firewalld规则失败！"
					exit 1
				fi
				if [ ! -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "REJECT" | grep "all")" ]; then
					clear
					echo -e "${ok_font}解禁 ${wanna_banned_ip}访问所有端口 成功。"
				else
					clear
					echo -e "${error_font}解禁 ${wanna_banned_ip}访问所有端口 失败。"
					exit 1
				fi
			else
				clear
				echo -e "IP地址不正确，请检查无误后再试。"
				exit 1
			fi
		elif [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "5" ] || [ "${OS_Version}" == "6" ]; then
			service iptables save
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存当前iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存当前iptables规则失败！"
			fi
			iptables -D INPUT -s "${wanna_banned_ip}" -j DROP
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}解禁 ${wanna_banned_ip}访问所有端口 请求成功。"
			else
				clear
				echo -e "${error_font}解禁 ${wanna_banned_ip}访问所有端口 请求失败！"
				exit 1
			fi
			service iptables save
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存iptables规则失败！"
			fi
			if [ ! -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "DROP" | grep "all")" ]; then
				clear
				echo -e "${ok_font}解禁 ${wanna_banned_ip}访问所有端口 成功。"
			else
				clear
				echo -e "${error_font}解禁 ${wanna_banned_ip}访问所有端口 失败。"
				exit 1
			fi
		elif [[ ${System_OS} =~ ^Debian$|^Ubuntu$ ]];then
			iptables-save > /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存当前iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存当前iptables规则失败！"
			fi
			echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置iptables启动规则成功。"
			else
				clear
				echo -e "${error_font}配置iptables启动规则失败！"
				exit 1
			fi
			chmod +x /etc/network/if-pre-up.d/iptables
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}设置iptables启动文件执行权限成功。"
			else
				clear
				echo -e "${error_font}设置iptables启动文件执行权限失败！"
				exit 1
			fi
			iptables-restore < /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}导入iptables规则成功。"
			else
				clear
				echo -e "${error_font}导入iptables规则失败！"
				exit 1
			fi
			iptables -D INPUT -s "${wanna_banned_ip}" -j DROP
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}解禁 ${wanna_banned_ip}访问所有端口 请求成功。"
			else
				clear
				echo -e "${error_font}解禁 ${wanna_banned_ip}访问所有端口 请求失败！"
				exit 1
			fi
			iptables-save > /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存iptables规则失败！"
			fi
			if [ ! -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "DROP" | grep "all")" ]; then
				clear
				echo -e "${ok_font}解禁 ${wanna_banned_ip}访问所有端口 成功。"
			else
				clear
				echo -e "${error_font}解禁 ${wanna_banned_ip}访问所有端口 失败。"
				exit 1
			fi
		else
			clear
			echo -e "${error_font}目前暂不支持您使用的操作系统。"
			exit 1
		fi
	elif [ "${wanna_banned_type}" == "2" ]; then
		wanna_banned_port="$(cat /usr/local/mtprotoproxy/config.py | grep "PORT = " | awk -F "PORT = " '{print $2}')"
		if [ ! -n "${wanna_banned_port}" ]; then
			wanna_banned_port="$(cat "/usr/local/mtproto/install_port.txt")"
		fi
		if [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "7" ]; then
			if [ "${wanna_banned_ip}" != "${wanna_banned_ip#*[0-9].[0-9]}" ]; then
				firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='${wanna_banned_ip}' port port='${wanna_banned_port}' protocol=tcp reject"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求成功。"
				else
					clear
					echo -e "${error_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求失败！"
					exit 1
				fi
				firewall-cmd --complete-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载firewalld规则成功。"
				else
					clear
					echo -e "${error_font}重载firewalld规则失败！"
					exit 1
				fi
				if [ ! -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "REJECT" | grep "tcp")" ]; then
					clear
					echo -e "${ok_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 成功。"
				else
					clear
					echo -e "${error_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 失败。"
					exit 1
				fi
			elif [ "${wanna_banned_ip}" != "${wanna_banned_ip#*:[0-9a-fA-F]}" ]; then
				firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='${wanna_banned_ip}' port port='${wanna_banned_port}' protocol=tcp reject"
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求成功。"
				else
					clear
					echo -e "${error_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求失败！"
					exit 1
				fi
				firewall-cmd --complete-reload
				if [[ $? -eq 0 ]];then
					clear
					echo -e "${ok_font}重载firewalld规则成功。"
				else
					clear
					echo -e "${error_font}重载firewalld规则失败！"
					exit 1
				fi
				if [ ! -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "${wanna_banned_port}" | grep "REJECT" | grep "tcp")" ]; then
					clear
					echo -e "${ok_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 成功。"
				else
					clear
					echo -e "${error_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 失败。"
					exit 1
				fi
			else
				clear
				echo -e "IP地址不正确，请检查无误后再试。"
				exit 1
			fi
		elif [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "5" ] || [ "${OS_Version}" == "6" ]; then
			service iptables save
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存当前iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存当前iptables规则失败！"
			fi
			iptables -D INPUT -s "${wanna_banned_ip}" -p tcp --dport "${wanna_banned_port}" -j DROP
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求成功。"
			else
				clear
				echo -e "${error_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求失败！"
				exit 1
			fi
			service iptables save
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存iptables规则失败！"
			fi
			if [ ! -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "${wanna_banned_port}" | grep "DROP" | grep "tcp")" ]; then
				clear
				echo -e "${ok_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 成功。"
			else
				clear
				echo -e "${error_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 失败。"
				exit 1
			fi
		elif [[ ${System_OS} =~ ^Debian$|^Ubuntu$ ]];then
			iptables-save > /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存当前iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存当前iptables规则失败！"
			fi
			echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置iptables启动规则成功。"
			else
				clear
				echo -e "${error_font}配置iptables启动规则失败！"
				exit 1
			fi
			chmod +x /etc/network/if-pre-up.d/iptables
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}设置iptables启动文件执行权限成功。"
			else
				clear
				echo -e "${error_font}设置iptables启动文件执行权限失败！"
				exit 1
			fi
			iptables-restore < /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}导入iptables规则成功。"
			else
				clear
				echo -e "${error_font}导入iptables规则失败！"
				exit 1
			fi
			iptables -D INPUT -s "${wanna_banned_ip}" -p tcp --dport "${wanna_banned_port}" -j DROP
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求成功。"
			else
				clear
				echo -e "${error_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 请求失败！"
				exit 1
			fi
			iptables-save > /etc/iptables.up.rules
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}保存iptables规则成功。"
			else
				clear
				echo -e "${warning_font}保存iptables规则失败！"
			fi
			if [ ! -n "$(iptables -L -n | grep "${wanna_banned_ip}" | grep "${wanna_banned_port}" | grep "DROP" | grep "tcp")" ]; then
				clear
				echo -e "${ok_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 成功。"
			else
				clear
				echo -e "${error_font}解禁${wanna_banned_ip}访问 ${wanna_banned_port}端口tcp协议 失败。"
				exit 1
			fi
		else
			clear
			echo -e "${error_font}目前暂不支持您使用的操作系统。"
			exit 1
		fi
	else
		clear
		echo -e "${error_font}输入错误，请检查后重试。"
		exit 1
	fi
}

function prevent_install_check(){
	clear
	echo -e "正在检测安装状态中..."
	if [[ ${determine_type} = "1" ]]; then
		if [[ ${install_status} = "${green_fontcolor}已安装${default_fontcolor}" ]]; then
			echo -e "${error_font}您已经安装MTProtoProxy，请勿再次安装；如您需要重新安装，请先卸载后再使用安装功能。"
			exit 1
		else
			if [[ ${mtprotoproxy_status} = "${red_fontcolor}未安装${default_fontcolor}" ]]; then
				echo -e "${ok_font}系统检测到您的系统中未安装MTProtoProxy，正在执行命令中..."
			else
				echo -e "${error_font}您的系统中已经安装MTProtoProxy，请勿再次安装，若您需要使用本脚本，请先卸载后再使用安装功能。"
				exit 1
			fi
		fi
	fi
}

function uninstall_program(){
	clear
	echo -e "正在卸载中..."
	install_type=$(cat /usr/local/mtprotoproxy/install_type.txt)
	if [[ "${install_type}" -eq "1" ]]; then
		service mtprotoproxy stop
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}停止MTProtoProxy成功。"
		else
			clear
			echo -e "${error_font}停止MTProtoProxy失败！"
		fi
		if [ "${daemon_name}" == "systemctl" ]; then
			systemctl disable mtprotoproxy.service
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}取消开机自启动成功。"
			else
				clear
				echo -e "${error_font}取消开机自启动失败！"
			fi
			rm -f /etc/systemd/system/mtprotoproxy.service
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}删除进程守护文件成功。"
			else
				clear
				echo -e "${error_font}删除进程守护文件失败！"
			fi
		elif [ "${daemon_name}" == "update-rc.d" ] || [ "${daemon_name}" == "chkconfig" ]; then
			if [ "${System_OS}" == "CentOS" ]; then
				chkconfig --del mtprotoproxy
			elif [[ ${System_OS} =~ ^Debian$|^Ubuntu$ ]];then
				update-rc.d -f mtprotoproxy remove
			fi
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}取消开机自启动成功。"
			else
				clear
				echo -e "${error_font}取消开机自启动失败！"
			fi
			chmod -x /etc/init.d/mtprotoproxy
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}取消进程守护文件执行权限成功。"
			else
				clear
				echo -e "${error_font}取消进程守护文件执行权限失败！"
			fi
			rm -f /etc/init.d/mtprotoproxy
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}删除进程守护文件成功。"
			else
				clear
				echo -e "${error_font}删除进程守护文件失败！"
			fi
		else
			clear
			echo -e "${error_font}您的系统中没有安装进程守护工具，已跳过本步骤！"
		fi
		close_port
		rm -rf /usr/local/mtprotoproxy
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}删除MTProtoProxy文件夹成功。"
		else
			clear
			echo -e "${error_font}删除MTProtoProxy文件夹失败！"
		fi
		clear
		echo -e "${ok_font}MTProtoProxy卸载成功。"
	fi
}

function upgrade_program(){
	clear
	echo -e "正在更新程序中..."
	install_type=$(cat /usr/local/mtprotoproxy/install_type.txt)
	if [ "${install_type}" -eq "1" ]; then
		clear
		cd /usr/local/mtprotoproxy
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}进入MTProtoProxy目录成功。"
		else
			clear
			echo -e "${error_font}进入MTProtoProxy目录失败！"
			exit 1
		fi
		mv /usr/local/mtprotoproxy/mtprotoproxy.py /usr/local/mtprotoproxy/mtprotoproxy.py.bak
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}备份旧文件成功。"
		else
			clear
			echo -e "${error_font}备份旧文件失败！"
			exit 1
		fi
		mv /usr/local/mtprotoproxy/pyaes /usr/local/mtprotoproxy/pyaes_bak
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}备份旧文件成功。"
		else
			clear
			echo -e "${error_font}备份旧文件失败！"
			rm -f /usr/local/mtprotoproxy/mtprotoproxy.py.bak
			exit 1
		fi
		echo -e "更新MTProtoProxy主程序中..."
		clear
		curl "https://raw.githubusercontent.com/shell-script/mtprotoproxy-onekey/master/program.zip" -o "/usr/local/mtprotoproxy/program.zip"
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}下载MTProtoProxy文件成功。"
		else
			clear
			echo -e "${error_font}下载MTProtoProxy文件失败！"
			mv /usr/local/mtprotoproxy/mtprotoproxy.py.bak /usr/local/mtprotoproxy/mtprotoproxy.py
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}恢复备份文件成功。"
			else
				clear
				echo -e "${error_font}恢复备份文件失败！"
			fi
			mv /usr/local/mtprotoproxy/pyaes_bak /usr/local/mtprotoproxy/pyaes
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}恢复备份文件成功。"
			else
				clear
				echo -e "${error_font}恢复备份文件失败！"
			fi
			clear
			echo -e "${error_font}MTProtoProxy升级失败！"
			echo -e "${error_font}失败原因：下载MTProtoProxy文件失败。"
			echo -e "${info_font}如需获得更详细的报错信息，请在shell窗口中往上滑动。"
			exit 1
		fi
		unzip program.zip
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}解压MTProtoProxy文件成功。"
		else
			clear
			echo -e "${error_font}解压MTProtoProxy文件失败！"
			rm -f program.zip
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}删除下载文件成功。"
			else
				clear
				echo -e "${error_font}删除下载文件失败！"
			fi
			mv /usr/local/mtprotoproxy/mtprotoproxy.py.bak /usr/local/mtprotoproxy/mtprotoproxy.py
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}恢复备份文件成功。"
			else
				clear
				echo -e "${error_font}恢复备份文件失败！"
			fi
			mv /usr/local/mtprotoproxy/pyaes_bak /usr/local/mtprotoproxy/pyaes
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}恢复备份文件成功。"
			else
				clear
				echo -e "${error_font}恢复备份文件失败！"
			fi
			clear
			echo -e "${error_font}MTProtoProxy升级失败！"
			echo -e "${error_font}失败原因：下载MTProtoProxy文件失败。"
			echo -e "${info_font}如需获得更详细的报错信息，请在shell窗口中往上滑动。"
			exit 1
		fi
		chmod +x "/usr/local/mtprotoproxy/mtprotoproxy.py"
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}设置MTProtoProxy执行权限成功。"
		else
			clear
			rm -f program.zip
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}删除下载文件成功。"
			else
				clear
				echo -e "${error_font}删除下载文件失败！"
			fi
			echo -e "${error_font}设置MTProtoProxy执行权限失败！"
			mv /usr/local/mtprotoproxy/mtprotoproxy.py.bak /usr/local/mtprotoproxy/mtprotoproxy.py
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}恢复备份文件成功。"
			else
				clear
				echo -e "${error_font}恢复备份文件失败！"
			fi
			mv /usr/local/mtprotoproxy/pyaes_bak /usr/local/mtprotoproxy/pyaes
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}恢复备份文件成功。"
			else
				clear
				echo -e "${error_font}恢复备份文件失败！"
			fi
			clear
			echo -e "${error_font}MTProtoProxy升级失败！"
			echo -e "${error_font}失败原因：下载MTProtoProxy文件失败。"
			echo -e "${info_font}如需获得更详细的报错信息，请在shell窗口中往上滑动。"
			exit 1
		fi
		rm -f /usr/local/mtprotoproxy/program.zip
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}删除下载文件成功。"
		else
			clear
			echo -e "${warning_font}删除下载文件失败！"
		fi
		rm -f /usr/local/mtprotoproxy/mtprotoproxy.py.bak
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}删除备份文件成功。"
		else
			clear
			echo -e "${warning_font}删除备份文件失败！"
		fi
		rm -rf /usr/local/mtprotoproxy/pyaes_bak
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}删除备份文件夹成功。"
		else
			clear
			echo -e "${warning_font}删除备份文件夹失败！"
		fi
		clear
		echo -e "${ok_font}MTProtoProxy更新成功。"
	fi
}

function clear_install(){
	clear
	echo -e "正在卸载中..."
	if [ "${determine_type}" -eq "1" ]; then
		service mtprotoproxy stop
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}停止MTProtoProxy成功。"
		else
			clear
			echo -e "${error_font}停止MTProtoProxy失败！"
		fi
		if [ "${daemon_name}" == "systemctl" ]; then
			systemctl disable mtprotoproxy.service
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}取消开机自启动成功。"
			else
				clear
				echo -e "${error_font}取消开机自启动失败！"
			fi
			rm -f /etc/systemd/system/mtprotoproxy.service
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}删除进程守护文件成功。"
			else
				clear
				echo -e "${error_font}删除进程守护文件失败！"
			fi
		elif [ "${daemon_name}" == "update-rc.d" ] || [ "${daemon_name}" == "chkconfig" ]; then
			if [ "${System_OS}" == "CentOS" ]; then
				chkconfig --del mtprotoproxy
			elif [[ ${System_OS} =~ ^Debian$|^Ubuntu$ ]];then
				update-rc.d -f mtprotoproxy remove
			fi
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}取消开机自启动成功。"
			else
				clear
				echo -e "${error_font}取消开机自启动失败！"
			fi
			chmod -x /etc/init.d/mtprotoproxy
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}取消进程守护文件执行权限成功。"
			else
				clear
				echo -e "${error_font}取消进程守护文件执行权限失败！"
			fi
			rm -f /etc/init.d/mtprotoproxy
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}删除进程守护文件成功。"
			else
				clear
				echo -e "${error_font}删除进程守护文件失败！"
			fi
		else
			clear
			echo -e "${error_font}您的系统中没有安装进程守护工具，已跳过本步骤！"
		fi
		close_port
		rm -rf /usr/local/mtprotoproxy
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}删除MTProtoProxy文件夹成功。"
		else
			clear
			echo -e "${error_font}删除MTProtoProxy文件夹失败！"
		fi
		echo -e "${ok_font}MTProtoProxy卸载成功。"
		echo -e "\n${error_font}卸载原因：${clear_install_reason}"
		echo -e "${info_font}如需获得更详细的报错信息，请在shell窗口中往上滑动。"
	fi
}

function os_update(){
	clear
	echo -e "正在更新系统组件中..."
	if [ "${System_OS}" == "CentOS" ]; then
		yum update -y
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${error_font}系统源更新失败！"
			exit 1
		else
			clear
			echo -e "${ok_font}系统源更新成功。"
		fi
		yum upgrade -y
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${error_font}系统组件更新失败！"
			exit 1
		else
			clear
			echo -e "${ok_font}系统组件更新成功。"
		fi
		if [ "${OS_Version}" == "5" ]; then
			yum install -y wget curl unzip lsof cron daemon iptables ca-certificates python yum-utils gcc make
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}所需组件安装失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}所需组件安装成功。"
			fi
			yum-builddep python
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}所需组件安装失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}所需组件安装成功。"
			fi
			clear
			make_python
		elif [ "${OS_Version}" == "6" ]; then
			yum install -y wget curl unzip lsof cron daemon iptables ca-certificates python yum-utils epel-release
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}所需组件安装失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}所需组件安装成功。"
			fi
			yum install -y "https://centos6.iuscommunity.org/ius-release.rpm"
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${warning_font}系统源更新失败！"
			else
				clear
				echo -e "${ok_font}系统源更新成功。"
			fi
			yum install -y python36u python36u-pip
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}所需组件安装失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}所需组件安装成功。"
			fi
			ln -f -s "/usr/bin/python3.6" "/usr/bin/python3"
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}配置Python3.6失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}配置Python3.6成功。"
			fi
			ln -f -s "/usr/bin/pip3.6" "/usr/bin/pip3"
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}配置Python3.6-pip失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}配置Python3.6-pip成功。"
			fi
		elif [ "${OS_Version}" == "7" ]; then
			yum install -y wget curl unzip lsof cron daemon firewalld ca-certificates python yum-utils epel-release
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}所需组件安装失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}所需组件安装成功。"
			fi
			systemctl start firewalld
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}启动firewalld失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}启动firewalld成功。"
			fi
			yum install -y "https://centos7.iuscommunity.org/ius-release.rpm"
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${warning_font}系统源更新失败！"
			else
				clear
				echo -e "${ok_font}系统源更新成功。"
			fi
			yum install -y python36u python36u-pip
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}所需组件安装失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}所需组件安装成功。"
			fi
			ln -f -s "/usr/bin/python3.6" "/usr/bin/python3"
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}配置Python3.6失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}配置Python3.6成功。"
			fi
			ln -f -s "/usr/bin/pip3.6" "/usr/bin/pip3"
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}配置Python3.6-pip失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}配置Python3.6-pip成功。"
			fi
		else
			clear
			echo -e "${error_font}目前暂不支持您使用的操作系统的版本号。"
			exit 1
		fi
		pip3 install --upgrade pip
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${error_font}pip3更新失败！"
			exit 1
		else
			clear
			echo -e "${ok_font}pip3更新成功。"
		fi
		pip3 install cryptography
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${warning_font}cryptography安装失败！"
		else
			clear
			echo -e "${ok_font}cryptography安装成功。"
		fi
	elif [ "${System_OS}" == "Debian" ] || [ "${System_OS}" == "Ubuntu" ]; then
		apt-get update -y
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${error_font}系统源更新失败！"
			exit 1
		else
			clear
			echo -e "${ok_font}系统源更新成功。"
		fi
		apt-get upgrade -y
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${error_font}系统组件更新失败！"
			exit 1
		else
			clear
			echo -e "${ok_font}系统组件更新成功。"
		fi
		apt-get install -y wget curl unzip lsof cron daemon iptables ca-certificates python python3 python3-pip
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${error_font}所需组件安装失败！"
			exit 1
		else
			clear
			echo -e "${ok_font}所需组件安装成功。"
		fi
		if [ "${System_OS}" == "Debian" ] && [ "${OS_Version}" == "7" ] || [ "${OS_Version}" == "8" ]; then
			apt-get install -y gcc make
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}所需组件安装失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}所需组件安装成功。"
			fi
			make_python
		fi
		if [ "${System_OS}" == "Ubuntu" ] && [ "${OS_Version}" == "14" ]; then
			apt-get install -y gcc make
			if [[ $? -ne 0 ]];then
				clear
				echo -e "${error_font}所需组件安装失败！"
				exit 1
			else
				clear
				echo -e "${ok_font}所需组件安装成功。"
			fi
			make_python
		fi
		pip3 install --upgrade pip
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${error_font}pip3更新失败！"
			exit 1
		else
			clear
			echo -e "${ok_font}pip3更新成功。"
		fi
		pip3 install cryptography
		if [[ $? -ne 0 ]];then
			clear
			echo -e "${warning_font}cryptography安装失败！"
		else
			clear
			echo -e "${ok_font}cryptography安装成功。"
		fi
	fi
	clear
	echo -e "${ok_font}相关组件 更新/安装 完毕。"
}

function make_python(){
	clear
	mkdir -p "/tmp/make_python"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}创建临时文件夹成功。"
	else
		clear
		echo -e "${error_font}创建临时文件夹失败！"
		exit 1
	fi
	cd "/tmp/make_python"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}进入临时文件夹成功。"
	else
		clear
		echo -e "${error_font}进入临时文件夹失败！"
		rm -rf "/tmp/make_python"
		exit 1
	fi
	curl "https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz" -o "/tmp/make_python/python3.6.tgz"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}下载Python3.6.4成功。"
	else
		clear
		echo -e "${error_font}下载Python3.6.4失败！"
		rm -rf "/tmp/make_python"
		exit 1
	fi
	tar -zxvf "/tmp/make_python/python3.6.tgz"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}解压包文件成功。"
	else
		clear
		echo -e "${error_font}解压包文件失败！"
		rm -rf "/tmp/make_python"
		exit 1
	fi
	rm -f "/tmp/make_python/python3.6.tgz"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}删除包文件成功。"
	else
		clear
		echo -e "${error_font}删除包文件失败！"
		rm -rf "/tmp/make_python"
		exit 1
	fi
	cd "/tmp/make_python/Python-3.6.4"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}进入Python文件夹成功。"
	else
		clear
		echo -e "${error_font}进入Python文件夹失败！"
		rm -rf "/tmp/make_python"
		exit 1
	fi
	./configure
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}配置Python成功。"
	else
		clear
		echo -e "${error_font}配置Python失败！"
		rm -rf "/tmp/make_python"
		exit 1
	fi
	make && make install
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}编译安装Python成功。"
	else
		clear
		echo -e "${error_font}编译安装Python失败！"
		make clean
		rm -rf "/tmp/make_python"
		exit 1
	fi
	ln -f -s "/usr/bin/python3.6" "/usr/bin/python3"
	if [[ $? -ne 0 ]];then
		clear
		echo -e "${error_font}配置Python3.6失败！"
		exit 1
	else
		clear
		echo -e "${ok_font}配置Python3.6成功。"
	fi
	ln -f -s "/usr/bin/pip3.6" "/usr/bin/pip3"
	if [[ $? -ne 0 ]];then
		clear
		echo -e "${error_font}配置Python3.6-pip失败！"
		exit 1
	else
		clear
		echo -e "${ok_font}配置Python3.6-pip成功。"
	fi
	rm -rf "/tmp/make_python"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}删除临时文件夹成功。"
	else
		clear
		echo -e "${error_font}删除临时文件夹失败！"
		exit 1
	fi
	cd ~
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}返回当前目录成功。"
	else
		clear
		echo -e "${error_font}返回当前目录失败！"
		exit 1
	fi
	clear
	echo -e "${ok_font}Python3.6.4安装成功。"
}

function generate_base_config(){
	clear
	echo "正在生成基础信息中..."
	Address="$(wget -qO- -t1 -T2 -4 https://api.ip.sb/ip)"
	if [ ! -n "${Address}" ]; then
		Address="$(wget -qO- -t1 -T2 https://ipinfo.io/ip)"
	fi
	if [ ! -n "${Address}" ]; then
		Address="$(wget -qO- -t1 -T2 http://members.3322.org/dyndns/getip)"
	fi
	if [ ! -n "${Address}" ]; then
		clear
		echo -e "${warning_font}获取服务器公网IP失败，请手动输入服务器公网IP地址！"
		stty erase '^H' && read -r -p "请输入您服务器的公网IP地址：" Address
	fi
	if [[ ! -n "${Address}" ]]; then
		clear
		echo -e "${error_font}获取服务器公网IP地址失败，安装无法继续。"
		exit 1
	else
		clear
		echo -e "${ok_font}您的vps_ip为：${Address}"
	fi
}

function input_port(){
	clear
	stty erase '^H' && read -p "请输入监听端口(默认监听1080端口)：" install_port
	if [ ! -n "${install_port}" ]; then
		install_port="1080"
	fi
	check_port
	echo -e "${install_port}" > "/usr/local/mtprotoproxy/install_port.txt"
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}MTProtoProxy端口配置成功。"
	else
		clear
		echo -e "${error_font}MTProtoProxy端口配置失败！"
		clear_install_reason="MTProtoProxy端口配置失败。"
		clear_install
		exit 1
	fi
}

function check_port(){
	clear
	echo -e "正在检测端口占用情况中..."
	if [[ 0 -eq $(lsof -i:"${install_port}" | wc -l) ]];then
		clear
		echo -e "${ok_font}${install_port}端口未被占用"
		open_port
	else
		clear
		echo -e "${error_font}检测到${install_port}端口被占用，以下为端口占用信息："
		lsof -i:"${install_port}"
		stty erase '^H' && read -r -r -p "是否尝试强制终止该进程？[Y/N]（默认：N，可空）" install_stilling
		case ${install_stilling} in
		[yY][eE][sS]|[yY])
			clear
			echo -e "正在尝试强制终止该进程..."
			if [ -n "$(lsof -i:"${install_port}" | awk '{print $1}' | grep -v "COMMAND" | grep "nginx")" ]; then
				service nginx stop
			fi
			if [ -n "$(lsof -i:"${install_port}" | awk '{print $1}' | grep -v "COMMAND" | grep "apache")" ]; then
				service apache stop
				service apache2 stop
			fi
			if [ -n "$(lsof -i:"${install_port}" | awk '{print $1}' | grep -v "COMMAND" | grep "caddy")" ]; then
				service caddy stop
			fi
			lsof -i:"${install_port}" | awk '{print $2}'| grep -v "PID" | xargs kill -9
			if [[ 0 -eq $(lsof -i:"${install_port}" | wc -l) ]];then
				clear
				echo -e "${ok_font}强制终止进程成功，${install_port}端口已变为未占用状态。"
				open_port
			else
				clear
				echo -e "${error_font}尝试强制终止进程失败，${install_port}端口仍被占用！"
				clear_install_reason="尝试强制终止进程失败，${install_port}端口仍被占用。"
				clear_install
				exit 1
			fi
			;;
		*)
			clear
			echo -e "${error_font}取消安装。"
			clear_install_reason="${install_port}端口被占用。"
			clear_install
			exit 1
			;;
		esac
	fi
}

function open_port(){
	clear
	echo -e "正在设置防火墙中..."
	if [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "7" ]; then
		firewall-cmd --permanent --zone=public --add-port="${install_port}"/tcp
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}开放 ${install_port}端口tcp协议 请求成功。"
		else
			clear
			echo -e "${error_font}开放 ${install_port}端口tcp协议 请求失败！"
			clear_install_reason="开放 ${install_port}端口tcp协议 请求失败。"
			clear_install
			exit 1
		fi
		firewall-cmd --complete-reload
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}重载firewalld规则成功。"
		else
			clear
			echo -e "${error_font}重载firewalld规则失败！"
			clear_install_reason="重载firewalld规则失败。"
			clear_install
			exit 1
		fi
		if [ "$(firewall-cmd --query-port="${install_port}"/tcp)" == "yes" ]; then
			clear
			echo -e "${ok_font}开放 ${install_port}端口tcp协议 成功。"
		else
			clear
			echo -e "${error_font}开放 ${install_port}端口tcp协议 失败！"
			clear_install_reason="开放 ${install_port}端口tcp协议 失败。"
			clear_install
			exit 1
		fi
	elif [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "5" ] || [ "${OS_Version}" == "6" ]; then
		service iptables save
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}保存当前iptables规则成功。"
		else
			clear
			echo -e "${warning_font}保存当前iptables规则失败！"
		fi
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${install_port}" -j ACCEPT
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}开放 ${install_port}端口tcp协议 请求成功。"
		else
			clear
			echo -e "${error_font}开放 ${install_port}端口tcp协议 请求失败！"
			clear_install_reason="开放 ${install_port}端口tcp协议 请求失败。"
			clear_install
			exit 1
		fi
		service iptables save
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}保存iptables规则成功。"
		else
			clear
			echo -e "${error_font}保存iptables规则失败！"
			clear_install_reason="保存iptables规则失败。"
			clear_install
			exit 1
		fi
		service iptables restart
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}重启iptables成功。"
		else
			clear
			echo -e "${error_font}重启iptables失败！"
			clear_install_reason="重启iptables失败。"
			clear_install
			exit 1
		fi
		if [ -n "$(iptables -L -n | grep ACCEPT | grep tcp |grep "${install_port}")" ]; then
			clear
			echo -e "${ok_font}开放 ${install_port}端口tcp协议 成功。"
		else
			clear
			echo -e "${error_font}开放 ${install_port}端口tcp协议 失败！"
			clear_install_reason="开放 ${install_port}端口tcp协议 失败。"
			clear_install
			exit 1
		fi
	elif [[ ${System_OS} =~ ^Debian$|^Ubuntu$ ]];then
		iptables-save > /etc/iptables.up.rules
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}保存当前iptables规则成功。"
		else
			clear
			echo -e "${error_font}保存当前iptables规则失败！"
			clear_install_reason="保存当前iptables规则失败。"
			clear_install
			exit 1
		fi
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}配置iptables启动规则成功。"
		else
			clear
			echo -e "${error_font}配置iptables启动规则失败！"
			clear_install_reason="配置iptables启动规则失败。"
			clear_install
			exit 1
		fi
		chmod +x /etc/network/if-pre-up.d/iptables
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}设置iptables启动文件执行权限成功。"
		else
			clear
			echo -e "${error_font}设置iptables启动文件执行权限失败！"
			clear_install_reason="设置iptables启动文件执行权限失败。"
			clear_install
			exit 1
		fi
		iptables-restore < /etc/iptables.up.rules
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}导入iptables规则成功。"
		else
			clear
			echo -e "${error_font}导入iptables规则失败！"
			clear_install_reason="导入iptables规则失败。"
			clear_install
			exit 1
		fi
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${install_port}" -j ACCEPT
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}开放 ${install_port}端口tcp协议 请求成功。"
		else
			clear
			echo -e "${error_font}开放 ${install_port}端口tcp协议 请求失败！"
			clear_install_reason="开放 ${install_port}端口tcp协议 请求失败。"
			clear_install
			exit 1
		fi
		iptables-save > /etc/iptables.up.rules
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}保存iptables规则成功。"
		else
			clear
			echo -e "${error_font}保存iptables规则失败！"
			clear_install_reason="保存iptables规则失败。"
			clear_install
			exit 1
		fi
		if [ -n "$(iptables -L -n | grep ACCEPT | grep tcp |grep "${install_port}")" ]; then
			clear
			echo -e "${ok_font}开放 ${install_port}端口tcp协议 成功。"
		else
			clear
			echo -e "${error_font}开放 ${install_port}端口tcp协议 失败！"
			clear_install_reason="开放 ${install_port}端口tcp协议 失败。"
			clear_install
			exit 1
		fi
	else
		clear
		echo -e "${error_font}目前暂不支持您使用的操作系统。"
		clear_install_reason="目前暂不支持您使用的操作系统。"
		clear_install
		exit 1
	fi
	clear
	echo -e "${ok_font}防火墙配置完毕。"
}

function close_port(){
	clear
	echo -e "正在设置防火墙中..."
	uninstall_port="$(cat "/usr/local/mtprotoproxy/config.py" | grep "PORT = " | awk -F "PORT = " '{print $2}')"
	if [ ! -n "${uninstall_port}" ]; then
		uninstall_port="$(cat "/usr/local/mtproto/install_port.txt")"
	fi
	if [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "7" ]; then
		firewall-cmd --permanent --zone=public --remove-port="${uninstall_port}"/tcp
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}关闭 ${uninstall_port}端口tcp协议 请求成功。"
		else
			clear
			echo -e "${error_font}关闭 ${uninstall_port}端口tcp协议 请求失败！"
		fi
		firewall-cmd --complete-reload
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}重载firewalld规则成功。"
		else
			clear
			echo -e "${error_font}重载firewalld规则失败！"
		fi
		if [ "$(firewall-cmd --query-port="${uninstall_port}"/tcp)" == "no" ]; then
			clear
			echo -e "${ok_font}关闭 ${uninstall_port}端口tcp协议 成功。"
		else
			clear
			echo -e "${error_font}关闭 ${uninstall_port}端口tcp协议 失败！"
		fi
	elif [ "${System_OS}" == "CentOS" ] && [ "${OS_Version}" == "5" ] || [ "${OS_Version}" == "6" ]; then
		service iptables save
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}保存当前iptables规则成功。"
		else
			clear
			echo -e "${warning_font}保存当前iptables规则失败！"
		fi
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport "${uninstall_port}" -j ACCEPT
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}关闭 ${uninstall_port}端口tcp协议 请求成功。"
		else
			clear
			echo -e "${error_font}关闭 ${uninstall_port}端口tcp协议 请求失败！"
		fi
		service iptables save
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}保存iptables规则成功。"
		else
			clear
			echo -e "${error_font}保存iptables规则失败！"
		fi
		service iptables restart
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}重启iptables成功。"
		else
			clear
			echo -e "${error_font}重启iptables失败！"
		fi
		if [ ! -n "$(iptables -L -n | grep ACCEPT | grep tcp |grep "${uninstall_port}")" ]; then
			clear
			echo -e "${ok_font}关闭 ${uninstall_port}端口tcp协议 成功。"
		else
			clear
			echo -e "${error_font}关闭 ${uninstall_port}端口tcp协议 失败！"
		fi
	elif [[ ${System_OS} =~ ^Debian$|^Ubuntu$ ]];then
		iptables-save > /etc/iptables.up.rules
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}保存当前iptables规则成功。"
		else
			clear
			echo -e "${error_font}保存当前iptables规则失败！"
			clear_install_reason="保存当前iptables规则失败。"
			clear_install
			exit 1
		fi
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}配置iptables启动规则成功。"
		else
			clear
			echo -e "${error_font}配置iptables启动规则失败！"
			clear_install_reason="配置iptables启动规则失败。"
			clear_install
			exit 1
		fi
		chmod +x /etc/network/if-pre-up.d/iptables
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}设置iptables启动文件执行权限成功。"
		else
			clear
			echo -e "${error_font}设置iptables启动文件执行权限失败！"
			clear_install_reason="设置iptables启动文件执行权限失败。"
			clear_install
			exit 1
		fi
		iptables-restore < /etc/iptables.up.rules
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}导入iptables规则成功。"
		else
			clear
			echo -e "${error_font}导入iptables规则失败！"
			clear_install_reason="导入iptables规则失败。"
			clear_install
			exit 1
		fi
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport "${uninstall_port}" -j ACCEPT
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}关闭 ${uninstall_port}端口tcp协议 请求成功。"
		else
			clear
			echo -e "${error_font}关闭 ${uninstall_port}端口tcp协议 请求失败！"
		fi
		iptables-save > /etc/iptables.up.rules
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}保存iptables规则成功。"
		else
			clear
			echo -e "${error_font}保存iptables规则失败！"
		fi
		if [ ! -n "$(iptables -L -n | grep ACCEPT | grep tcp |grep "${uninstall_port}")" ]; then
			clear
			echo -e "${ok_font}关闭 ${uninstall_port}端口tcp协议 成功。"
		else
			clear
			echo -e "${error_font}关闭 ${uninstall_port}端口tcp协议 失败！"
		fi
	else
		clear
		echo -e "${error_font}目前暂不支持您使用的操作系统。"
	fi
	clear
	echo -e "${ok_font}防火墙配置完毕。"
}

function echo_mtprotoproxy_config(){
	if [[ ${determine_type} = "1" ]]; then
		clear
		telegram_link="https://t.me/proxy?server=${Address}&port=${install_port}&secret=${install_secret}" 
		echo -e "您的连接信息如下："
		echo -e "服务器地址：${Address}"
		echo -e "端口：${install_port}"
		echo -e "Secret：${install_secret}"
		echo -e "Telegram设置指令：${green_backgroundcolor}${telegram_link}${default_fontcolor}"
	fi
	echo -e "${telegram_link}" > /usr/local/mtprotoproxy/telegram_link.txt
}

function main(){
	set_fonts_colors
	check_os
	check_install_status
	echo_install_list
}

	main
