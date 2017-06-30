truncate -s 0 /etc/portage/package.accept_keywords/zzz-autounmask
truncate -s 0 /etc/portage/package.keywords/zzz-autounmask
truncate -s 0 /etc/portage/package.use/zzz-autounmask
truncate -s 0 /etc/portage/package.unmask/zzz-autounmask
FEATURES=-test emerge --update --newuse --deep --with-bdeps=y @world
emerge --depclean -q --with-bdeps=y
