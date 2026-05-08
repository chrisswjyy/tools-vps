#!/bin/bash

# ─────────────────────────────────────────────
#   VPS Tools by Chris
#   Telegram: @chriswijayaa
# ─────────────────────────────────────────────

if [[ $EUID -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

clear_screen() {
    clear
}

loading() {
    local msg="$1"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local delay=0.08
    local i=0
    echo -ne "\n"
    while true; do
        printf "\r  ${CYAN}${chars:$i:1}${RESET}  ${WHITE}$msg${RESET}"
        i=$(( (i+1) % ${#chars} ))
        sleep $delay
    done
}

stop_loading() {
    kill $LOADING_PID 2>/dev/null
    wait $LOADING_PID 2>/dev/null
    echo -ne "\r\033[K"
}

start_loading() {
    loading "$1" &
    LOADING_PID=$!
}

press_enter() {
    echo -e "\n  ${DIM}tekan enter buat balik ke menu...${RESET}"
    read -r </dev/tty
}

typewrite() {
    local text="$1"
    local delay="${2:-0.03}"
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

animate_banner() {
    clear_screen
    echo ""
    sleep 0.08
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    sleep 0.08
    echo -e "  ${BOLD}${WHITE}  VPS Tools by Chris${RESET}"
    sleep 0.08
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    sleep 0.08
    echo -e "  ${DIM}Telegram: @chriswijayaa${RESET}"
    echo ""
}

show_menu() {
    animate_banner
    echo -e "  ${BOLD}${CYAN}Pilih yang mau kamu lakuin:${RESET}"
    echo ""
    echo -e "  ${WHITE}1.${RESET}  Benchmark VPS"
    echo -e "  ${WHITE}2.${RESET}  Lihat spesifikasi VPS"
    echo -e "  ${WHITE}3.${RESET}  Update & Upgrade sistem"
    echo -e "  ${WHITE}4.${RESET}  Run Cloudflared"
    echo -e "  ${WHITE}5.${RESET}  Install bahasa pemrograman"
    echo -e "  ${WHITE}6.${RESET}  Cek koneksi & ping"
    echo -e "  ${WHITE}7.${RESET}  Monitor resource (live)"
    echo -e "  ${WHITE}8.${RESET}  Manajemen firewall (UFW)"
    echo -e "  ${WHITE}9.${RESET}  Swap memory"
    echo -e "  ${WHITE}10.${RESET} Cek port yang lagi jalan"
    echo -e "  ${WHITE}11.${RESET} Info IP publik & geolokasi"
    echo -e "  ${WHITE}0.${RESET}  Keluar"
    echo ""
    read -r -t 0 -n 999 discard </dev/tty 2>/dev/null || true
    echo -ne "  ${BOLD}${YELLOW}Pilihan kamu: ${RESET}"
}

# ─── 1. BENCHMARK ─────────────────────────────

benchmark_speedtest() {
    echo -e "\n  ${CYAN}Ngecek speedtest-cli...${RESET}"
    if ! command -v speedtest-cli &>/dev/null; then
        echo -e "  ${YELLOW}Belum ada, lagi install...${RESET}"
        apt-get install -y speedtest-cli -qq 2>/dev/null || pip install speedtest-cli -q 2>/dev/null
    fi
    echo -e "\n  ${WHITE}Hasil Speedtest:${RESET}"
    echo -e "  ${DIM}────────────────${RESET}"
    speedtest-cli --simple 2>/dev/null || echo -e "  ${RED}Speedtest gagal jalan.${RESET}"
}

benchmark_disk() {
    echo -e "\n  ${WHITE}Disk Speed Test (3x run):${RESET}"
    echo -e "  ${DIM}──────────────────────────${RESET}"
    local total=0
    for i in 1 2 3; do
        echo -ne "  Run $i: "
        RESULT=$(dd if=/dev/zero of=/tmp/vpstools_test bs=1M count=512 conv=fdatasync 2>&1 | grep -oP '[0-9.]+ [MGK]B/s' | tail -1)
        echo -e "${WHITE}${RESULT}${RESET}"
        rm -f /tmp/vpstools_test
        sleep 1
    done

    # Deteksi tipe disk
    DISK=$(lsblk -d -o NAME,ROTA 2>/dev/null | grep -v NAME | head -1)
    ROTA=$(echo "$DISK" | awk '{print $2}')
    if [ "$ROTA" = "0" ]; then
        # Cek NVMe
        if lsblk -d -o NAME,TRAN 2>/dev/null | grep -qi nvme; then
            DISK_TYPE="${GREEN}NVMe SSD${RESET}"
        else
            DISK_TYPE="${CYAN}SSD${RESET}"
        fi
    else
        DISK_TYPE="${YELLOW}HDD${RESET}"
    fi
    echo -e "\n  Tipe storage terdeteksi: ${BOLD}${DISK_TYPE}"
}

benchmark_ram() {
    echo -e "\n  ${WHITE}RAM Info:${RESET}"
    echo -e "  ${DIM}──────────${RESET}"
    # Deteksi DDR
    RAM_TYPE=$(sudo dmidecode --type 17 2>/dev/null | grep -i "type:" | grep -v "Error" | head -1 | awk '{print $NF}')
    RAM_SPEED=$(sudo dmidecode --type 17 2>/dev/null | grep "Speed:" | grep -v "Unknown" | head -1 | awk '{print $2, $3}')
    if [ -z "$RAM_TYPE" ]; then
        RAM_TYPE="Tidak bisa dideteksi (butuh root / dmidecode)"
    fi
    echo -e "  Teknologi RAM : ${BOLD}${WHITE}${RAM_TYPE}${RESET}"
    echo -e "  Kecepatan     : ${BOLD}${WHITE}${RAM_SPEED:-N/A}${RESET}"
    echo ""
    free -h | awk '
    /Mem:/ { printf "  Total: %s  |  Terpakai: %s  |  Bebas: %s\n", $2, $3, $4 }
    /Swap:/ { printf "  Swap : %s  |  Terpakai: %s  |  Bebas: %s\n", $2, $3, $4 }
    '
}

benchmark_cpu() {
    echo -e "\n  ${WHITE}CPU Benchmark (sysbench 10 detik):${RESET}"
    echo -e "  ${DIM}───────────────────────────────────${RESET}"
    if ! command -v sysbench &>/dev/null; then
        echo -e "  ${YELLOW}Install sysbench dulu...${RESET}"
        apt-get install -y sysbench -qq 2>/dev/null
    fi
    sysbench cpu --cpu-max-prime=20000 --time=10 run 2>/dev/null | grep -E "events per second|total time|min:|max:|avg:" | while read -r line; do
        echo -e "  ${line}"
    done
}

menu_benchmark() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Benchmark VPS${RESET}"
    echo -e "  ${DIM}Ini bakal makan waktu sebentar, santai aja.${RESET}"
    echo ""

    benchmark_speedtest
    benchmark_disk
    benchmark_ram
    benchmark_cpu

    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    echo -e "  ${GREEN}Benchmark selesai!${RESET}"
    press_enter
}

# ─── 2. VIEW SPECS ────────────────────────────

menu_specs() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Spesifikasi VPS Kamu${RESET}"
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    echo ""

    # CPU
    CPU_NAME=$(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2 | xargs)
    CPU_CORES=$(nproc)
    CPU_THREADS=$(grep -c "processor" /proc/cpuinfo)
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "  ${BOLD}${WHITE}CPU${RESET}"
    echo -e "  Nama     : ${CPU_NAME}"
    echo -e "  Core     : ${CPU_CORES} cores / ${CPU_THREADS} threads"
    echo -e "  Pemakaian: ${CPU_USAGE}%"
    echo ""

    # RAM
    RAM_TOTAL=$(free -h | awk '/Mem:/{print $2}')
    RAM_USED=$(free -h | awk '/Mem:/{print $3}')
    RAM_FREE=$(free -h | awk '/Mem:/{print $4}')
    RAM_CACHE=$(free -h | awk '/Mem:/{print $6}')
    RAM_PCT=$(free | awk '/Mem:/{printf "%.1f", $3/$2*100}')
    echo -e "  ${BOLD}${WHITE}RAM${RESET}"
    echo -e "  Total    : ${RAM_TOTAL}"
    echo -e "  Terpakai : ${RAM_USED} (${RAM_PCT}%)"
    echo -e "  Bebas    : ${RAM_FREE}"
    echo -e "  Cache    : ${RAM_CACHE}"
    echo ""

    # SWAP
    SWAP_TOTAL=$(free -h | awk '/Swap:/{print $2}')
    SWAP_USED=$(free -h | awk '/Swap:/{print $3}')
    echo -e "  ${BOLD}${WHITE}Swap${RESET}"
    echo -e "  Total    : ${SWAP_TOTAL}"
    echo -e "  Terpakai : ${SWAP_USED}"
    echo ""

    # DISK
    echo -e "  ${BOLD}${WHITE}Storage${RESET}"
    df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -v tmpfs | grep -v udev | tail -n +2 | while read -r line; do
        echo -e "  ${line}"
    done
    echo ""

    # OS
    OS=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')
    HOSTNAME=$(hostname)
    echo -e "  ${BOLD}${WHITE}Sistem${RESET}"
    echo -e "  OS       : ${OS}"
    echo -e "  Kernel   : ${KERNEL}"
    echo -e "  Uptime   : ${UPTIME}"
    echo -e "  Hostname : ${HOSTNAME}"
    echo ""

    # IP
    IP_PUBLIK=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "Gagal ambil IP")
    IP_LOKAL=$(hostname -I | awk '{print $1}')
    echo -e "  ${BOLD}${WHITE}Jaringan${RESET}"
    echo -e "  IP Publik : ${IP_PUBLIK}"
    echo -e "  IP Lokal  : ${IP_LOKAL}"
    echo ""

    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    press_enter
}

# ─── 3. UPDATE & UPGRADE ──────────────────────

menu_update() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Update & Upgrade Sistem${RESET}"
    echo -e "  ${DIM}Lagi ngambil update terbaru...${RESET}"
    echo ""
    apt-get update
    echo ""
    echo -e "  ${CYAN}Sekarang upgrade...${RESET}"
    echo ""
    apt-get upgrade -y
    echo ""
    echo -e "  ${GREEN}Sistem sudah up to date!${RESET}"
    press_enter
}

# ─── 4. CLOUDFLARED ───────────────────────────

menu_cloudflared() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Run Cloudflared${RESET}"
    echo ""

    if ! command -v cloudflared &>/dev/null; then
        echo -e "  ${YELLOW}Cloudflared belum ada, lagi install...${RESET}"
        echo ""

        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
        elif [[ "$ARCH" == "aarch64" ]]; then
            CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
        else
            CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
        fi

        curl -fsSL "$CF_URL" -o /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared

        if command -v cloudflared &>/dev/null; then
            echo -e "  ${GREEN}Cloudflared berhasil diinstall!${RESET}"
        else
            echo -e "  ${RED}Install gagal. Cek koneksi internet kamu.${RESET}"
            press_enter
            return
        fi
    else
        echo -e "  ${GREEN}Cloudflared sudah ada.${RESET}"
    fi

    echo ""
    echo -e "  ${WHITE}Pastikan port yang ingin kamu publish sudah berjalan.${RESET}"
    echo -ne "  ${BOLD}${YELLOW}Masukan port: ${RESET}"
    read -r CF_PORT </dev/tty

    if [[ -z "$CF_PORT" ]]; then
        echo -e "  ${RED}Port nggak boleh kosong.${RESET}"
        press_enter
        return
    fi

    echo ""
    echo -e "  ${CYAN}Lagi jalanin tunnel ke port ${CF_PORT}...${RESET}"
    echo -e "  ${DIM}Nunggu domain keluar, bentar...${RESET}"
    echo ""

    TMPLOG=$(mktemp)
    cloudflared tunnel --url "http://localhost:${CF_PORT}" >"$TMPLOG" 2>&1 &
    CF_PID=$!

    DOMAIN=""
    for i in $(seq 1 40); do
        sleep 1
        DOMAIN=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$TMPLOG" | head -1)
        if [[ -n "$DOMAIN" ]]; then
            break
        fi
    done

    if [[ -n "$DOMAIN" ]]; then
        echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
        echo -e "  ${GREEN}Ini domain random cloudflared lu:${RESET}"
        echo -e "  ${BOLD}${WHITE}${DOMAIN}${RESET}"
        echo ""
        echo -e "  ${WHITE}Port running : ${CF_PORT}${RESET}"
        echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    else
        echo -e "  ${RED}Gagal dapetin domain. Cek apakah port ${CF_PORT} beneran jalan.${RESET}"
        echo -e "  ${DIM}Log cloudflared:${RESET}"
        tail -5 "$TMPLOG"
    fi

    echo ""
    echo -e "  ${DIM}Tunnel jalan di background (PID: ${CF_PID}).${RESET}"
    echo -e "  ${DIM}Kalau mau stop: kill ${CF_PID}${RESET}"
    press_enter
}

# ─── 5. INSTALL BAHASA ────────────────────────

menu_language() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Install Bahasa Pemrograman${RESET}"
    echo ""
    echo -e "  ${WHITE}1.${RESET}  Node.js (LTS)"
    echo -e "  ${WHITE}2.${RESET}  Python 3"
    echo -e "  ${WHITE}3.${RESET}  PHP"
    echo -e "  ${WHITE}4.${RESET}  Go (Golang)"
    echo -e "  ${WHITE}5.${RESET}  Java (OpenJDK 17)"
    echo -e "  ${WHITE}6.${RESET}  Ruby"
    echo -e "  ${WHITE}7.${RESET}  Rust"
    echo -e "  ${WHITE}8.${RESET}  Perl"
    echo -e "  ${WHITE}9.${RESET}  C / C++ (gcc, g++)"
    echo -e "  ${WHITE}10.${RESET} .NET (dotnet)"
    echo -e "  ${WHITE}11.${RESET} Bun.js"
    echo -e "  ${WHITE}12.${RESET} Deno"
    echo -e "  ${WHITE}0.${RESET}  Balik ke menu"
    echo ""
    echo -ne "  ${BOLD}${YELLOW}Pilih: ${RESET}"
    read -r LANG_CHOICE </dev/tty

    case "$LANG_CHOICE" in
        1)
            echo -e "\n  ${CYAN}Install Node.js LTS...${RESET}"
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            apt-get install -y nodejs
            echo -e "  ${GREEN}Node.js $(node -v) berhasil diinstall!${RESET}"
            ;;
        2)
            echo -e "\n  ${CYAN}Install Python 3...${RESET}"
            apt-get install -y python3 python3-pip
            echo -e "  ${GREEN}Python $(python3 --version) berhasil diinstall!${RESET}"
            ;;
        3)
            echo -e "\n  ${CYAN}Install PHP...${RESET}"
            apt-get install -y php php-cli php-fpm php-mbstring php-xml php-curl
            echo -e "  ${GREEN}PHP $(php -v | head -1) berhasil diinstall!${RESET}"
            ;;
        4)
            echo -e "\n  ${CYAN}Install Go...${RESET}"
            apt-get install -y golang-go
            echo -e "  ${GREEN}Go $(go version) berhasil diinstall!${RESET}"
            ;;
        5)
            echo -e "\n  ${CYAN}Install Java (OpenJDK 17)...${RESET}"
            apt-get install -y openjdk-17-jdk
            echo -e "  ${GREEN}Java $(java -version 2>&1 | head -1) berhasil diinstall!${RESET}"
            ;;
        6)
            echo -e "\n  ${CYAN}Install Ruby...${RESET}"
            apt-get install -y ruby-full
            echo -e "  ${GREEN}Ruby $(ruby -v) berhasil diinstall!${RESET}"
            ;;
        7)
            echo -e "\n  ${CYAN}Install Rust...${RESET}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path </dev/tty
            source "$HOME/.cargo/env" 2>/dev/null || true
            echo -e "  ${GREEN}Rust berhasil diinstall! Jalanin: source \$HOME/.cargo/env${RESET}"
            ;;
        8)
            echo -e "\n  ${CYAN}Install Perl...${RESET}"
            apt-get install -y perl
            echo -e "  ${GREEN}Perl $(perl -v | head -2 | tail -1) berhasil diinstall!${RESET}"
            ;;
        9)
            echo -e "\n  ${CYAN}Install C/C++...${RESET}"
            apt-get install -y gcc g++ build-essential
            echo -e "  ${GREEN}GCC $(gcc --version | head -1) berhasil diinstall!${RESET}"
            ;;
        10)
            echo -e "\n  ${CYAN}Install .NET...${RESET}"
            wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
            dpkg -i /tmp/packages-microsoft-prod.deb
            apt-get update -qq
            apt-get install -y dotnet-sdk-8.0
            echo -e "  ${GREEN}dotnet $(dotnet --version) berhasil diinstall!${RESET}"
            ;;
        11)
            echo -e "\n  ${CYAN}Install Bun.js...${RESET}"
            curl -fsSL https://bun.sh/install | bash -s -- </dev/tty
            echo -e "  ${GREEN}Bun berhasil diinstall! Restart terminal dulu ya.${RESET}"
            ;;
        12)
            echo -e "\n  ${CYAN}Install Deno...${RESET}"
            curl -fsSL https://deno.land/install.sh | sh -s -- </dev/tty
            echo -e "  ${GREEN}Deno berhasil diinstall! Restart terminal dulu ya.${RESET}"
            ;;
        0) return ;;
        *)
            echo -e "  ${RED}Pilihan nggak valid.${RESET}"
            ;;
    esac
    press_enter
}

