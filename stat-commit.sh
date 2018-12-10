truncate -s 0 /tmp/.message

master="$( git --no-pager -C ../../usr/portage rev-parse --short remotes/heads/master )"
#perlgit="$(  git --no-pager -C ../../usr/portage rev-parse --short remotes/gentoo-perl/perl-wip )"
stats="$( perl sync.pl stats-all )"

echo "sync to $master: $stats" >> /tmp/.message
echo  >> /tmp/.message
perl sync.pl stats >> /tmp/.message
perl sync.pl stats > ./.stats
perl sync.pl stats-verbose-summary > ./.stats-verbose
perl sync.pl stats-alpha > ./.stats-alpha

git add ./.stats ./.stats-verbose ./.stats-alpha
git commit -F /tmp/.message index.in/ index/ ./.stats ./.stats-verbose ./.stats-alpha
