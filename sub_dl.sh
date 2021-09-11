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
    export code=$(echo ${url} | sed -E "s@https://www.24faw.com/|.aspx@@g")
    touch ${code}.temp
    curl -H@Header -so ${code}.html "${url}"
    pages=$(grep -E "<ul><li class=\"p_current\">" ${code}.html | grep -oE ">[[:digit:]]+<" | tail -1 | grep -oE "[[:digit:]]+")
    export title=$(grep -oE "<title>.*</title>" ${code}.html | sed -E "s@</?title>@@g"| tr " " "_")
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

