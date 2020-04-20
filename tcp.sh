start_menu
function install_trojan(){
    bash <(curl -O https://raw.githubusercontent.com/atrandys/trojan/master/trojan_mult.sh && chmod +x trojan_mult.sh && ./trojan_mult.sh)
}

start_menu
function bbr_boost_sh(){
    bash <(curl -L -s -k "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh")
}

start_menu(){
    clear
    green " ===================================="
    green "  Jeffern Trojan 一键安装自动脚本      "
    green " 系统：centos7+/debian9+/ubuntu16.04+"
    green " Twitter:@jeffern12               "
    green " ===================================="
    echo
    red " ===================================="
    yellow " 1. 走起 开始安装Trojan"
    red " ===================================="
    yellow " 2. 来加个速度吧 一键安装BBR PLUS"
    red " ===================================="
    yellow " 0. 不玩了，拜拜！"
    red " ===================================="
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    install_trojan
    ;;
    2)
    bbr_boost_sh 
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu
