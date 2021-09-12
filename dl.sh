#=================================
export IFS=$(echo -ne "\n\b")
export MDEST="storage/downloads/UMMOE/"
export WinDEST="/mnt/c/Users/e9965/Downloads/"
export userID="167016"
export checkURL="https://www.ummoe.com/author/${userID}/fav/"
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
function validateHeader(){
    cat Header.template > Header
    curl -s -H@Header -F email="${account}" -F pwd="${passwd}" -F type=login "https://www.ummoe.com/wp-admin/admin-ajax.php?_nonce=5e0b7d57cc&action=88ad88392aa6f9ad220e03e92af22150&type=login" -D respond.cookie > /dev/null 2>&1
    echo $(grep -E "path=/;"  respond.cookie | sed -E "s@expires.+|set-cookie:@@g"| xargs) >> Header
    [[ $(curl -s -H@Header "${checkURL}" | grep -oE "inn-author-page__fans__body inn-card_variable-width__container") == "" ]] && >& Header && handleError "請確保賬戶密碼是有效的"
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
    rm -rf Header
    rm -rf respond.cookie
}
main
exit 0