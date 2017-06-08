truncate -s 0 /tmp/.message

stats="$( perl sync.pl stats | grep all | sed 's/^.*all:\s*//' )"

echo "$1: $stats" >> /tmp/.message
echo  >> /tmp/.message
perl sync.pl stats >> /tmp/.message

git commit -F /tmp/.message index.in/ index/ todo/
