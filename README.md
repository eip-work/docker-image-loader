# docker-image-mover

我们时常遇到需要在内网环境中需要下载大量 docker 镜像的情况，例如安装 Kubernetes，安装 ceph 集群等。此时非常大的一个挑战是，如何将公网环境下可以轻松获取的 docker image 转移到内网环境的机器上。 

docker-image-mover 项目假设您有一台机器 A 能够访问公网，有另外一台机器 B 能够访问内网，且您有办法从机器 A 传输文件到机器 B 上（或者机器 A、机器 B 是同一台机器）。

按照本文档的描述，docker-image-mover 能够帮助您便捷的将一系列指定的 docker 镜像加载到一系列指定的内网机器上。前提条件：
* 机器 A、机器 B 以及所有的目标机器都安装了 docker

docker-image-mover 工作过程：
1. 在机器 A 上执行 `./pull.sh abc-images.txt` 以下载 `abc-images.txt` 文件中所指定的 docker image，镜像将被保存到 `abc-images.tar.gz` 文件中；
2. 将 `./dispatch.sh` 文件和 `abc-images.tar.gz` 文件复制到机器 B；
3. 在机器 B 上执行 `./dispatch.sh abc-images.tar.gz target-hosts.txt`，将前面步骤中下载到的镜像分发到 `target-hosts.txt` 文件中所定义的所有目标机器上。

具体操作过程请参考本文后面的描述

## 准备工作

### 下载 docker-image-mover

* 在机器 A 上创建一个临时目录，并切换到该目录

  ```sh
  mkdir docker-image-mover
  cd docker-image-mover
  ```

* 下载 docker-image-mover

  ```sh
  wget https://addons.kuboard.cn/downloads/docker-image-mover/dispatch.sh
  wget https://addons.kuboard.cn/downloads/docker-image-mover/pull.sh
  chmod +x dispatch.sh
  chmod +x pull.sh
  ```

### 设置机器 B 可以无密码 ssh 访问所有目标机器

  > 如果您的机器 A 可以同时访问外网和内网，则 A 和 B 可以是同一台机器

  在机器 B 上执行
  
* 生成 key 文件，如果您已经有 ssh key 文件，无需再次生成

  ```sh
  ssh-keygen -t rsa
  ```

* 设置无密码访问

  ```sh
  # 将 *<target-host>* 替换为目标主机的 IP 地址
  # 针对每个目标主机都要执行一次，如此，机器 B 可以无密码 ssh 访问所有目标机器
  ssh-copy-id -f -i ~/.ssh/id_rsa.pub root@*<target-host>*
  ```

## 在机器 A 上下载镜像


* 创建 `abc-images.txt` 文件，内容如下所示：

  文件中的每一行代表一个镜像（需包含 TAG）
  ```
  quay.io/k8scsi/csi-provisioner:v1.6.0
  quay.io/k8scsi/csi-resizer:v0.5.0
  quay.io/k8scsi/csi-snapshotter:v2.1.1
  quay.io/k8scsi/csi-attacher:v2.1.1
  quay.io/cephcsi/cephcsi:v3.1.0
  quay.io/k8scsi/csi-node-driver-registrar:v1.3.0
  ```

* 执行下载任务

  ``` sh
  ./pull.sh abc-images.txt
  ```

  镜像下载任务完成之后，会在同目录下生成一个压缩文件 `abc-images.tar.gz` （文件名称与 abc-images.txt 相同，后缀不同）


## 将文件复制到机器 B

用你自己的办法，将如下两个文件复制到机器 B 的某个目录，假设路径是 `~/docker-image-mover`：
* `dispatch.sh`
* `abc-images.tar.gz` （在前一个步骤中生成的文件）

## 从机器 B 分发镜像到目标机器

在机器 B 上执行：

* 切换到 `~/docker-image-mover` 目录

  ```sh
  cd ~/docker-image-mover
  ```

* 创建 `target-hosts.txt` 文件，内容如下

  ``` {1}
  /root/.ssh/id_rsa
  192.168.32.11:22
  192.168.32.12:22
  192.168.32.13:22
  192.168.32.14:22
  192.168.32.15:22
  ```
  * 第一行为 ssh key 文件的路径，我们在前面 **设置机器 B 可以无密码 ssh 访问所有目标机器** 的步骤中，已经将该 key 对应的 .pub 文件复制到所有的目标服务器上，后续将使用该 key 文件作为认证信息，远程在目标服务器上执行指令；
    > 此处 ssh key 文件的路径必须使用绝对路径
  * 后面的每一行为一个目标机器的 IP 地址以及 ssh 端口（如果使用默认 22 端口，也需要在此处列出）。

* 执行分发任务
  ``` sh
  chmod +x dispatch.sh
  ./dispatch.sh abc-images.tar.gz target-hosts.txt
  ```

**至此，您已经成功地将制定的 docker image 分发到指定的目标机器上。**
