perl gen_non_core.pl
for i in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
  for input in *-${i}.in; do
    [[ -e "${input%.in}" ]] || touch "${input%.in}"
    perl merge-set.pl "${input%.in}" "${input}" > "/tmp/${input%.in}.out"
    mv /tmp/${input%.in}.out "${input%.in}"
    rm "${input}"
    sudo chown root:wheel "${input%.in}"
    sudo chmod u+rw,g+rw "${input%.in}"
  done
done
