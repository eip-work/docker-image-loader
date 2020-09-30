#!/bin/bash

echo ${1}

if [ x"${1}" = x ]; then
  echo -e "\033[31m 请指定 *-images.txt 文件 \033[0m"
  exit
fi

if [ x"${2}" = x ]; then
  echo -e "\033[31m 请指定 target-hosts.txt 文件 \033[0m"
  exit
fi

read line < ${2}

prvKey=$(echo ${line})

echo ${prvKey} ${1%???????}

while read line
do
  let count++
  if [ ${count} -gt 1 ]; then
    line=$(echo $line)
    ip=$(echo ${line%:*})
    port=$(echo ${line#*:})
    hostIndex=`expr ${count} - 1`
    echo -e "\033[36m>>>>> 开始分发镜像到第 ${hostIndex} 个目标主机 ${ip} >>>>>\033[0m"
    scp -P ${port} -i ${prvKey} ${1} root@${ip}:/root/

    ssh -p ${port} -i ${prvKey} root@${ip} "rm -rf /root/${1%???????} || true
echo -e \"\033[36mstep ${hostIndex}.1 解压缩\033[0m\"
tar zxvf /root/${1}
echo -e \"\033[36mstep ${hostIndex}.2 加载镜像\033[0m\"
while read line
do
  let c++
  echo \"Step ${hostIndex}.2.\${c} docker load < ${1%???????}/\${line//\//_}.tar\"
  line=\$(echo \$line)
  docker load < ${1%???????}/\${line//\//_}.tar > /dev/null
done < ${1%???????}/images.txt

echo -e \"\033[36m加载到目标主机 ${ip} 的镜像如下\033[0m\"
echo -e \"IMAGE ID\t    CREATED\t\tSIZE\t\t    REPOSITORY:TAG\"
while read line
do
  tag=\$(echo \${line%:*})
  version=\$(echo \${line%:*})
  docker images \${line} --format \"table {{.ID}}\t{{.CreatedSince}}\t{{.Size}}\t{{.Repository}}:{{.Tag}}\" | grep \${tag} | grep \${version}
done < ${1%???????}/images.txt" < /dev/null

      echo -e "\033[32m<<<<< 已成功将镜像分发到第 ${hostIndex} 个目标主机 ${ip} <<<<<\033[0m"
      echo ""
  fi
done < ${2}

echo -e "\033[32m----- 已成功将镜像分发到 ${2} 文件中定义的所有主机 -----\033[0m"

echo ""
