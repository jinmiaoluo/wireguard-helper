# wireguard-helper

这是构建远程开发环境用的一套脚本。需要一台公网服务器作为入口，通过 FRP 和 WireGuard 实现开发环境内网的安全暴露。这样就可以在异地安全的访问开发环境内网中的所有基础服务（而不是简单的通过 FRP 公网暴露），比如：GitLab、Jira

我本地已经彻底停用这套脚本，改为基于 Ansible 来管理 WireGuard 和 FRP 配置，参考了 Arch Linux Team 的解决方案，见：[archlinux infrastructure](https://gitlab.archlinux.org/archlinux/infrastructure/-/blob/5be67df41492cf5272cc544997548856b0e3cb08/roles/wireguard/tasks/main.yml)

因此我将不更新这个仓库内的脚本并将归档这个仓库。
