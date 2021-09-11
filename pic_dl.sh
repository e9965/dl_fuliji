dir=${1}
link=${3}
name=${2}.$(echo ${link} | sed "s@_gzip.aspx@@g" | sed -E "s/.+\.//g")
curl "${link}" -so UMMOE/${dir}/${name} -H@Header 