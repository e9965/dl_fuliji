echo "正在更新&安装"
curl -so pic_dl.sh https://raw.githubusercontent.com/e9965/dl_fuliji/main/pic_dl.sh
curl -so sub_dl.sh https://raw.githubusercontent.com/e9965/dl_fuliji/main/sub_dl.sh
curl -so Header https://raw.githubusercontent.com/e9965/dl_fuliji/main/Header
curl -so dl.sh https://raw.githubusercontent.com/e9965/dl_fuliji/main/dl.sh
chmod +rwx *.sh && ./dl.sh
