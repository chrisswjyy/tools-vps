# VPS Tools by Chris

Script bash interaktif untuk manajemen dan monitoring VPS berbasis Linux (Ubuntu/Debian).

Telegram: [@chriswijayaa](https://t.me/chriswijayaa)

---

## Cara Penggunaan

Jalankan perintah berikut di terminal VPS kamu:

```bash
curl -fsSL https://raw.githubusercontent.com/chrisswjyy/tools-vps/main/tools.sh -o tools.sh && bash tools.sh
```

Script akan otomatis berjalan sebagai root. Pastikan kamu memiliki akses sudo.

---

## Fitur

| No | Fitur | Keterangan |
|----|-------|------------|
| 1 | Benchmark VPS | Speedtest, disk speed (3x run), info RAM, dan CPU benchmark |
| 2 | Lihat Spesifikasi VPS | Info lengkap CPU, RAM, storage, OS, kernel, uptime, dan IP |
| 3 | Update & Upgrade Sistem | Menjalankan apt update dan apt upgrade |
| 4 | Run Cloudflared | Auto install dan jalankan tunnel Cloudflare, cukup masukkan port |
| 5 | Install Bahasa Pemrograman | Node.js, Python, PHP, Go, Java, Ruby, Rust, Perl, C/C++, .NET, Bun, Deno |
| 6 | Cek Koneksi & Ping | Ping ke Google dan Cloudflare, serta DNS resolution test |
| 7 | Monitor Resource (Live) | CPU, RAM, disk, dan load average secara realtime |
| 8 | Manajemen Firewall (UFW) | Allow, deny, hapus rule, aktifkan atau nonaktifkan UFW |
| 9 | Swap Memory | Buat, hapus, atau lihat info swap |
| 10 | Cek Port yang Jalan | Daftar semua port yang sedang listening |
| 11 | Info IP Publik & Geolokasi | IP, kota, ISP, timezone, dan info geolokasi lengkap |

---

## Persyaratan

- OS: Ubuntu / Debian
- Akses root atau sudo
- Koneksi internet aktif

---

## Catatan

- Script harus dijalankan dari file, bukan langsung di-pipe ke bash, agar input terminal berfungsi dengan benar.
- Beberapa fitur seperti deteksi tipe RAM membutuhkan package `dmidecode`.
- Fitur benchmark CPU membutuhkan `sysbench` yang akan diinstall otomatis jika belum ada.

---

## Lisensi

Script ini dibuat untuk keperluan pribadi dan edukasi. Penggunaan sepenuhnya menjadi tanggung jawab pengguna.
