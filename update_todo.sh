for i in index/*; do
  target="$(basename ${i})"
  echo "Todoizing ${target}"
  perl stabile-ring-todo.pl index/${target} > todo/${target}
  chown root:wheel todo/${target}
  chmod u+rw,g+rw todo/${target}
done