# ─── 6. CEK KONEKSI ───────────────────────────

menu_ping() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Cek Koneksi & Ping${RESET}"
    echo ""

    echo -e "  ${WHITE}Ping ke Google (8.8.8.8):${RESET}"
    ping -c 4 8.8.8.8 2>/dev/null || echo -e "  ${RED}Gagal ping.${RESET}"

    echo ""
    echo -e "  ${WHITE}Ping ke Cloudflare (1.1.1.1):${RESET}"
    ping -c 4 1.1.1.1 2>/dev/null || echo -e "  ${RED}Gagal ping.${RESET}"

    echo ""
    echo -e "  ${WHITE}DNS Resolution Test:${RESET}"
    for host in google.com cloudflare.com github.com; do
        RESULT=$(dig +short "$host" 2>/dev/null | head -1)
        if [[ -n "$RESULT" ]]; then
            echo -e "  ${GREEN}${host}${RESET} -> ${RESULT}"
        else
            echo -e "  ${RED}${host}${RESET} -> Gagal resolve"
        fi
    done

    press_enter
}

# ─── 7. MONITOR RESOURCE ──────────────────────

menu_monitor() {
    clear_screen
    echo -e "\n  ${CYAN}Live Monitor Resource${RESET}"
    echo -e "  ${DIM}(tekan Ctrl+C buat stop)${RESET}\n"
    sleep 1
    watch -n 2 '
    echo "  CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk "{printf \"  %.1f%% terpakai\n\", \$2}"
    echo ""
    echo "  RAM:"
    free -h | awk "/Mem:/{printf \"  Total: %s | Terpakai: %s | Bebas: %s\n\", \$2, \$3, \$4}"
    echo ""
    echo "  Disk:"
    df -h / | tail -1 | awk "{printf \"  %s dari %s terpakai (%s)\n\", \$3, \$2, \$5}"
    echo ""
    echo "  Load Average:"
    uptime | awk -F"load average:" "{print \"  \" \$2}"
    '
}

# ─── 8. FIREWALL UFW ──────────────────────────

menu_firewall() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Manajemen Firewall (UFW)${RESET}"
    echo ""

    if ! command -v ufw &>/dev/null; then
        echo -e "  ${YELLOW}UFW belum ada, lagi install...${RESET}"
        apt-get install -y ufw -qq
    fi

    echo -e "  ${WHITE}1.${RESET} Lihat status firewall"
    echo -e "  ${WHITE}2.${RESET} Aktifkan UFW"
    echo -e "  ${WHITE}3.${RESET} Nonaktifkan UFW"
    echo -e "  ${WHITE}4.${RESET} Allow port"
    echo -e "  ${WHITE}5.${RESET} Deny port"
    echo -e "  ${WHITE}6.${RESET} Hapus rule"
    echo -e "  ${WHITE}0.${RESET} Balik"
    echo ""
    echo -ne "  ${BOLD}${YELLOW}Pilih: ${RESET}"
    read -r UFW_CHOICE

    case "$UFW_CHOICE" in
        1) ufw status verbose ;;
        2)
            ufw --force enable
            echo -e "  ${GREEN}UFW aktif!${RESET}"
            ;;
        3)
            ufw --force disable
            echo -e "  ${YELLOW}UFW dinonaktifkan.${RESET}"
            ;;
        4)
            echo -ne "  Port yang mau di-allow: "
            read -r UFW_PORT
            ufw allow "$UFW_PORT"
            echo -e "  ${GREEN}Port ${UFW_PORT} diizinkan.${RESET}"
            ;;
        5)
            echo -ne "  Port yang mau di-deny: "
            read -r UFW_PORT
            ufw deny "$UFW_PORT"
            echo -e "  ${RED}Port ${UFW_PORT} diblokir.${RESET}"
            ;;
        6)
            ufw status numbered
            echo -ne "  Nomor rule yang mau dihapus: "
            read -r UFW_NUM
            ufw --force delete "$UFW_NUM"
            ;;
        0) return ;;
    esac
    press_enter
}

