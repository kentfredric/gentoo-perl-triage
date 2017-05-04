set -euo pipefail
for i in index.in/*; do
  f="$(basename "${i}")"
  if [[ ! -e "index/${f}" ]]; then
    touch "index/${f}"
  fi
  echo "Merging ${f}"
  perl merge-set.pl "index/${f}" "index.in/${f}" > "/tmp/${f}.out"
  mv "/tmp/${f}.out" "index/${f}"
  echo "Todoizing ${f}"
  perl stabile-ring-todo.pl "index/${f}" > "todo/${f}"
  chown root:wheel "index/${f}" "todo/${f}"
  chmod u+rw,g+rw "index/${f}" "todo/${f}"
  rm "index.in/${f}"
done
