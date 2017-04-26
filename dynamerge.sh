echo "[32m installing > [31m$@[0m"
emerge -tqa1 --unordered-display "$@"
exitstate=$?
[[ $exitstate == 0 ]] && emerge --depclean -q --with-bdeps=y
[[ $exitstate == 0 ]] && echo "[32m success installing > [35m$@[0m"
[[ $exitstate == 0 ]] || echo "[31;1m failure installing > $@[0m"

exit $exitstate
