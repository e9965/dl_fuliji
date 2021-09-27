#=================================
export IFS=$(echo -ne "\n\b")
export MDEST="storage/downloads/UMMOE/"
export WinDEST="/mnt/c/Users/e9965/Downloads/"
export checkURL="https://www.ummoe.com/wp-admin/admin-ajax.php?action=dd5b5a9bbbcd36cb72b9ed9d8c144f00"
export mainFlag=${1}
#=================================
function createFile(){
    case ${1} in
    Header)
        cat > Header.template <<\EOF
accept: */*
accept-language: zh-CN,zh;q=0.9
dnt: 1
origin: https://www.ummoe.com
referer: https://www.ummoe.com
sec-ch-ua: " Not;A Brand";v="99", "Google Chrome";v="91", "Chromium";v="91"
sec-ch-ua-mobile: ?0
sec-fetch-dest: empty
sec-fetch-mode: cors
sec-fetch-site: same-origin
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36
cookie: age_gate=18; cookie_notice_accepted=true; 
EOF
        ;;
    sub)
        cat > sub_dl.sh <<\EOF
#==============================
export IFS=$(echo -ne "\n\b")
export url=$1
#==============================
function ummoe(){
    echo "正在识别ummoe图源"
    export code=$(echo ${url} | grep -oE "[[:digit:]]+")
    curl -L -H@Header -so ${code}.html "${url}"
    grep -oE "<div class=\"inn-singular__post__body__content inn-content-reseter\">.*</div>" ${code}.html | sed "s/<div id=\"inn-singular__post__toolbar\"/\ndiv id=\"inn-singular__post__toolbar\"/g" | grep -v "inn-singular__post__toolbar" | grep -oE "https://[^\"]+" | grep -iE "*jpg|*png|*jpeg" | cut -d"=" -f2 > ${code}.temp
    export title=$(grep -oE "<title>.*</title>" ${code}.html | cut -d">" -f2 | cut -d"&" -f1 | tr " " "_")
}
#==============================
function tuaoo(){
#https://www.tuaoo.cc/
    echo "正在识别凸凹吧图源"
    export code=$(echo ${url} | grep -oE "[[:digit:]]+")
    touch ${code}.temp
    curl -H@Header -so ${code}.html "${url}"
    pages=$(grep -oE "<ul id=\"dm-fy\">.*<" ${code}.html| grep -oE "page=[[:digit:]]+" | sort -V |  tail -1 | grep -oE "[[:digit:]]+")
    export title=$(grep -E "<h1 class=\"title\">" ${code}.html | sed -E "s/<h1 class=\"title\">|<\/h1>//g" | tr " " "_")
    for ((i=1;i<${pages};i++))
    do
        curl -H@Header -s "https://www.tuaoo.cc/post/${code}.html?page=${i}" | grep -oE "img title=[^>]+" | cut -d"\"" -f4 >> ${code}.temp
    done
}
#==============================
function faw(){
#https://www.24faw.com/c49.aspx
    echo "正在识别24faw图源"
    url=${url/\/mn/\/m}
    export code=$(echo ${url} | sed -E "s@https://www.24faw.com/|.aspx|https://www.24faw.com/m@@g")
    touch ${code}.temp
    curl -H@Header -so ${code}.html "${url}"
    pages=$(grep -E "<ul><li class=\"p_current\">" ${code}.html | grep -oE ">[[:digit:]]+<" | tail -1 | grep -oE "[[:digit:]]+")
    export title=$(grep -E "<h1 class=\"title2\">" ${code}.html | sed -E "s/<h1 class=\"title2\">|<\/h1>//g" | tr " " "_")
    for ((i=1;i<${pages};i++))
    do
        curl -H@Header -s "${url%.*}p${i}.aspx" | grep -oE "<div style=\"text-align: center;\">.*</div>" | grep -oE "src=.[^\"]+" | cut -d"\"" -f2 | sed "s@^@https://www.24faw.com/@g"  >> ${code}.temp
    done
}
#==============================
case $(echo ${url} | grep -oE "www\.[[:alnum:]]+\.[^/]+" | cut -d"." -f2) in
    ummoe)
        ummoe
        ;;
    24faw)
        faw
        ;;
    tuaoo)
        tuaoo
        ;;
    *)
        exit 0
        ;;
esac
#==============================
echo "準備下載 ${title} 编号：【${code}】"
mkdir -p UMMOE/${title}
cat -b ${code}.temp | xargs -P4 -n2 ./pic_dl.sh "${title}"
wait
echo "下載 ${title} 完成"
#==============================
EOF
        ;;
    pic)
        cat > pic_dl.sh <<\EOF
dir=${1}
link=${3}
name=${2}.$(echo ${link} | sed "s@_gzip.aspx@@g" | sed -E "s/.+\.//g")
curl "${link}" -so UMMOE/${dir}/${name} -H@Header 
EOF
        ;;
    *)
        handleError "程序逻辑错误，请回报"
        ;;
    esac
}
function checkFile(){
    [[ ! -f Header.template ]] && createFile Header && chmod +rwx Header.template
    [[ ! -f sub_dl.sh ]] && createFile sub && chmod +rwx sub_dl.sh
    [[ ! -f pic_dl.sh ]] && createFile pic && chmod +rwx pic_dl.sh
}
function main(){
    checkFile
    clear
    echo "================================="
    echo " 福  利  姬  套  图  下  載  機  器  "
    echo "================================="
    initial
    echo "================================="
    readURL
    echo "================================="
    mainDL
    echo "================================="
    moveDEST
    echo "================================="
    [[ ! ${debug} == 1 ]] && cleanTemp
    echo "下載完成"
    echo "================================="
}
function validateHeader(){
    cat Header.template > Header
    NONCE=$(curl -s -H@Header "https://www.ummoe.com/wp-admin/admin-ajax.php?action=dd5b5a9bbbcd36cb72b9ed9d8c144f00" | grep -oE "nonce[^,]+" | cut -d"\"" -f3)
    curl -H@Header -F email="${account}" -F pwd="${passwd}" -F type=login "https://www.ummoe.com/wp-admin/admin-ajax.php?_nonce=${NONCE}&action=88ad88392aa6f9ad220e03e92af22150&type=login" -D respond.cookie > /dev/null 2>&1
    truncate -s -1 Header && echo $(grep -E "path=/;"  respond.cookie | sed -E "s@expires.+|set-cookie:@@g"| xargs) >> Header
    [[ ! $(curl -s -H@Header "${checkURL}" | grep -oE "isLoggedIn\":false") == "" ]] && handleError "請確保賬戶密碼是有效的"
    sed -i "s@referer: https://www.ummoe.com@referer: https://www.tuaoo.cc/@g" Header
}
function readURL(){
    echo "提示：直接換行來開始下載"
    while true
    do
        read -p "請輸入網頁地址：" SRCURL 
        if [[ ${SRCURL} == "" ]]
        then
            break
        else
            echo "${SRCURL}" >> url.temp
        fi
    done
    uniq url.temp >> main.temp
    [[ $(cat main.temp) == "" ]] && handleError "請停止你的無意義行爲"
}
function mainDL(){
    cat url.temp | xargs -P4 -n1 bash sub_dl.sh
}
function initial(){
    >& url.temp
    >& main.temp 
    echo "正在初始化"
    getPasswd
    validateHeader
    getOS
}
function getPasswd(){
    if [[ ! -f .passwd ]]
    then
        read -p "請輸入UMMOE的賬戶郵箱：" account
        read -p "請輸入UMMOE的密碼：" passwd
        echo ${account} > .passwd
        echo ${passwd} >> .passwd
    fi
    export account=$(cat .passwd|head -1)
    export passwd=$(cat .passwd|tail -1)
}
function getOS(){
    export Device=0
    if [[ -f .config ]]
    then
        Device=$(cat .config)
    else
        echo "【0:Termux (default) | 1:Windows | 2:Linux】"
        read -p "請輸入你正在使用的設備：" Device 
        echo ${Device} > .config
    fi
    case ${Device} in
    1)
        export DEST=${WinDEST}
        ;;
    2)
        export DEST=.
        ;;
    *)
        export DEST=${MDEST}
        ;;
    esac
    [[ ! -d ${DEST} ]] && handleError "請檢查儲存目錄"
}
function handleError(){
    echo $1
    echo "Please Check the Error"
    [[ ! ${debug} == 1 ]] && cleanTemp
    exit 2
}
function moveDEST(){
    echo "正在移動下載好的文件夾"
    mv UMMOE/* ${DEST}
}
function cleanTemp(){
    rm -rf *.temp
    rm -rf *.html
    rm -rf Header*
    rm -rf respond.cookie
    rm -rf *_dl.sh
}
function readFlag(){
    [[ ${1} == "-v" ]] && export debug=1
    [[ ${1} == "-r" ]] && cleanTemp && clear && exit 0
}
readFlag ${mainFlag}
main
exit 0
