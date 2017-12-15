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
	"--verbose"
	"--backtrack=${BACKTRACK:-10}"
)
if [[ -n $EXTRA_EARGS ]]; then
	EARGS+=( "${EXTRA_EARGS[@]}" )
fi

estatus() {
	local action=$1
	shift
	local target=$1
	shift

	(
		printf "\e[32m*  %s \e[34m %s > \e[31m" "$action" "$target"
		echo -n "$@"
		printf "\e[0m\n"
	) | tee -a /tmp/merge.log
}

eerror() {
	local action=$1
	shift
	local target=$1
	shift
	(
		printf "\e[31;1m* %s \e[34m%s\e[31m> " "$action" "$target"
		echo -n "$@"
		printf "\e[0m\n"
	) | tee -a /tmp/merge.log
}

eemerge() {
	(
		printf "\e[32m  ->\e[0m "
		if [[ -n ${FEATURES} ]]; then
			printf "FEATURES=%q " "${FEATURES}"
		fi
		printf "emerge "
		for arg; do
			printf "%q " "$arg";
		done
		printf "\n"
	) | tee -a /tmp/merge.log
	emerge "$@"
	return $?
}

installdeps() {
	estatus installing deps "$@"
	FEATURES="${FEATURES} -test" eemerge "${EARGS[@]}" --onlydeps --with-test-deps=y "$@"
	return $?
}

installpkg() {
	estatus installing target "$@"
	eemerge "${EARGS[@]}" --quiet-build=n --jobs=1 "$@"
	return $?
}

cleanup() {
	if [[ -n $AUTODEPCLEAN ]]; then
		source /root/set-gen/cleanup.sh
	fi
}

if [[ -z $NO_INSTALLDEPS ]]; then
	installdeps "$@"
	depexitstate=$?

	if [[ $depexitstate != 0 ]]; then
		eerror "failure installing" deps "$@"
		echo "$(date -Is) $@" >> /tmp/merge.depfailure
		echo "depfailure $@ $(date -Is)" >> /tmp/merge.all
		exit $depexitstate
	fi
fi

installpkg "$@"
exitstate=$?

if [[ $exitstate != 0 ]]; then
	eerror "failure installing" "" "$@"
	echo "$(date -Is) $@" >> /tmp/merge.failure
	echo "failure $@ $(date -Is)" >> /tmp/merge.all
	cleanup
	exit $exitstate
fi

estatus "success installing" "" "$@"
echo "$(date -Is) $@" >> /tmp/merge.success
echo "pass $@ $(date -Is)" >> /tmp/merge.all

echo "[34m --{+}-- Files --{+}--[0m"
qlist -e "$@"
echo "[34m --{-}-- Files --{-}--[0m"

cleanup
