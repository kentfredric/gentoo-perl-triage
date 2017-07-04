truncate -s 0 /tmp/.message

stats="$( perl sync.pl stats | grep all | sed 's/^.*all:\s*//' )"

echo "$1: $stats" >> /tmp/.message
echo  >> /tmp/.message
perl sync.pl stats >> /tmp/.message
perl sync.pl stats > ./.stats
perl sync.pl stats-verbose | grep "^[^ ]" | grep -E "broken|todo" | sort > ./.stats-verbose

git commit -F /tmp/.message index.in/ index/ todo/ ./.stats ./.stats-verbose
