# TITAN OS - Requirements

## Android (Termux)
- Android device with Termux installed
- Internet connection
- Git for downloading the project
- Clang and Make only if building the native C engine

Install dependencies:
```bash
pkg update -y && pkg install git clang make -y
```

Install TITAN OS:
```bash
git clone https://github.com/Ffee2/TITAN-OS-.git
cd TITAN-OS-
bash install-android.sh
```

## Arch Linux PC
- Arch Linux or supported Arch-based distribution
- x86_64 architecture
- Root privileges
- Pacman and pacman-conf
- Configured Pacman repositories
- Internet connection

Install:
```bash
git clone https://github.com/Ffee2/TITAN-OS-.git
cd TITAN-OS-
sudo bash install-pc.sh
```

## Debian PRoot
Debian 13 ARM64 is a development environment. No dedicated Debian installer is currently provided.

## Important
- TITAN OS is a terminal-based software project.
- It does not replace Android or install a complete PC operating system.
- No bootable ISO is currently available.
