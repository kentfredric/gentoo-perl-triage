if [[ -d /nfs-mnt/amd64-root/usr/portage/.git ]];
then
  export GIT_WORK_TREE="/nfs-mnt/amd64-root/usr/portage/"
else
  export GIT_WORK_TREE="/usr/portage/"
fi
exec git -C "${GIT_WORK_TREE}" diff --diff-filter=d --no-renames --raw "$@" |
  cut -f 2 | xargs perl ./is_perl.pl
