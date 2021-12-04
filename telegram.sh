#Version:2021-12-4[17:21]
export oldOffset=""
function NewOffset(){
#$(NewOffset) return the offset for getUpdates method. The offset is the latest msg's update_id plus 1
    echo $(($(Tmethod getUpdates | grep -oE "update_id[^,]+" | sort -V | tail -1 | cut -d'"' -f2 | grep -oE "[[:digit:]]+") + 1))
}

function noMsg(){
#$(noMsg) return [1] when there is/are still have msg
#$(noMsg) return [0] when there is no msg
    [[ $(Tmethod getUpdates "offset=${oldOffset}" | grep -oE '"result":\[\]') == "" ]] && echo 1 || echo 0
}

function main(){
    clear
    while true
    do
        echo "Telegram Bot Service is running"
        [[ $(noMsg) == 1 ]] && work
        sleep 2s && clear
    done
}


function saveMsg(){
    saveMsg_offset=${1}
    >& Msg.tmp
    Tmethod getUpdates "offset=${saveMsg_offset}" > Msg.tmp
}

function creatMsgFile(){
    [[ ! -f Msg_File.tmp ]] && touch Msg_File.tmp
    >& Msg_File.tmp
}

function displayLog(){
    echo "We get the ${1} . The contents are followings:"
    echo "==========================================================="
        cat ${2}
    echo "==========================================================="
}

function work(){
    sleep 2s
    endFlag=0
    creatMsgFile
    echo "We get the request and start to work"
    saveMsg ${oldOffset}
    displayLog "plain json request" "Msg.tmp"
    export chatId=$(cat Msg.tmp | grep -oE "chat[^,]+" | head -1 | grep -oE "[[:digit:]]+")
    backRespond 'Bot starts to collect ur request'
    while [[ ${endFlag} == 0 ]]
    do
        readSrc
        oldOffset=$(NewOffset)
        sleep 2s
        saveMsg ${oldOffset}
        endFlag=$(checkEnd)
    done
    backRespond 'Bot gets ur request'
    if [[ $(checkEmpty "Msg_File.tmp") == 0 ]]
    then
        createFolder
        displayLog "work" "Msg_File.tmp"
        downFile
        rcloneMove
        backRespond 'Your request has just been proceeded'
        rm -rf downRespond.tmp
    fi
    cleanTmp
    oldOffset=$(NewOffset)
}

function downFile(){
    downArray=($(cat Msg_File.tmp))
    for ((i=1;${i}<=${#downArray[@]};i++))
    do
        Tmethod getFile "file_id=${downArray[${i}]}" > downRespond.tmp
        if [[ $(check_downRespond) == 0 ]]
        then
            oldPath="$(grep -oE 'file_path[^}]+' downRespond.tmp | cut -d'"' -f3)"
            mv "${oldPath}" downDir/Video/$(grep -oE "file_unique_id[^,]+" downRespond.tmp | cut -d'"' -f3).${oldPath##*.}
        fi
        echo "File [${i}]/[${#downArray[@]}] is downloaded"
    done
}

function check_downRespond(){
#$(check_downRespond) return 0 when there is no problem with the respond
#$(check_downRespond) return 1 when there is an error with the respond
    [[ $(grep -oE 'ok":true' downRespond.tmp) == "" ]] && echo 1 || echo 0
}

function backRespond(){
    Tmethod sendMessage "chat_id=${chatId}&text=${1}"
}

function createFolder(){
    mkdir -p downDir/Video
}

function rcloneMove(){
    rclone move downDir 25t-me:/ -v -P
}

function cleanTmp(){
    >& Msg.tmp
    >& Msg_File.tmp
    sleep 2s && clear
}

function checkEmpty(){
#$(checkEmpty) return 1 when the file is Empty
#$(checkEmpty) return 0 when the file is not Empty
    [[ $(cat ${1}) == "" ]] && echo 1 || echo 0
}

function checkEnd(){
#$(checkEnd) return 0 when there is no '/End' Commend
#$(checkEnd) return 1 when there is a '/End' commend
    [[ $(grep -oE "\/end" Msg.tmp) == "" ]] && echo 0 || echo 1
}

function readSrc(){
    cat Msg.tmp | sed -E "s@thumb[^}]+,@@g" | grep -oE "file_id[^,]+" | cut -d"\"" -f3 >> Msg_File.tmp
}
[[ ! -f Msg.tmp ]] && touch Msg.tmp
main