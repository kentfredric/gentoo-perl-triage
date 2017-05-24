EARGS=( 
	"-t1"
	"--quiet-build=y"
	"--quiet-repo-display"
	"--nospinner"
	"--autounmask=y" 
	"--autounmask-keep-masks=y"
	"--autounmask-unrestricted-atoms=n"
	"--autounmask-continue"
	"--unordered-display"
)

installdeps() {
	echo "[32m installing [34mdeps > [31m$@[0m"
	FEATURES="-test" emerge "${EARGS[@]}" --onlydeps --with-test-deps=y "$@"
	return $?
}

installpkg() {
	echo "[32m installing [34mtarget > [31m$@[0m"
	emerge "${EARGS[@]}" "$@"
	return $?
}

cleanup() {
	emerge --depclean -q --with-bdeps=y
	truncate -s 0 /etc/portage/package.accept_keywords/zzz-autounmask
	truncate -s 0 /etc/portage/package.keywords/zzz-autounmask
	truncate -s 0 /etc/portage/package.use/zzz-autounmask
}

installdeps "$@"
depexitstate=$?

if [[ $depexitstate != 0 ]]; then
	echo "[31;1m failure installing [34mdeps[31m> $@[0m"
	echo "$@" >> /tmp/merge.depfailure
	echo "depfailure $@" >> /tmp/merge.all
	exit $depexitstate
fi

installpkg "$@"
exitstate=$?

if [[ $exitstate != 0 ]]; then
	echo "[31;1m failure installing > $@[0m"
	echo "$@" >> /tmp/merge.failure
	echo "failure $@" >> /tmp/merge.all
	exit $exitstate
fi

echo "[32m success installing > [35m$@[0m"
echo "$@" >> /tmp/merge.success
echo "pass $@" >> /tmp/merge.all
cleanup;
