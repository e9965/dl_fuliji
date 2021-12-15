#!/bin/bash
OLD_IFS=$IFS
IFS=$(echo -ne "\n\b")
#-------------------------------------------------------------------------
#<程序基本運行函數>
SET_BASIC_ENV_VAR(){
	export INPUT_DIR=/content/drive/MyDrive/Sharer.pw/
	export OUTPUT_DIR=/content/drive/MyDrive/Temporary/
	export yellow='\e[33m'
	export blue='\e[34m'
	export green='\e[92m'
	export red='\e[91m'
	export plain='\e[39m'
	export UNZIP_THREAD=5
	export TEMP_UNZIP_PATH=/content/unzip/ && INI_MKDIR ${TEMP_UNZIP_PATH}
}
INI_MKDIR(){
	if [[ ! -d $1 ]] ; then	mkdir -p $1 ; fi
}
write(){
	echo -e "${1}${2}${plain}"
}
INSTALL_7Z(){
		touch /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb http://mirrors.aliyun.com/debian/ buster main non-free contrib" > /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb http://mirrors.aliyun.com/debian-security buster/updates main" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb-src http://mirrors.aliyun.com/debian-security buster/updates main" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo echo "deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >> /etc/apt/sources.list.d/aliyun.list
		sudo apt update -y
		sudo apt install p7zip-full -y
		sudo apt install p7zip-rar -y
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

function moveZipFile(){
#<程序運行-转移压缩包>
	UNZIP_MULTI 3 && wait
	for i in $(ls ${INPUT_DIR})
	do
	read -u4
	{
		write $blue "正在移动【${i}】"
		mv ${INPUT_DIR}${i} ${TEMP_UNZIP_PATH} 
		echo "${i}" >> remove_file_list.tmp
		write $green "移动压缩包【${i}】完成"
		echo >&4
	}&
	done
	wait && exec 4>&-
}

function unzipRar(){
	UNZIP_MULTI 2 && wait
	for i in $(find ${TEMP_UNZIP_PATH} -type f -name "*.rar" | grep -vE "\.part[2-9]|[0-9].\.rar$" )
	do
		read -u4
		{
			write $red "正在解压压缩包【${i##*\/}】"
			7z x -y -r -bsp0 -bso0 -bse0 -aot -o${TEMP_UNZIP_PATH} ${i}
			echo >&4
		}&
	done
	wait && exec 4>&-
	removeRarFile
}

function removeRarFile(){
	for i in $(cat remove_file_list.tmp)
	do
		rm -f ${TEMP_UNZIP_PATH}${i}
	done
}

function simplifyFolder(){
#<程序运行-简化文件夾>
	write $yellow "正在简化Erovoice压缩包结构"
	for i in $(find ${TEMP_UNZIP_PATH} -maxdepth 2 -type d | grep -E "RJ[[:digit:]]+-EroVoice.us")
	do
		{
			eval mv ${i}/* ${i%\/*}
			rm -rf ${i}
		}&
	done
	wait
	find ${TEMP_UNZIP_PATH} -type f -name "Information.txt" -exec rm -rf {} \;
}

function main(){
	init
	moveZipFile
	if [[ $(yesFile) == 1 ]]
	then
		unzipRar
		simplifyFolder
		returnFolder
	else
		write $red "未找到文件"
	fi
	cleanTemp
}

function returnFolder(){
	write $green "開始傳輸"
	for i in $(ls ${TEMP_UNZIP_PATH})
	do
		write $yellow "開始傳輸${i}"
		mv "${TEMP_UNZIP_PATH}${i}" "${OUTPUT_DIR}"
		write ${yellow} "完成傳輸${i}"
	done
	write $green "已完成传输"
}

function cleanTemp(){
	rm -rf remove_file_list.tmp
	rm -rf ${TEMP_UNZIP_PATH}
}

function yesFile(){
#Return 1 when there is a rar file
#Return 0 when there is no rar file
	[[ $(find ${TEMP_UNZIP_PATH} -type f -name "*.rar"|wc -l) > 0 ]] && echo 1 || echo 0
}

function init(){
#<程序運行-准备环境参数>
	SET_BASIC_ENV_VAR
	write $yellow "正在安裝必要插件"
	>& remove_file_list.tmp
	INSTALL_7Z > /dev/null 2>&1
	write $yellow "插件已準備完成"
}

main
IFS=$OLD_IFS
exit 0