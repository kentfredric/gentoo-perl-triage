truncate -s 0 /tmp/.message

stats="$( perl sync.pl stats-all )"

echo "$1: $stats" >> /tmp/.message
echo  >> /tmp/.message
perl sync.pl stats >> /tmp/.message
perl sync.pl stats > ./.stats
perl sync.pl stats-verbose-summary > ./.stats-verbose

git add ./.stats ./.stats-verbose
git commit -F /tmp/.message index.in/ index/ ./.stats ./.stats-verbose
