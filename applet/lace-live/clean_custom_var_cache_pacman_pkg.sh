echo
echo
echo Before ...
echo
du -h profile/airootfs/root/custom/var/cache/pacman/pkg/

sudo pacman --noconfirm --quiet -Sc --cachedir profile/airootfs/root/custom/var/cache/pacman/pkg

echo
echo After ...
du -h profile/airootfs/root/custom/var/cache/pacman/pkg/

echo
echo