# ─── 9. SWAP ──────────────────────────────────

menu_swap() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Swap Memory${RESET}"
    echo ""

    CURRENT_SWAP=$(free -h | awk '/Swap:/{print $2}')
    echo -e "  Swap sekarang: ${WHITE}${CURRENT_SWAP}${RESET}"
    echo ""
    echo -e "  ${WHITE}1.${RESET} Buat swap baru"
    echo -e "  ${WHITE}2.${RESET} Hapus swap"
    echo -e "  ${WHITE}3.${RESET} Lihat info swap"
    echo -e "  ${WHITE}0.${RESET} Balik"
    echo ""
    echo -ne "  ${BOLD}${YELLOW}Pilih: ${RESET}"
    read -r SWAP_CHOICE

    case "$SWAP_CHOICE" in
        1)
            echo -ne "  Berapa GB swap? (contoh: 2): "
            read -r SWAP_SIZE
            SWAP_BYTES=$((SWAP_SIZE * 1024))
            fallocate -l "${SWAP_SIZE}G" /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count="$SWAP_BYTES" 2>/dev/null
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
            echo -e "  ${GREEN}Swap ${SWAP_SIZE}GB berhasil dibuat!${RESET}"
            ;;
        2)
            swapoff /swapfile 2>/dev/null
            rm -f /swapfile
            sed -i '/swapfile/d' /etc/fstab
            echo -e "  ${YELLOW}Swap dihapus.${RESET}"
            ;;
        3)
            swapon --show
            free -h
            ;;
        0) return ;;
    esac
    press_enter
}

