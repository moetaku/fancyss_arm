#!/bin/bash

base_url="https://github.com/v2fly/v2ray-core/releases/latest"
ver=$(curl $base_url | grep tag | sed 's/.*tag\/\(v[.0-9]*\).*/\1/g' )
echo $ver

if [[ -n "$ver" ]] && [[ "$ver" =~ ^v.* ]]; then 
  echo "版本获取成功"
else
  echo "版本获取出错"
  exit
fi

cur_ver=$(cat ./latest.txt)

if [ "$ver" = "$cur_ver" ]; then
    echo "与当前版本一致，不进行更新"
    exit
fi

if [ -e './v2ray-linux-arm32-v5.zip' ]; then 
    rm -rf ./v2ray-linux-arm32-v5.zip
fi

wget --no-check-certificate --timeout=8 "$base_url"/download/v2ray-linux-arm32-v5.zip

if [ "$?" == "0" ]; then
    echo 文件下载成功
else
    echo 下载失败，可能是网络问题，请稍候尝试
    exit
fi

md5=$(wget --no-check-certificate --timeout=8 -qO - "$base_url"/download/v2ray-linux-arm32-v5.zip.dgst | grep MD5 | sed 's/MD5= \(.*\)/\1/g')
echo "获取远程文件md5: $md5"

md5sum_zip=$(md5sum ./v2ray-linux-arm32-v5.zip|awk '{print $1}')

echo "计算本地文件md5: $md5sum_zip"

if [ "$md5sum_zip"x != "$md5"x ]; then
    echo "md5校验出错"
    exit
else
    echo "md5校验通过"
fi

unzip -o ./v2ray-linux-arm32-v5.zip -d ./tmp

upx --lzma -9 ./tmp/v2ctl ./tmp/v2ray
res=$?
if [[ "$res" == "0" ]] || [[ "$res" == "2" ]]; then 
    echo "压缩成功"
else
    echo "压缩失败"
    exit
fi

if [ ! -d './$ver' ]; then 
    mkdir ./$ver
fi

echo "开始复制执行文件..."
cp -f ./tmp/v2ray ./$ver/v2ray
cp -f ./tmp/v2ctl ./$ver/v2ctl

echo "复制完毕，写入md5"
cd ./$ver
md5sum v2ctl > md5sum.txt
md5sum v2ray >> md5sum.txt
cd ..

echo "修改版本号..."
echo $ver > latest.txt

echo "清理临时文件..."
if [ -e './tmp' ]; then 
    rm -rf ./tmp
fi

if [ -e './v2ray-linux-arm32-v5.zip' ]; then 
    rm -rf ./v2ray-linux-arm32-v5.zip
fi

echo "脚本执行完毕"