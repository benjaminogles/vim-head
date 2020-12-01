#!/bin/bash 

export VADER_OUTPUT_FILE=/tmp/vader.out
[[ -f $VADER_OUTPUT_FILE ]] && rm $VADER_OUTPUT_FILE

run_test() {
  echo -n "Running $1 tests: "
  nvim -u tests/vimrc -c "Vader! tests/$1.vader"
  if [[ $? -eq 0 ]]
  then
    echo Success
  else
    echo Failure \(check /tmp/vader.out\)
    exit
  fi
}

run_test editing
run_test agenda
