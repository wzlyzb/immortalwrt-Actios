#!/bin/bash
# DIY脚本
# https://github.com/P3TERX/Actions-OpenWrt
# 文件名: diy-part1.sh
# 功能说明: OpenWrt DIY脚本第1部分（更新feeds之前）
# 版权: (c) 2019-2024 P3TERX <https://p3terx.com>
# 基于 MIT 开源协议，详见 /LICENSE

# 添加第三方 feed 源（small-package 包含 openclash/passwall/ssr-plus 等常用插件）
echo 'src-git smpackage https://github.com/kenzok8/small-package' >> feeds.conf.default
# 添加第三方源，iStore 应用商店，编译时包名输入 luci-app-store
echo 'src-git store https://github.com/linkease/istore.git;main' >> feeds.conf.default

# ---- 补丁 1：补齐 libffi（上游已把它从 packages feed 移到 core 仓库）----
mkdir -p package/libs/libffi
curl -fsSL https://raw.githubusercontent.com/openwrt/openwrt/master/package/libs/libffi/Makefile \
  -o package/libs/libffi/Makefile
[ -s package/libs/libffi/Makefile ] || { echo "libffi Makefile 下载失败"; exit 1; }
echo "libffi 已补齐: $(wc -l < package/libs/libffi/Makefile) 行"

# ---- 补丁 2：打开高通 410 的蓝牙（BREDR/LE/QCOMSMD + RFCOMM/BNEP/HIDP）----
for KCFG in target/linux/msm89xx/config-6.* target/linux/generic/config-6.*; do
  [ -f "$KCFG" ] || continue
  echo "patch kernel config: $KCFG"
  sed -i \
    -e '/^# CONFIG_BT_BREDR is not set$/d' \
    -e '/^# CONFIG_BT_LE is not set$/d' \
    -e '/^# CONFIG_BT_QCOMSMD is not set$/d' \
    -e '/^# CONFIG_BT_RFCOMM is not set$/d' \
    -e '/^# CONFIG_BT_BNEP is not set$/d' \
    -e '/^# CONFIG_BT_HIDP is not set$/d' \
    -e '/^CONFIG_BT_BREDR=/d' \
    -e '/^CONFIG_BT_LE=/d' \
    -e '/^CONFIG_BT_QCOMSMD=/d' \
    -e '/^CONFIG_BT_RFCOMM=/d' \
    -e '/^CONFIG_BT_BNEP=/d' \
    -e '/^CONFIG_BT_HIDP=/d' "$KCFG"
  cat >> "$KCFG" <<'EOF'
CONFIG_BT_BREDR=y
CONFIG_BT_LE=y
CONFIG_BT_QCOMSMD=y
CONFIG_BT_RFCOMM=y
CONFIG_BT_BNEP=y
CONFIG_BT_HIDP=y
EOF
done

echo "=== 蓝牙内核配置核对 ==="
for KCFG in target/linux/msm89xx/config-6.* target/linux/generic/config-6.*; do
  [ -f "$KCFG" ] || continue
  echo "$KCFG:"
  grep -E '^CONFIG_BT_(BREDR|LE|QCOMSMD|RFCOMM|BNEP|HIDP)=' "$KCFG" | sort -u
done
