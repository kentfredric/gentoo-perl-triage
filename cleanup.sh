	emerge --depclean -q --with-bdeps=y
	truncate -s 0 /etc/portage/package.accept_keywords/zzz-autounmask
	truncate -s 0 /etc/portage/package.keywords/zzz-autounmask
	truncate -s 0 /etc/portage/package.use/zzz-autounmask
