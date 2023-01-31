#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="laceOS"
iso_label="laceOS_$(date +%Y%m)"
#iso_label="laceOS_live"
iso_publisher="Rod Kay <http://www.orthanc.site:8080>"
iso_application="laceOS Linux Install/Rescue CD"
#iso_version="$(date +%Y.%m.%d)"
iso_version="0.6"

install_dir="laceos"

buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
	   'uefi-ia32.grub.esp' 'uefi-x64.systemd-boot.esp'
	   'uefi-ia32.grub.eltorito' 'uefi-x64.systemd-boot.eltorito')

arch="x86_64"
pacman_conf="pacman.conf"

airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.zshrc"]="0:0:750"
  ["/root/build_aur_packages"]="0:0:750"
  ["/root/scripts/fetch.sh"]="0:0:750"
  ["/root/scripts/enter_chroot.sh"]="0:0:750"
  ["/root/scripts/build_aur_packages.sh"]="0:0:750"
  ["/root/scripts/clear_installed_package_caches.sh"]="0:0:750"
  ["/root/scripts/sync_all_package_caches.sh"]="0:0:750"
  ["/root/scripts/sync_aur_install_order.sh"]="0:0:750"
  ["/root/scripts/sync_installed_pkgs.sh"]="0:0:750"
  ["/root/scripts/sync_pacstrap_pkgs.sh"]="0:0:750"
  ["/root/scripts/sync_aur_pkgs.sh"]="0:0:750"
  ["/root/scripts/update_installer_xfce4_conf.sh"]="0:0:750"
  ["/root/scripts/update_user_xfce4_conf.sh"]="0:0:750"
  ["/root/scripts/update_user_firefox_conf.sh"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/Desktop/Install laceOS.desktop"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/install_laceOS"]="0:0:750"
  ["/usr/local/bin/start_wifi.sh"]="0:0:750"
)