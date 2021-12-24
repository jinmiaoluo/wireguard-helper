#!/bin/bash
# 返回码 101 表示当前脚本的权限不足
# 返回码 102 表示修改当前工作目录失败
# 返回码 103 表示当前脚本参数不正确, 需要传递用户的名字拼音作为第一个参数
# 返回码 104 表示文件不存在

# 检查当前是否为 root 权限用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限执行当前脚本"
  exit 101
fi

# 修改当前工作目录
[[ -d /etc/wireguard ]] && cd /etc/wireguard || exit 102

# 检查参数是否存在, 不存在直接退出
[[ ! $# -eq 1 ]] && exit 103

# 待添加的人员名字(拼音)
NAME=$1

read -r -p "你输入的用户名是 $NAME, 正确请按 Enter 否则请按 ctrl-c: " _tmp

# 生成客户端私钥
PRIVATE=$(wg genkey)

# 生成客户端公钥
PUBLICKEY=$(echo -n "$PRIVATE" | wg pubkey)

# 生成客户端预分享密钥
CLIENT_PRESHAREDKEY=$(wg genpsk)

# 生成随机 IP
RANDOMNUMBER1=$(expr "$(tr -cd '[:digit:]' < /dev/urandom | fold -w64 | head -n1 | cut -c -3 | tr -d '\n')" % 254 + 1)
RANDOMNUMBER2=$(expr "$(tr -cd '[:digit:]' < /dev/urandom | fold -w64 | head -n1 | cut -c -3 | tr -d '\n')" % 254 + 1)
CLIENT_IPADDRESS=$(echo -n 10.67."${RANDOMNUMBER1}"."${RANDOMNUMBER2}")

# 创建客户端文件夹
[[ ! -d $NAME ]] && mkdir "$NAME"

# 生成客户端配置文件
[[ -f client-template ]] && cp client-template "$NAME"/"$NAME".conf || exit 104
sed -i -e s#CLIENT_PRIVATE#"${PRIVATE}"#g \
       -e s#CLIENT_IPADDRESS#"${CLIENT_IPADDRESS}"#g \
       -e s#CLIENT_PRESHAREDKEY#"${CLIENT_PRESHAREDKEY}"#g \
       "$NAME"/"$NAME".conf

# 生成服务端配置文件
[[ -f server-template ]] && \
  sed -e s#PUBLICKEY#"${PUBLICKEY}"#g \
      -e s#COMMENT#"${NAME}"#g \
      -e s#CLIENT_IPADDRESS#"${CLIENT_IPADDRESS}"#g \
      -e s#CLIENT_PRESHAREDKEY#${CLIENT_PRESHAREDKEY}#g \
      server-template >> server.conf || exit 104

# 生成二维码
qrencode -o ./"$NAME"/"$NAME".png -r ./"$NAME"/"$NAME".conf &>/dev/null

# 生成 zip 压缩包
zip ./"$NAME"/"$NAME".zip ./"$NAME"/"$NAME".conf ./"$NAME"/"$NAME".png &>/dev/null

qrencode -t ansiutf8 -r ./"$NAME"/"$NAME".conf
echo "配置添加完成, 见 $NAME 文件夹或直接扫描上面的二维码"

# 重启服务端进程
systemctl restart wg-quick@server
