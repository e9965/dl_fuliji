#Version:2021-12-5[10:10]
export oldOffset=""
########################################################################################################
#Extended Function Regions
source fuliji.sh
#fuliji.sh is the shell script to download the photo from 112w.cc
########################################################################################################
function NewOffset(){
#$(NewOffset) return the offset for getUpdates method. The offset is the latest msg's update_id plus 1
    echo $(($(Tmethod getUpdates | grep -oE "update_id[^,]+" | sort -V | tail -1 | cut -d'"' -f2 | grep -oE "[[:digit:]]+") + 1))
}

function readSrc_Ex(){
    readFuliji
}

function downFile_Ex(){
    [[ ${flagArray[1]} = 1 ]] && downFuliji
}

function createFolder_Ex(){
    [[ ${flagArray[1]} == 1 ]] && mkdir -p downDir/Fuliji
}

function checkRequest(){
##When the FlagArray value = 0 > The File is Empty
##When the FlagArray value = 1 > The File is not empty
##For the overall function, it returns 0 whenever anyone of the file is not empty
    flagArray[0]=$(checkEmpty "Msg_File.tmp")
    flagArray[1]=$(checkEmpty "Msg_File_Fuliji.tmp")
    [[ `expr $(echo ${flagArray[@]} | sed 's@ @ + @g')` > 0 ]] && return 0 || return 1
}

function createMsgFile_Ex(){
    [[ ${flagArray[1]} == 1 ]] && createFuliji
}

function displayLog_Ex(){
    displayLog "fuliji_work" "Msg_File_Fuliji.tmp"
}

function noMsg(){
#$(noMsg) return [1] when there is/are still have msg
#$(noMsg) return [0] when there is no msg
    [[ $(Tmethod getUpdates "offset=${oldOffset}" | grep -oE '"result":\[\]') == "" ]] && echo 1 || echo 0
}

function main(){
    while true
    do
        echo -ne "Telegram Bot Service is running\r"
        [[ $(noMsg) == 1 ]] && work
        sleep 2s
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
    sleep 1s
    endFlag=0
    creatMsgFile
    createMsgFile_Ex
    echo "We get the request and start to work"
    saveMsg ${oldOffset}
    displayLog "plain json request" "Msg.tmp"
    export chatId=$(cat Msg.tmp | grep -oE "chat[^,]+" | head -1 | grep -oE "[[:digit:]]+")
    backRespond 'Bot gets your call ~ Send the cmd </end> to start the process.'
    while [[ ${endFlag} == 0 ]]
    do
        readSrc
        readSrc_Ex
        oldOffset=$(NewOffset)
        sleep 1s
        saveMsg ${oldOffset}
        endFlag=$(checkEnd)
    done
    backRespond 'Bot start to process your request'
    checkRequest
    if [[ ${?} == 0 ]]
    then
        createFolder
        createFolder_Ex
        displayLog "work" "Msg_File.tmp"
        displayLog_Ex
        backRespond 'Start to download those file'
        [[ ${flagArray[0]} = 1 ]] && downFile
        downFile_Ex
        backRespond 'Start to transfer the file to Google Drive'
        rcloneMove
        backRespond 'Your request has just been proceeded'
        rm -rf downRespond.tmp
    else
        backRespond 'No request was found......'
    fi
    cleanTmp
    oldOffset=$(NewOffset)
}

function downFile(){
    downArray=($(cat Msg_File.tmp))
    for ((i=0;${i}<${#downArray[@]};i++))
    do
        Tmethod getFile "file_id=${downArray[${i}]}" > downRespond.tmp
        if [[ $(check_downRespond) == 0 ]]
        then
            oldPath="$(grep -oE 'file_path[^}]+' downRespond.tmp | cut -d'"' -f3)"
                CompressedFile_Flag=0
                [[ ! $(echo ${oldPath##*.}| grep -i '7z') == "" ]] && CompressedFile_Flag=`expr ${CompressedFile_Flag} + 1`
                [[ ! $(echo ${oldPath##*.}| grep -i 'rar') == "" ]] && CompressedFile_Flag=`expr ${CompressedFile_Flag} + 1`
                [[ ! $(echo ${oldPath##*.}| grep -i 'zip') == "" ]] && CompressedFile_Flag=`expr ${CompressedFile_Flag} + 1`
                if [[ ${CompressedFile_Flag} == 0 ]]
                then
                    mv "${oldPath}" downDir/Video/$(grep -oE "file_unique_id[^,]+" downRespond.tmp | cut -d'"' -f3).${oldPath##*.}
                else
                    mv "${oldPath}" downDir/Compressed/$(grep -oE "file_unique_id[^,]+" downRespond.tmp | cut -d'"' -f3).${oldPath##*.}
                fi
        fi
        backRespond "File [`expr ${i} + 1`]/[${#downArray[@]}] is downloaded"
        echo "File [`expr ${i} + 1`]/[${#downArray[@]}] is downloaded"
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
    mkdir -p downDir/Compressed
}

function rcloneMove(){
    rclone move downDir 25t-me:/ -v -P
}

function cleanTmp(){
    rm -rf *.tmp
    >& Msg.tmp
    >& Msg_File.tmp
    sleep 2s
}

function checkEmpty(){
#$(checkEmpty) return 0 when the file is Empty
#$(checkEmpty) return 1 when the file is not Empty
    [[ $(cat ${1}) == "" ]] && echo 0 || echo 1
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