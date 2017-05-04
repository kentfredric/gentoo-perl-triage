for i in {a..z}; do
  perl stable_lists.pl 'dev-perl/'${i}'*' > index.in/dev-perl-${i}
  chown root:wheel index.in/dev-perl-${i}
  chmod u+rw,g+rw  index.in/dev-perl-${i}
done
