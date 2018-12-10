perl sync.pl stats > ./.stats
perl sync.pl stats-verbose-summary > ./.stats-verbose
perl sync.pl stats-alpha > ./.stats-alpha

git --no-pager diff --color=always ./.stats ./.stats-alpha ./.stats-verbose | grep 'm\([+-]\)'
