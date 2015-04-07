#!/bin/sh

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBITIM_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
#   RABBITIM_BUILD_PREFIX=`pwd`/../${RABBITIM_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBITIM_BUILD_SOURCE_CODE    #源码目录
#   RABBITIM_BUILD_CROSS_PREFIX     #交叉编译前缀
#   RABBITIM_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM (android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
    RABBITIM_BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

if [ -z "${RABBITIM_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_${RABBITIM_BUILD_TARGERT}_envsetup.sh"
    . `pwd`/build_${RABBITIM_BUILD_TARGERT}_envsetup.sh
fi

if [ -n "$2" ]; then
    RABBITIM_BUILD_SOURCE_CODE=$2
else
    RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_PREFIX}/../src/speexdsp
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBITIM_BUILD_SOURCE_CODE} ]; then
    if [ -n "$RABBITIM_USE_REPOSITORIES" ]; then
        echo "git clone http://git.xiph.org/speexdsp.git  ${RABBITIM_BUILD_SOURCE_CODE}"
        git clone -b 887ac10 http://git.xiph.org/speexdsp.git ${RABBITIM_BUILD_SOURCE_CODE}
    else
        echo "wget http://downloads.xiph.org/releases/speex/speexdsp-1.2rc3.tar.gz"
        mkdir -p ${RABBITIM_BUILD_SOURCE_CODE}
        cd ${RABBITIM_BUILD_SOURCE_CODE}
        wget http://downloads.xiph.org/releases/speex/speexdsp-1.2rc3.tar.gz
        tar xvf speexdsp-1.2rc3.tar.gz
        RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_SOURCE_CODE}/speexdsp-1.2rc3
    fi
fi

cd ${RABBITIM_BUILD_SOURCE_CODE}

if [ ! -f configure ]; then
    echo "sh autogen.sh"
    sh autogen.sh
fi

mkdir -p build_${RABBITIM_BUILD_TARGERT}
cd build_${RABBITIM_BUILD_TARGERT}
rm -fr *

echo ""
echo "RABBITIM_BUILD_TARGERT:${RABBITIM_BUILD_TARGERT}"
echo "RABBITIM_BUILD_SOURCE_CODE:$RABBITIM_BUILD_SOURCE_CODE"
echo "CUR_DIR:`pwd`"
echo "RABBITIM_BUILD_PREFIX:$RABBITIM_BUILD_PREFIX"
echo "RABBITIM_BUILD_HOST:$RABBITIM_BUILD_HOST"
echo "RABBITIM_BUILD_CROSS_HOST:$RABBITIM_BUILD_CROSS_HOST"
echo "RABBITIM_BUILD_CROSS_PREFIX:$RABBITIM_BUILD_CROSS_PREFIX"
echo "RABBITIM_BUILD_CROSS_SYSROOT:$RABBITIM_BUILD_CROSS_SYSROOT"
echo ""

echo "configure ..."

CONFIG_PARA="--disable-static --enable-shared"
case ${RABBITIM_BUILD_TARGERT} in
    android)
        CONFIG_PARA="CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc --disable-shared -enable-static --with-gnu-ld --host=${RABBITIM_BUILD_CROSS_HOST}"
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        ;;
    unix)
        CONFIG_PARA="${CONFIG_PARA} --enable-vbr --enable-sse"
        ;;
    windows_msvc)
        ;;
    windows_mingw)
         CONFIG_PARA="${CONFIG_PARA} CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc"
         CONFIG_PARA="${CONFIG_PARA} --enable-vbr --enable-sse --with-gnu-ld"
         CONFIG_PARA="${CONFIG_PARA}--host=${RABBITIM_BUILD_CROSS_HOST}"
        ;;
    *)
        echo "${HELP_STRING}"
        exit 2
        ;;
esac

CONFIG_PARA="${CONFIG_PARA}"
echo "../configure --prefix=$RABBITIM_BUILD_PREFIX  --disable-examples  ${CONFIG_PARA} CFLAGS=\"${CFLAGS}\" CPPFLAGS=\"${CPPFLAGS}\""
../configure --prefix=$RABBITIM_BUILD_PREFIX  --disable-examples ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}"

echo "make install"
make ${RABBITIM_MAKE_JOB_PARA} && make install

cd $CUR_DIR