# ─── 10. CEK PORT ─────────────────────────────

menu_ports() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Port yang Lagi Jalan${RESET}"
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"

    if command -v ss &>/dev/null; then
        ss -tulnp 2>/dev/null | tail -n +2 | awk '{printf "  %-8s %-25s %s\n", $1, $5, $7}'
    else
        netstat -tulnp 2>/dev/null | tail -n +3 | awk '{printf "  %-8s %-25s %s\n", $1, $4, $7}'
    fi

    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    press_enter
}

# ─── 11. IP INFO ──────────────────────────────

menu_ipinfo() {
    clear_screen
    animate_banner
    echo -e "  ${BOLD}${CYAN}Info IP Publik & Geolokasi${RESET}"
    echo ""

    start_loading "Ngambil info IP..."
    IP_DATA=$(curl -s --max-time 10 https://ipinfo.io 2>/dev/null)
    stop_loading

    if [[ -z "$IP_DATA" ]]; then
        echo -e "  ${RED}Gagal ambil data. Cek koneksi internet.${RESET}"
        press_enter
        return
    fi

    IP=$(echo "$IP_DATA" | grep '"ip"' | cut -d'"' -f4)
    HOSTNAME_IP=$(echo "$IP_DATA" | grep '"hostname"' | cut -d'"' -f4)
    CITY=$(echo "$IP_DATA" | grep '"city"' | cut -d'"' -f4)
    REGION=$(echo "$IP_DATA" | grep '"region"' | cut -d'"' -f4)
    COUNTRY=$(echo "$IP_DATA" | grep '"country"' | cut -d'"' -f4)
    ORG=$(echo "$IP_DATA" | grep '"org"' | cut -d'"' -f4)
    TIMEZONE=$(echo "$IP_DATA" | grep '"timezone"' | cut -d'"' -f4)

    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    echo -e "  IP Publik  : ${BOLD}${WHITE}${IP}${RESET}"
    echo -e "  Hostname   : ${HOSTNAME_IP:-N/A}"
    echo -e "  Kota       : ${CITY}"
    echo -e "  Provinsi   : ${REGION}"
    echo -e "  Negara     : ${COUNTRY}"
    echo -e "  ISP/Org    : ${ORG}"
    echo -e "  Timezone   : ${TIMEZONE}"
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    press_enter
}

# ─── MAIN LOOP ────────────────────────────────

while true; do
    show_menu
    read -r CHOICE </dev/tty
    case "$CHOICE" in
        1) menu_benchmark ;;
        2) menu_specs ;;
        3) menu_update ;;
        4) menu_cloudflared ;;
        5) menu_language ;;
        6) menu_ping ;;
        7) menu_monitor ;;
        8) menu_firewall ;;
        9) menu_swap ;;
        10) menu_ports ;;
        11) menu_ipinfo ;;
        0)
            clear_screen
            echo ""
            typewrite "  Oke, sampai jumpa! - @chriswijayaa" 0.04
            echo ""
            exit 0
            ;;
        *)
            echo -e "\n  ${RED}Pilihan nggak valid, coba lagi.${RESET}"
            sleep 1
            ;;
    esac
done
