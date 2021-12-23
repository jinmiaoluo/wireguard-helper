#!/bin/bash
# 返回码 101 表示当前脚本的权限不足
# 返回码 102 表示修改当前工作目录失败

# 检查当前是否为 root 权限用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限执行当前脚本"
  exit 101
fi

# 修改当前工作目录
[[ -d /etc/wireguard ]] && cd /etc/wireguard || exit 102

# 配置 umask 避免服务端公钥和私钥文件权限过大
umask 077

# 生成服务器私钥
wg genkey > privatekey

# 生成服务器公钥
wg pubkey < privatekey > publickey

# 开启内核转发
[[ ! -f /etc/sysctl.d/ip_forward.conf ]] && echo -n "net.ipv4.ip_forward=1" > /etc/sysctl.d/ip_forward.conf

# 启用内核配置
sysctl -p /etc/sysctl.d/ip_forward.conf &>/dev/null

# 指定一些定制化的值
read -r -p "请输入需要转发流量的局域网所连接的接口的名字, 比如你要允许客户端访问 192.168.1.0/24, 则填分配了该网段 IP 的网卡名字 (默认: eth0): " INTERFACE
read -r -p "指定 WireGuard 服务器监听的端口, 这个端口将通过 FRP 跟服务器上的 20206 端口映射(默认: 20205): " CLIENT_PORT
read -r -p "指定 FRP 将暴露 WireGuard 服务到的服务器地址, 这里输入对应服务器的 IP 或者域名(默认: 120.97.112.7): " SERVER_PUBLIC_ADDRESS
read -r -p "指定 FRP 将暴露 WireGuard 服务到的服务器端口, 这里输入对应服务器的端口(默认: 20206): " SERVER_PUBLIC_PORT
read -r -p "指定需要转发流量的局域网的网络段地址(默认: 192.168.1.0/24): " LAN_NET
INTERFACE=${INTERFACE:=eth0}
CLIENT_PORT=${CLIENT_PORT:=20205}
SERVER_PUBLIC_ADDRESS=${SERVER_PUBLIC_ADDRESS:=120.97.112.7}
SERVER_PUBLIC_PORT=${SERVER_PUBLIC_PORT:=20206}
LAN_NET=${LAN_NET:=192.168.1.0/24}

# 将公钥和私钥读到变量内
PRIVATEKEY=$(cat privatekey)
PUBLICKEY=$(cat publickey)

# 初始化服务器配置
sed -e s#PRIVATEKEY#"${PRIVATEKEY}"#g \
    -e s#INTERFACE#"${INTERFACE}"#g \
    -e s#CLIENT_PORT#"${CLIENT_PORT}"#g \
    server.conf.template > server.conf

# 渲染客户端模板
sed -i -e s#PUBLICKEY#"${PUBLICKEY}"#g \
       -e s#SERVER_PUBLIC_ADDRESS#"${SERVER_PUBLIC_ADDRESS}"#g \
       -e s#SERVER_PUBLIC_PORT#"${SERVER_PUBLIC_PORT}"#g \
       -e s#LAN_NET#"${LAN_NET}"#g \
       client-template
