#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=$(nvram get productid)
module=aria2
DIR=$(cd $(dirname $0); pwd)

# 获取固件类型
_get_type() {
	local FWTYPE=$(nvram get extendno|grep koolshare)
	if [ -d "/koolshare" ];then
		if [ -n $FWTYPE ];then
			echo "koolshare官改固件"
		else
			echo "koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			echo "梅林原版固件"
		else
			echo "华硕官方固件"
		fi
	fi
}

exit_install(){
	local state=$1
	case $state in
		1)
			echo_date "本插件适用于适用于【koolshare 梅林改/官改 hnd/axhnd/axhnd.675x】固件平台，你的固件平台不能安装！！！"
			echo_date "本插件支持机型/平台：https://github.com/koolshare/rogsoft#rogsoft"
			echo_date "退出安装！"
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 1
			;;
		0|*)
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 0
			;;
	esac
}

# 判断路由架构和平台
case $(uname -m) in
	aarch64)
		if [ "$(uname -o|grep Merlin)" -a -d "/koolshare" ];then
			echo_date 机型：$MODEL $(_get_type) 符合安装要求，开始安装插件！
		else
			exit_install 1
		fi
		;;
	armv7l)
		if [ "$MODEL" == "TUF-AX3000" -o "$MODEL" == "RT-AX82U" -o "$MODEL" == "RT-AX95Q" -o "$MODEL" == "RT-AX56_XD4" ] && [ -d "/koolshare" ];then
			echo_date 机型：$MODEL $(_get_type) 符合安装要求，开始安装插件！
		else
			exit_install 1
		fi
		;;
	*)
		exit_install 1
	;;
esac

if [ "$MODEL" == "GT-AC5300" ] || [ "$MODEL" == "GT-AX11000" ] || [ -n "$(nvram get extendno | grep koolshare)" -a "$MODEL" == "RT-AC86U" ];then
	# 官改固件，骚红皮肤
	ROG=1
fi

if [ "$MODEL" == "TUF-AX3000" ];then
	# 官改固件，橙色皮肤
	TUF=1
fi

#重建 /dev/null
rm /dev/null 
mknod /dev/null c 1 3 
chmod 666 /dev/null

# stop first
aria2_enable=`dbus get aria2_enable`
aria2_version=`dbus get aria2_version`
if [ "$aria2_enable" == "1" ] && [ -f "/koolshare/scripts/aria2_config.sh" ];then
	sh /koolshare/scripts/aria2_config.sh stop
fi

cp -rf /tmp/aria2/bin/* /koolshare/bin/
cp -rf /tmp/aria2/scripts/* /koolshare/scripts/
cp -rf /tmp/aria2/webs/* /koolshare/webs/
cp -rf /tmp/aria2/res/* /koolshare/res/
cp -rf /tmp/aria2/aria2 /koolshare
cp -rf /tmp/aria2/uninstall.sh /koolshare/scripts/uninstall_aria2.sh
if [ "$ROG" == "1" ];then
	continue
else
	if [ "$TUF" == "1" ];then
		sed -i 's/3e030d/3e2902/g;s/91071f/92650F/g;s/680516/D0982C/g;s/cf0a2c/c58813/g;s/700618/74500b/g;s/530412/92650F/g' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
	else
		sed -i '/rogcss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
	fi
fi
chmod +x /koolshare/bin/*
chmod +x /koolshare/scripts/aria2*.sh
chmod +x /koolshare/scripts/uninstall_aria2.sh
[ ! -L "/koolshare/init.d/M99Aria2.sh" ] && ln -sf /koolshare/scripts/aria2_config.sh /koolshare/init.d/M99Aria2.sh
[ ! -L "/koolshare/init.d/N99Aria2.sh" ] && ln -sf /koolshare/scripts/aria2_config.sh /koolshare/init.d/N99Aria2.sh

#some modify
if [ "$aria2_version" == "1.5" ] || [ "$aria2_version" == "1.4" ] || [ "$aria2_version" == "1.3" ];then
	dbus set aria2_custom=Y2EtY2VydGlmaWNhdGU9L2V0Yy9zc2wvY2VydHMvY2EtY2VydGlmaWNhdGVzLmNydA==
fi

# for offline install
dbus set aria2_version="$(cat $DIR/version)"
dbus set softcenter_module_aria2_version="$(cat $DIR/version)"
dbus set softcenter_module_aria2_install="1"
dbus set softcenter_module_aria2_name="aria2"
dbus set softcenter_module_aria2_title="aria2"
dbus set softcenter_module_aria2_description="linux下载利器"

# re-enable
if [ "$aria2_enable" == "1" ] && [ -f "/koolshare/scripts/aria2_config.sh" ];then
	sh /koolshare/scripts/aria2_config.sh start
fi

# finish
echo_date aria2插件安装完毕！
exit_install
