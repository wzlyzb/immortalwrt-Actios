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

# ---- 补丁 2：只加 RFCOMM（无线 CarPlay 必需），不动 BNEP/HIDP ----
KCFG=target/linux/msm89xx/config-6.12
[ -f "$KCFG" ] || KCFG=$(ls target/linux/msm89xx/config-* | head -1)
echo "patch kernel config: $KCFG"
sed -i '/^# CONFIG_BT_BREDR is not set$/d'   "$KCFG"
sed -i '/^# CONFIG_BT_LE is not set$/d'       "$KCFG"
sed -i '/^# CONFIG_BT_QCOMSMD is not set$/d'  "$KCFG"
sed -i '/^# CONFIG_BT_RFCOMM is not set$/d'   "$KCFG"
sed -i '/^CONFIG_BT_BREDR=/d;/^CONFIG_BT_LE=/d;/^CONFIG_BT_QCOMSMD=/d;/^CONFIG_BT_RFCOMM=/d' "$KCFG"
cat >> "$KCFG" <<'EOF'
CONFIG_BT_BREDR=y
CONFIG_BT_LE=y
CONFIG_BT_QCOMSMD=y
CONFIG_BT_RFCOMM=y
EOF

# generic 会覆盖 RFCOMM，只修这一个符号
for G in target/linux/generic/config-6.*; do
  [ -f "$G" ] || continue
  sed -i '/^# CONFIG_BT_RFCOMM is not set$/d;/^CONFIG_BT_RFCOMM=/d' "$G"
  echo 'CONFIG_BT_RFCOMM=y' >> "$G"
done

echo "=== 核对 ==="
grep -E '^CONFIG_BT_(BREDR|LE|QCOMSMD|RFCOMM)=' "$KCFG" | sort -u
