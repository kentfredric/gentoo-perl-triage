for i in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
  perl stabile-ring-todo.pl dev-perl-${i} > todo/dev-perl-${i}
  chown root:wheel todo/dev-perl-${i}
  chmod u+rw,g+rw todo/dev-perl-${i}
done
