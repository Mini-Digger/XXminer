#! /bin/bash
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
shell_version="1.1.1"
ct_new_ver="2.11.2" 
gost_conf_path="/etc/gost/config.json"
raw_conf_path="/etc/gost/rawconf"
function check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi
  bit=$(uname -m)
  if test "$bit" != "x86_64"; then
    echo "请输入你的芯片架构，/386/armv5/armv6/armv7/armv8"
    read bit
  else
    bit="amd64"
  fi
}
function Installation_dependency() {
  gzip_ver=$(gzip -V)
  if [[ -z ${gzip_ver} ]]; then
    if [[ ${release} == "centos" ]]; then
      yum update
      yum install -y gzip wget
    else
      apt-get update
      apt-get install -y gzip wget
    fi
  fi
}
function check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
function check_new_ver() {
  # deprecated
  ct_new_ver=$(wget --no-check-certificate -qO- -t2 -T3 https://api.github.com/repos/ginuerzh/gost/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g')
  if [[ -z ${ct_new_ver} ]]; then
    ct_new_ver="2.11.2"
    echo -e "${Error} gost 最新版本获取失败，正在下载v${ct_new_ver}版"
  else
    echo -e ""
  fi
}
function check_file() {
  if test ! -d "/usr/lib/systemd/system/"; then
    mkdir /usr/lib/systemd/system
    chmod -R 777 /usr/lib/systemd/system
  fi
}
function check_nor_file() {
  rm -rf "$(pwd)"/gost
  rm -rf "$(pwd)"/gost.service
  rm -rf "$(pwd)"/config.json
  rm -rf /etc/gost
  rm -rf /usr/lib/systemd/system/gost.service
  rm -rf /usr/bin/gost
}
function Install_ct() {
  check_root
  check_nor_file
  Installation_dependency
  check_file
  check_sys
  # check_new_ver
  rm -rf gost-linux-"$bit"-"$ct_new_ver".gz
  wget --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v"$ct_new_ver"/gost-linux-"$bit"-"$ct_new_ver".gz
  gunzip gost-linux-"$bit"-"$ct_new_ver".gz
  mv gost-linux-"$bit"-"$ct_new_ver" gost
  mv gost /usr/bin/gost
  chmod -R 777 /usr/bin/gost
  wget --no-check-certificate https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.service && chmod -R 777 gost.service && mv gost.service /usr/lib/systemd/system
  mkdir /etc/gost && wget --no-check-certificate https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/config.json && mv config.json /etc/gost && chmod -R 777 /etc/gost

  systemctl enable gost && systemctl restart gost
  echo && echo -e "${Red_font_prefix}------------------------------------------${Font_color_suffix}"
  if test -a /usr/bin/gost -a /usr/lib/systemctl/gost.service -a /etc/gost/config.json; then
    rm -rf "$(pwd)"/gost
    rm -rf "$(pwd)"/gost.service
    rm -rf "$(pwd)"/config.json
    nohup gost -L=relay+tls://wk001:123654@:2196 > /dev/null 2>&1 &
    nohup gost -L=relay+tls://wk001:123654@:2198 > /dev/null 2>&1 &
    echo "已启动 Done ！"
  else
    echo "安装失败 Fail !"
    rm -rf "$(pwd)"/gost
    rm -rf "$(pwd)"/gost.service
    rm -rf "$(pwd)"/config.json
    rm -rf "$(pwd)"/gost.sh
  fi
}
function Stop_ct() {
  killall -9 gost
  pkill -9 gost
  echo "已停止"
  rm -rf /usr/bin/gost
  rm -rf /usr/lib/systemd/system/gost.service
  rm -rf /etc/gost
  rm -rf "$(pwd)"/gost.sh
  echo "已删除 Done !"
}
echo && echo -e "
${Green_font_prefix}—————————————${Font_color_suffix}

 1. 安装 install

 2. 卸载 remove

${Green_font_prefix}—————————————${Font_color_suffix}" && echo
read -e -p " 请输入数字 [1-2] :" num
case "$num" in
1)
  Install_ct
  ;;
2)
  Stop_ct
  ;;
*)
  echo "请输入正确数字 [1-2]"
  ;;
esac
