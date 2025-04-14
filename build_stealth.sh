#!/bin/bash
# 隐藏配置文件的编译脚本
set -e

# 参数校验
if [ $# -lt 3 ]; then
  echo "Usage: $0 <toml_path_to_hide> <target_os> <target_arch>"
  echo "Example: $0 ./conf/frpc.toml linux amd64"  # darwin/windows/linux
  exit 1
fi

# 获取脚本所在绝对路径
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOML_PATH=$1
TARGET_OS=$2
TARGET_ARCH=$3
VERSION=$(date +%Y%m%d_%H%M)
RELEASE_DIR="./release"
EMBED_DIR="./pkg/config/embedder"

# 清理旧文件
rm -rf $EMBED_DIR/frpc.toml
mkdir -p $EMBED_DIR

# 植入配置文件
cp $TOML_PATH $EMBED_DIR/frpc.toml
echo "[!] Embedded config file hash: $(md5sum $EMBED_DIR/frpc.toml)"

# 交叉编译
echo "[*] Building for $TARGET_OS/$TARGET_ARCH..."
cd "$SCRIPT_DIR/" && \
  make clean && \
  GOOS=$TARGET_OS GOARCH=$TARGET_ARCH make frpc

# 移动文件到 release文件夹
mkdir -p $RELEASE_DIR

final_name="./$RELEASE_DIR/frpc_embeded_${TARGET_OS}_${TARGET_ARCH}"
mv ./bin/frpc $final_name
# 备份一下 frpc 配置文件
cp $EMBED_DIR/frpc.toml $final_name.toml.backup

if [ "$TARGET_OS" = "windows" ]; then
  mv ./$RELEASE_DIR/frpc_embeded_${TARGET_OS}_${TARGET_ARCH} ./$RELEASE_DIR/frpc_embeded_${TARGET_OS}_${TARGET_ARCH}.exe
fi

# 生成校验文件
cd ./$RELEASE_DIR
sha256sum frpc_embeded_* > checksums.txt

# 清理中间文件
rm -rf $EMBED_DIR/frpc.toml
echo "[+] Build completed. Output files in $RELEASE_DIR:"
ls -lh