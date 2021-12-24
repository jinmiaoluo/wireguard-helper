#!/bin/bash
# 返回码 101 表示当前脚本的权限不足
# 返回码 102 表示修改当前工作目录失败
# 返回码 103 表示当前脚本参数不正确, 需要传递用户的名字拼音作为第一个参数
# 返回码 104 表示文件不存在
# 返回码 105 表示文件夹不存在

# 检查当前是否为 root 权限用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限执行当前脚本"
  exit 101
fi

# 修改当前工作目录
[[ -d /etc/wireguard ]] && cd /etc/wireguard || exit 102

# 检查参数是否存在, 不存在直接退出
[[ ! $# -eq 1 ]] && exit 103

# 待删除的人员名字(拼音)
NAME=$1

# 检查参数是否存在, 不存在直接退出
[[ ! $# -eq 1 ]] && exit 1

# 检查是否是 Linux 环境, 不是直接退出
# 因为 MacOS 的 sed 不兼容
if [[ ! $(uname) == "Linux" ]]; then
        echo '非 Linux 环境, 暂时不兼容, 操作取消, 退出中'
        exit 1
fi

if [[ ! -d "${NAME}" ]]; then
  echo "该用户对应的配置不存在"
  exit 105
fi

# 更新 wg0.conf 脚本
awk "/$NAME/ {print NR-1 \",\" NR+3 \"d\"}" server.conf | sed -i -f - server.conf

# 删除用户文件夹
rm -rf "$NAME"

# 重启服务端进程
systemctl restart wg-quick@server
