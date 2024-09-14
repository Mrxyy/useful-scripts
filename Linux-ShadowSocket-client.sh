#!/bin/bash
# execute:sudo ./Linux-ShadowSocket-client.sh <server_address> 
# remote execute：curl -sL https://raw.githubusercontent.com/Mrxyy/useful-scripts/master/Linux-ShadowSocket-client.sh | sudo bash -s <server_address>

# 检查是否传入参数
if [ -z "$1" ]; then
  echo "请提供 Shadowsocks 服务器地址作为参数。"
  echo "用法: sudo ./setup_shadowsocks.sh <server_address>"
  exit 1
fi

# 获取传入的服务器地址
SERVER_ADDRESS=$1

# 创建 Shadowsocks 配置文件
sudo sh -c "cat > /etc/shadowsocks.json << EOF
{
    \"server\":\"$SERVER_ADDRESS\",
    \"server_port\":9800,
    \"local_address\": \"127.0.0.1\",
    \"local_port\":1080,
    \"password\":\"123789\",
    \"timeout\":300,
    \"method\":\"aes-256-cfb\",
    \"fast_open\": false
}
EOF"

# 克隆 Shadowsocks 源码
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev

# 初始化子模块
git submodule update --init --recursive

# 更新系统软件包并安装依赖
sudo apt update
sudo apt install -y build-essential autoconf libtool libssl-dev gawk debhelper dh-systemd init-system-helpers pkg-config asciidoc xmlto apg

# 生成配置脚本
./autogen.sh

# 安装更多依赖
sudo apt-get install -y libpcre3 libpcre3-dev gettext libev-dev libc-ares-dev automake libmbedtls-dev libsodium-dev

# 配置并编译源码
./configure
make
sudo make install

# 启动 Shadowsocks 客户端
cd src
nohup ss-local -c /etc/shadowsocks.json > ss-local.log 2>&1 &

# 安装 Proxychains
sudo apt-get install -y proxychains

# 修改 Proxychains 配置
sudo sed -i '$c\socks5 127.0.0.1 1080' /etc/proxychains.conf

# 1. 安装 Privoxy
sudo apt install -y privoxy

# 2. 修改 /etc/privoxy/config 文件以设置 SOCKS5 代理
echo "forward-socks5 / 127.0.0.1:1080 ." | sudo tee -a /etc/privoxy/config

# 3. 添加代理环境变量到 ~/.bashrc
echo -e 'export http_proxy="http://127.0.0.1:8118"\nexport https_proxy="http://127.0.0.1:8118"\nexport ftp_proxy="http://127.0.0.1:8118"\nexport no_proxy="localhost,127.0.0.1"' >> ~/.bashrc

# 4. 使更改生效
source ~/.bashrc

sudo systemctl start proxychains
sudo systemctl enable proxychains
sudo systemctl start privoxy
sudo systemctl enable privoxy

echo "安装和配置完成！"
