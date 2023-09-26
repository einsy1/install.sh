#!/bin/bash

# 提示用户输入Cloudflare API密钥
read -p "请输入Cloudflare API密钥: " api_key

# 提示用户输入Cloudflare邮箱
read -p "请输入Cloudflare邮箱: " email

# 提示用户输入域名的Zone ID
read -p "请输入域名的Zone ID: " zone_id

# 提示用户输入要添加DNS解析的域名
read -p "请输入要添加DNS解析的域名: " dns_name

# 提示用户输入要添加DNS解析的IPv4地址
read -p "请输入要添加DNS解析的IPv4地址: " ipv4_address

# 提示用户是否要启用CDN代理加速
read -p "是否要启用CDN代理加速？(y/n，默认为n): " enable_proxy
if [[ "$enable_proxy" == "y" || "$enable_proxy" == "Y" ]]; then
    proxied=true
else
    proxied=false
fi

# 设置API端点
api_endpoint="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records"

# 构建DNS记录JSON
dns_record='{
    "type": "A",
    "name": "'"$dns_name"'",
    "content": "'"$ipv4_address"'",
    "ttl": 3600,
    "proxied": '"$proxied"'
}'

# 发送POST请求来创建DNS记录，使用curl
response=$(curl -s -X POST "$api_endpoint" \
     -H "X-Auth-Email: $email" \
     -H "X-Auth-Key: $api_key" \
     -H "Content-Type: application/json" \
     --data "$dns_record")

# 使用jq来解析JSON响应
result=$(echo "$response" | jq -r '.success')

if [[ "$result" == "true" ]]; then
    echo "DNS记录已成功添加"
else
    echo "无法添加DNS记录，错误信息："
    echo "$response"
fi

# 第四步：xui安装
bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)

# 第五步：ACME证书脚本
read -p "请输入要申请证书的域名: " cert_domain
read -p "请输入要接收证书相关通知的邮箱地址: " cert_email  # 新增：询问证书邮箱地址

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

# 安装 ACME 证书并传递邮箱地址
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --register-account -m "$cert_email"  # 使用用户输入的邮箱地址
~/.acme.sh/acme.sh  --issue -d $cert_domain --standalone --force
~/.acme.sh/acme.sh --installcert -d $cert_domain --key-file /root/private.key --fullchain-file /root/cert.crt
