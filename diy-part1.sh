#!/bin/bash
# DIY脚本
# https://github.com/P3TERX/Actions-OpenWrt
# 文件名: diy-part1.sh
# 功能说明: OpenWrt DIY脚本第1部分（更新feeds之前）
# 版权: (c) 2019-2024 P3TERX <https://p3terx.com>
# 基于 MIT 开源协议，详见 /LICENSE

# 取消注释一个源
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# 添加第三方 feed 源（small-package 包含 openclash/passwall/ssr-plus 等常用插件）
echo 'src-git smpackage https://github.com/kenzok8/small-package' >> feeds.conf.default
# 添加第三方源，iStore 应用商店，编译时包名输入 luci-app-store
echo 'src-git store https://github.com/linkease/istore.git;main' >> feeds.conf.default


# OpenClash代理
# git clone --depth 1 https://github.com/vernesong/OpenClash.git OpenClash

# turboacc网络加速（需要用户在页面选择 luci-app-turboacc 后，由编译脚本自动执行，此处不再无条件运行）
# curl -sSL https://raw.githubusercontent.com/mufeng05/turboacc/main/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh

# 调试
# sed -i 's|src-git-full openstick https://github.com/lkiuyu/openstick-feeds.git|src-git-full openstick https://github.com/xuxin1955/openstick-feeds|g' feeds.conf.default


# 补齐 libffi：上游已把它从 packages feed 移到 openwrt/openwrt 的 package/libs 下
# 我们的源码锁在 2026-05 的 commit，正好卡在「feed 已删、core 还没加」的空档
mkdir -p package/libs/libffi
curl -fsSL https://raw.githubusercontent.com/openwrt/openwrt/master/package/libs/libffi/Makefile \
  -o package/libs/libffi/Makefile
[ -s package/libs/libffi/Makefile ] || { echo "libffi Makefile 下载失败"; exit 1; }
echo "libffi 已补齐: $(wc -l < package/libs/libffi/Makefile) 行"

