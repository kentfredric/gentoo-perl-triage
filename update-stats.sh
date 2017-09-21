perl sync.pl stats > ./.stats
perl sync.pl stats-verbose-summary > ./.stats-verbose

git --no-pager diff --color=always ./.stats ./.stats-verbose | grep 'm\([+-]\)'
