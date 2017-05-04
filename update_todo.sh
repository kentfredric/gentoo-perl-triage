for i in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
  for target in *-${i}; do
    perl stabile-ring-todo.pl ${target} > todo/${target}
    chown root:wheel todo/${target}
    chmod u+rw,g+rw todo/${target}
  done
done
