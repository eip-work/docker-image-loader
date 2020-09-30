# docker-image-mover

## 生成 key 文件

```sh
ssh-keygen -t rsa
```

## 设置无密码访问

```sh
ssh-copy-id -f -i ~/.ssh/id_rsa.pub root@*<target-host>*
```
