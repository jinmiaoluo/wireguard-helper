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


# 生成服务器私钥
wg genkey > privatekey

# 生成服务器公钥
wg pubkey < privatekey > publickey
