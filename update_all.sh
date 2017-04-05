for i in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
  perl stable_lists.pl 'dev-perl/'${i}'*' > /tmp/perl-${i}.in
  perl merge-set.pl dev-perl-${i} /tmp/perl-${i}.in > /tmp/perl-${i}.out
  mv /tmp/perl-${i}.out dev-perl-${i}
done
