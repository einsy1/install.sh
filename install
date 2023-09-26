#!/bin/bash

# 函数用于询问是否开启代理，返回true或false
ask_for_proxy() {
  read -p "是否开启代理？(true/false): " is_proxied
  if [ "$is_proxied" == "true" ]; then
    echo "代理已开启"
  else
    echo "代理未开启"
  fi
}

# 第一个命令：CF添加DNS解析
read -p "请输入要设置DNS解析的域名: " domain_name
read -p "请输入IPv4地址: " ipv4_address
ask_for_proxy

curl --location 'https://api.cloudflare.com/client/v4/zones/3bcc5a0bda6d9a52b874364f2c44f499/dns_records' \
--header 'Content-Type: application/json' \
--header 'X-Auth-Email: q237534447@gmail.com' \
--header 'X-Auth-Key: 402395e4a33a4a2ab28b65f7633f545a15b59' \
--data '{
    "content": "'$ipv4_address'",
    "name": "'$domain_name'",
    "proxied": '$is_proxied',
    "type": "A",
    "comment": "Domain verification record",
    "ttl": 3600
}'

# 第二个命令：xui安装
bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)

# 第三个命令：ACME证书脚本
read -p "请输入要申请证书的域名: " cert_domain

# 检查是否安装socat，如果未安装，则自动安装
if ! command -v socat &> /dev/null; then
  echo "socat 未安装，正在自动安装..."
  sudo apt-get update
  sudo apt-get install -y socat
fi

# 安装ACME证书
curl https://get.acme.sh | sh

~/.acme.sh/acme.sh --register-account -m bb@ny2.co

~/.acme.sh/acme.sh  --issue -d $cert_domain --standalone --force
~/.acme.sh/acme.sh --installcert -d $cert_domain --key-file /root/private.key --fullchain-file /root/cert.crt
