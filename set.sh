echo "正在更新&安装"
for i in pic_dl.sh sub_dl.sh Header.template dl.sh
do
    curl -so ${i} "https://raw.githubusercontent.com/e9965/dl_fuliji/main/${i}"
done
chmod +rwx *.sh && ./dl.sh