#!/bin/bash

# 获取默认的网络接口名称（忽略回环接口 lo）
INTERFACE=$(ip -6 route show | grep -m 1 default | awk '{print $5}')

# 检查是否成功获取接口名称
if [ -z "$INTERFACE" ]; then
  echo "未找到默认的网络接口，请检查网络配置！"
  exit 1
fi

echo "检测到的网络接口名称为: $INTERFACE"

# 删除所有默认的 IPv6 路由
echo "正在删除所有默认的 IPv6 路由..."
ip -6 route show default | while read -r ROUTE; do
  ip -6 route del $ROUTE
done
echo "默认的 IPv6 路由已清除。"

# 添加新的默认 IPv6 路由
echo "正在添加新的默认 IPv6 路由..."
ip -6 route add default via fe80::20c:29ff:fef4:e28e dev "$INTERFACE"

# 验证路由是否正确添加
echo "当前的 IPv6 路由表如下："
ip -6 route show

echo "新的默认 IPv6 路由已成功设置为 fe80::20c:29ff:fef4:e28e 经由接口 $INTERFACE"
