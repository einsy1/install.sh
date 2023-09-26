#!/bin/bash

# 设置 Cloudflare API 访问参数
api_key="402395e4a33a4a2ab28b65f7633f545a15b59"
api_email="q237534447@gmail.com"
api_cookie="__cflb=0H28vgHxwvgAQtjUGUFqYFDiSDreGJnV41dgaWoWt4d; __cfruid=6936c7adb3f4bbd8dbfe80a0f5f12a1f8d7a17ef-1695607587"

# 函数用于询问是否开启代理，返回true或false
ask_for_proxy() {
  read -p "是否开启代理？(true/false): " is_proxied
  if [ "$is_proxied" == "true" ]; then
    echo "代理已开启"
  else
    echo "代理未开启"
  fi
}

# 函数用于获取域名的 Zone ID
get_zone_id() {
  local domain_name="$1"
  local zone_id=""

  # 请求 Cloudflare API 获取 Zone ID
  zone_id=$(curl --location "https://api.cloudflare.com/client/v4/zones?name=$domain_name" \
    --header "Content-Type: application/json" \
    --header "X-Auth-Key: $api_key" \
    --header "X-Auth-Email: $api_email" \
    --header "Cookie: $api_cookie" | jq -r '.result[0].id')

  echo "$zone_id"
}

# 函数用于检查并自动安装 jq 工具
check_and_install_jq() {
  if ! command -v jq &> /dev/null; then
    echo "jq 工具未安装，正在自动安装..."
    if command -v apt-get &> /dev/null; then
      sudo apt-get update
      sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
      sudo yum install -y jq
    else
      echo "无法找到适用于系统的包管理器，无法自动安装 jq。请手动安装 jq 后重新运行脚本。"
      exit 1
    fi
  fi
}

# 第一步：获取域名的 Zone ID
read -p "请输入要设置DNS解析的域名: " domain_name
zone_id=$(get_zone_id "$domain_name")

if [ -z "$zone_id" ]; then
  echo "无法获取域名的 Zone ID，请确保域名已添加到 Cloudflare。"
  exit 1
fi

# 第二步：根据 Zone ID 获取该域名下的所有域名解析
dns_records=$(curl --location "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
  --header "Content-Type: application/json" \
  --header "X-Auth-Key: $api_key" \
  --header "X-Auth-Email: $api_email" \
  --header "Cookie: $api_cookie")

# 第三步：判断是否已存在域名解析，如果存在则执行更新，否则执行新增
read -p "请输入要设置的IPv4地址: " ipv4_address
ask_for_proxy

# 解析 DNS 记录数据以查找指定域名的记录
record_id=$(echo "$dns_records" | jq -r --arg name "$domain_name" '.result[] | select(.name == $name) | .id')

if [ -n "$record_id" ]; then
  # 更新域名解析
  curl --location --request PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
    --header "Content-Type: application/json" \
    --header "X-Auth-Email: $api_email" \
    --header "X-Auth-Key: $api_key" \
    --header "Cookie: $api_cookie" \
    --data '{
        "content": "'$ipv4_address'",
        "name": "'$domain_name'",
        "proxied": '$is_proxied',
        "type": "A",
        "comment": "Domain verification record",
        "ttl": 3600
    }'
else
  # 新增域名解析
  curl --location "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
    --header "Content-Type: application/json" \
    --header "X-Auth-Email: $api_email" \
    --header "X-Auth-Key: $api_key" \
    --header "Cookie: $api_cookie" \
    --data '{
        "content": "'$ipv4_address'",
        "name": "'$domain_name'",
        "proxied": '$is_proxied',
        "type": "A",
        "comment": "Domain verification record",
        "ttl": 3600
    }'
fi

# 第四步：xui安装
bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)

# 第五步：ACME证书脚本
read -p "请输入要申请证书的域名: " cert_domain

# 检查是否安装 socat，如果未安装，则自动安装
if ! command -v socat &> /dev/null; then
  echo "socat 未安装，正在自动安装..."
  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y socat
  elif command -v yum &> /dev/null; then
    sudo yum install -y socat
  else
    echo "无法找到适用于系统的包管理器，无法自动安装 socat。请手动安装 socat 后重新运行脚本。"
    exit 1
  fi
fi

# 安装 ACME 证书
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --register-account -m bb@ny2.co
~/.acme.sh/acme.sh  --issue -d $cert_domain --standalone --force
~/.acme.sh/acme.sh --installcert -d $cert_domain --key-file /root/private.key --fullchain-file /root/cert.crt
