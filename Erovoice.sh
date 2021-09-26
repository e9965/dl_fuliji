#!/bin/bash
OLD_IFS=$IFS
IFS=$(echo -ne "\n\b")
#-------------------------------------------------------------------------
#<程序基本運行函數>
INI_MKDIR(){
	if [[ ! -d $1 ]] ; then	mkdir -p $1 ; fi
}
write(){
	echo -e "${1}${2}${plain}"
}
SET_BASIC_ENV_VAR(){
	export yellow='\e[33m'
	export blue='\e[34m'
	export green='\e[92m'
	export red='\e[91m'
	export plain='\e[39m'
	export UNZIP_THREAD=5
	export TEMP_UNZIP_PATH=${SHELL_BOX_PATH}/unzip/ && INI_MKDIR ${TEMP_UNZIP_PATH}
	export INPUT_DIR=${SHELL_BOX_PATH}/drive/MyDrive/Sharer.pw
}
INSTALL_7z(){
		touch /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb http://mirrors.aliyun.com/debian/ buster main non-free contrib" > /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb http://mirrors.aliyun.com/debian-security buster/updates main" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb-src http://mirrors.aliyun.com/debian-security buster/updates main" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo apt-get update -y
		apt-get install --ignore-missing -y p7zip-full p7zip-rar -y
}
UNZIP_MULTI(){
	temp_fifo="/tmp/$$.fifo"
	mkfifo ${temp_fifo}
	exec 4<>${temp_fifo}
	rm -f ${temp_fifo}
	for ((i=0;i<${1};i++))
	do
    	echo >&4
    done
}
#-----------------------------------------------------------------------
#<程序運行-准备环境参数>
SHELL_BOX_PATH=$(readlink -f ${0})
export SHELL_BOX_PATH=${SHELL_BOX_PATH%\/*}
SET_BASIC_ENV_VAR
write $yellow "正在准备环境参数"
INSTALL_7z > /dev/null 2>&1
#-----------------------------------------------------------------------
#<程序運行-转移压缩包>
for i in $(ls ${INPUT_DIR})
do
	write $blue "正在移动【${i}】"
	mv ${INPUT_DIR}/${i} ${TEMP_UNZIP_PATH} 
	write $green "移动压缩包【${i}】完成"
done
#-----------------------------------------------------------------------
#<程序运行-解压压缩包>
if [[ $(find ${TEMP_UNZIP_PATH} -type f -name "*.rar"|wc -l) > 0 ]]
then
	UNZIP_MULTI 5 && wait
	for i in $(find ${TEMP_UNZIP_PATH} -type f -name "*.rar" | grep -vE "\.part[2-9]|[0-9].\.rar$" )
	do
		read -u4
		{
			write $red "正在解压压缩包【${i##*\/}】"
			7z x -y -r -bsp0 -bso0 -bse0 -aot -o${TEMP_UNZIP_PATH} ${i}
			rm -rf ${i}
			echo >&4
		}&
	done
	wait && exec 4>&-
	#-----------------------------------------------------------------------
	#<程序运行-简化压缩包>
	write $yellow "正在简化Erovoice压缩包结构"
	for i in $(find ${TEMP_UNZIP_PATH} -maxdepth 2 -type d | grep -E "RJ[[:digit:]]+-EroVoice.us")
	do
		{
			mv ${i}/* ${i%\/*}
			rm -rf ${i}
		}&
	done
	wait
	find ${TEMP_UNZIP_PATH} -type f -name "Information.txt" -exec rm -rf {} \;
	#-----------------------------------------------------------------------
	#<程序运行-传回文档>
	UNZIP_MULTI 5 && wait
	for i in $(find ${TEMP_UNZIP_PATH} -maxdepth 1 -type d | sed "1d")
	do
		read -u4
		{
			write $red "正在传回【${i##*\/}】"
			mv ${i} /content/drive/MyDrive/Temporary/${i##*\/}
			write $green "完成传回【${i##*\/}】"
			echo >&4
		}&
	done
	wait && exec 4>&-
	#-----------------------------------------------------------------------
	write $green "已完成传输"
else
	write $red "未找到文件"
fi
IFS=$OLD_IFS
exit 0
