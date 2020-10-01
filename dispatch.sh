#!/bin/bash

if [ x${1} = x ]; then
  echo -e "\033[31m 请在第一个命令行参数指定 *-images.txt 文件 \033[0m"
  exit
fi

if [ ! -f "${1}" ]; then
  echo -e "\033[31m 文件 ${1} 不存在 \033[0m"
  exit
fi

if [ x${2} = x ]; then
  echo -e "\033[31m 请在第二个命令行参数指定 target-hosts.txt 文件 \033[0m"
  exit
fi

if [ ! -f "${2}" ]; then
  echo -e "\033[31m 文件 ${2} 不存在 \033[0m"
  exit
fi

read line < ${2}

prvKey=$(echo ${line})

if [ ! -f "${prvKey}" ]; then
  echo -e "\033[31m 文件 '${prvKey}' 不存在，请在文件 ${2} 的第一行指定 ssh privateKey 的路径 \033[0m"
  exit
fi

while read line
do
  let count++
  if [ ${count} -gt 1 ]; then

    line=$(echo $line)

    if [ x${line} = x ]; then
      continue
    fi

    user=$(echo ${line%@*})
    ipport=$(echo ${line#*@})
    ip=$(echo ${ipport%:*})
    port=$(echo ${ipport#*:})

    if [ x${user} = x${line} -o x${ip} = x${ipport} -o x${port} = x${ipport} ]; then
      echo -e "\033[31m 文件 ${2} 的第 ${count} 行应该符合 user@192.168.2.10:22 的格式，当前该行内容为： \033[0m"
      echo ${line}
      exit
    fi

    hostIndex=`expr ${count} - 1`
    echo -e "\033[36m>>>>> 开始分发镜像到第 ${hostIndex} 个目标主机 ${ip} >>>>>\033[0m"
    scp -P ${port} -i ${prvKey} ${1} ${user}@${ip}:~/

    ssh -p ${port} -i ${prvKey} ${user}@${ip} "rm -rf ${1%???????} || true
echo -e \"\033[36mstep ${hostIndex}.1 解压缩\033[0m\"
tar zxvf ${1}
echo -e \"\033[36mstep ${hostIndex}.2 加载镜像\033[0m\"
while read line
do
  let c++
  line=\$(echo \${line})
  if [ x\${line} = x ]; then
    echo -e \"Step ${hostIndex}.2.\${c} \033[33m第 \${c} 行为空\033[0m\"
    continue
  fi
  echo -e \"Step ${hostIndex}.2.\${c} sudo docker load < ${1%???????}/\${line//\//_}.tar \\t \\c\"
  line=\$(echo \$line)
  sudo docker load < ${1%???????}/\${line//\//_}.tar
done < ${1%???????}/images.txt

echo -e \"\033[36m加载到目标主机 ${ip} 的镜像如下\033[0m\"
echo -e \"IMAGE ID\t    CREATED\t\tSIZE\t\t    REPOSITORY:TAG\"
while read line
do
  line=\$(echo \${line})
  if [ x\${line} = x ]; then
    continue
  fi
  tag=\$(echo \${line%:*})
  version=\$(echo \${line%:*})
  sudo docker images \${line} --format \"table {{.ID}}\t{{.CreatedSince}}\t{{.Size}}\t{{.Repository}}:{{.Tag}}\" | grep \${tag} | grep \${version}
done < ${1%???????}/images.txt

echo
echo -e \"\033[36m清理目标主机 ${ip} 上的临时文件\033[0m\"
rm -rf ${1%???????} || true
rm -rf ${1} || true
echo 
" < /dev/null

    echo -e "\033[32m<<<<< 已结束将镜像分发到第 ${hostIndex} 个目标主机 ${ip} <<<<<\033[0m"
    echo ""
  fi
done < ${2}

echo -e "\033[32m----- 已结束将镜像分发到 ${2} 文件中定义的所有主机 -----\033[0m"

echo ""
