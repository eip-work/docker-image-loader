#!/bin/bash

folder=${1%.*}

if [ x"${folder}" = x ]; then
  echo -e "\033[31m 请指定 *-images.txt 文件 \033[0m"
  exit
fi

echo ""
echo "创建临时文件夹  ${folder}"
echo ""
rm -rf ${folder} || true
mkdir ${folder}

while read line
do
  let count++
  line=$(echo $line)
  if [ x${line} = x ]; then
    echo -e "\033[33m第 ${count} 行为空\033[0m"
    echo
    continue
  fi
  echo ">>>>> 下载第 ${count} 个镜像 ${line} >>>>>"
  docker pull $line
  echo -e "\033[32m<<<<< 保存第 ${count} 个镜像到 ${folder}/${line//\//_}.tar \033[0m"
  docker save $line > ${folder}/${line//\//_}.tar
  echo ""
done < ${1}

echo "----- 创建压缩文件 ${folder}.tar.gz -----"
cp ${1} ${folder}/images.txt
tar -zcvf ${folder}.tar.gz ${folder}/*.tar ${folder}/images.txt

echo -e "\033[32m----- 已压缩到文件 ${folder}.tar.gz ----- \033[0m"
echo -e "文件大小为 \c"
ls -hl ${folder}.tar.gz | awk '{print $5}'

echo ""
echo "清除临时文件夹 ${folder}"
rm -rf ${folder} 

echo ""
echo "请执行以下指令，将镜像分发到 ./target-hosts.txt 文件中定义的目标主机上。"
echo -e "\033[36m./dispatch.sh ${folder}.tar.gz target-hosts.txt \033[0m"
echo ""
