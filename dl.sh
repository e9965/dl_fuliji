#=================================
export IFS=$(echo -ne "\n\b")
export MDEST="storage/downloads/UMMOE/"
export WinDEST="/mnt/c/Users/e9965/Downloads/"
export checkURL="https://www.ummoe.com/author/167016/fav/"
[[ ${1} == "v" ]] && export debug=1
#=================================
function main(){
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
function checkHeader(){
    [[ ! -f Header ]] && handleError "請將Header文件放置於本脚本文件夾"
}
function validateHeader(){
    while true
    do
        [[ $(curl -s -H@Header "${checkURL}" | grep -oE "inn-author-page__fans__body inn-card_variable-width__container") == "" ]] || break
        echo "請確保Cookie/Header是有效的"
        sed -i '$d' Header && echo -n "cookie: " >> Header
        read -p "请输入Cookie：" cookie 
        echo "${cookie}" >> Header
    done
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
    checkHeader 
    echo "正在初始化"
    validateHeader
    getOS
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
    exit 2
}
function moveDEST(){
    echo "正在移動下載好的文件夾"
    mv UMMOE/* ${DEST}
}
function cleanTemp(){
    rm -rf *.temp
    rm -rf *.html
}
main
exit 0