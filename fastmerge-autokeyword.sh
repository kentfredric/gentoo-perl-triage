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

threephase() {
	printf "\e[33;1m --~~-- ~~ \e[34;1m%s\e[33;1m ~~ --~~-- \e[0m\n" "$@" | tee -a /tmp/merge.log
	estatus "threephase 1/3" "no-test-install"

	if [[ -z $FORCEMERGE ]] && portageq has_version / "$@" ; then
		estatus "threephase 1/3" "already installed";
	else
		if FEATURES="${FEATURES} -test" eemerge "${EARGS[@]}" --with-test-deps=n "$@" ; then
			estatus "threephase 1/3" "no-test-install-success"
		else
			eerror "failed" "no-test-install"
			echo "installfailure $@ $(date -Is)" >> /tmp/merge.all
			exit 1
		fi
	fi

	portageq contents / "${1##=}" 2>/dev/null | grep -q '^.'            || eerror "QA" "No contents"
	portageq contents / "${1##=}" 2>/dev/null | grep -q '\.pm$'         || eerror "QA" "No .pm files"
	portageq contents / "${1##=}" 2>/dev/null | grep -q '\.packlist$'   || eerror "QA" "No .packlist files"
	portageq contents / "${1##=}" 2>/dev/null | grep -q '/bin/.'        || eerror "QA" "No /bin/ files"

	estatus "threephase 2/3" "install-test-deps"
	if FEATURES="${FEATURES} -test" eemerge "${EARGS[@]}" --onlydeps --with-test-deps=y "$@" ; then
		estatus "threephase 2/3" "install-test-deps-success"
	else
		echo "test-depfailure $@ $(date -Is)" >> /tmp/merge.all
		eerror "failed" "install-test-deps"
		exit 1
	fi

	estatus "threephase 3/3" "test"
	if eemerge "${EARGS[@]}" --quiet-build=n --jobs=1 "$@"; then
		estatus "threephase 3/3" "test-success"
	else
		eerror "failed" "test"

		echo "test-failure $@ $(date -Is)" >> /tmp/merge.all

		exit 1;
	fi

	echo "pass $@ $(date -Is)" >> /tmp/merge.all

	cleanup
}

cleanup() {
	if [[ -n $AUTODEPCLEAN ]]; then
		unset USE
		unset FEATURES
		source /root/set-gen/cleanup.sh
	fi
}

if [[ -n $THREE_PHASE ]]; then
	threephase "$@"
	exit $?
fi

if [[ -n $NO_TEST ]]; then
	FEATURES="${FEATURES} -test" installpkg  "$@"
	exitstate=$?
	exit $exitstate
fi

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
