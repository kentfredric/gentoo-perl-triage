truncate -s 0 /tmp/.message

master="$( git --no-pager -C ../../usr/portage rev-parse --short remotes/heads/master )"
#perlgit="$(  git --no-pager -C ../../usr/portage rev-parse --short remotes/gentoo-perl/perl-wip )"
stats="$( perl sync.pl stats | grep all | sed 's/^.*all:\s*//' )"

echo "sync to $master: $stats" >> /tmp/.message
echo  >> /tmp/.message
perl sync.pl stats >> /tmp/.message

git commit -F /tmp/.message index.in/ index/ todo/
