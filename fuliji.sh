export baseURL_fuliji="https://www.112w.cc/"
function readFuliji(){
    arrayF=($(cat Msg.tmp | grep -oE "text[^]]+" | grep -E "url|http" | grep -oE 'http[^"]+'))
#Check the Which URL is valid
    for i in ${arrayF[@]}
    do
        [[ ${i} =~ ${baseURL_fuliji} ]] && echo "We recieve the [${i}] URL" && echo ${i} >> Msg_File_Fuliji.tmp
    done
}

function createFuliji(){
    [[ ! -f Msg_File_Fuliji.tmp ]] && touch Msg_File_Fuliji.tmp
    >& Msg_File_Fuliji.tmp
    >& downList.fuliji.html.tmp
}

function checkUniq_Fuliji(){
    cp Msg_File_Fuliji.tmp Msg_File_Fuliji_uniq.tmp
    >& Msg_File_Fuliji.tmp
    sort -V Msg_File_Fuliji_uniq.tmp | uniq | sed '/^$/d' >> Msg_File_Fuliji.tmp
    rm -rf Msg_File_Fuliji_uniq.tmp
}

function downFuliji(){
    checkUniq_Fuliji
    for i in $(cat Msg_File_Fuliji.tmp)
    do
        >& downList.fuliji.html.tmp
        #Clear The Previous Pic Url
        fuliji_Code=$(echo ${i}|sed -E "s@${baseURL_fuliji}m?|(p[[:digit:]]+)?\.aspx@@g")
        storePicURL_Fuliji ${fuliji_Code} 1
        pageNum=$(grep '<table align="center">' fuliji.html.tmp | grep -oE "<a[^<]+" | grep -oE ">[[:digit:]]" | cut -d'>' -f2 | tail -1)
        title_Fuliji=$(grep -oE '<h1[^<]+' fuliji.html.tmp| sed -E "s@ |<h1>@@g")
        backRespond "start to download File [${title_Fuliji}.pdf]"
        for ((j=2;${j}<${pageNum};j++))
        do
            storePicURL_Fuliji ${fuliji_Code} ${j}
        done
        cat downList.fuliji.html.tmp | xargs -P 5 -I X wget ${baseURL_fuliji}X -P downDir/Fuliji --header='referer: https://www.112w.cc/mn86866c49p5.aspx'
        #cat downList.fuliji.html.tmp | xargs -P 10 -I X echo "${baseURL_fuliji}X" -P downDir/Fuliji
        wait
        convert $(find downDir/Fuliji | grep "downDir/Fuliji/" | grep -v '\.pdf') downDir/Fuliji/${title_Fuliji}.pdf
        remove_Pic_Raw
        backRespond "File [${title_Fuliji}.pdf] is downloaded"
        echo "File [${title_Fuliji}.pdf] is downloaded"
    done
}

function storePicURL_Fuliji(){
    curl "${baseURL_fuliji}m${1}p${2}.aspx" > fuliji.html.tmp
    grep '<div style="text-align: center;">' fuliji.html.tmp | grep -oE '<img[^.]+.jpg' | cut -d'"' -f2 >> downList.fuliji.html.tmp
}

function remove_Pic_Raw(){
    for k in $(ls downDir/Fuliji|grep -v '\.pdf')
    do
        rm -rf downDir/Fuliji/${k}
    done
}