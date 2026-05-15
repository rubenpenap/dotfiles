typeset -gaU path

path=(
  "/usr/local/bin"
  "$HOME/.bin"
  "$HOME/.local/bin"
  "$HOME/.console-ninja/.bin"
  $path
)

path+=(
  ./node_modules/.bin
  ../node_modules/.bin
  ../../node_modules/.bin
  ../../../node_modules/.bin
  ../../../../node_modules/.bin
  ../../../../../node_modules/.bin
  ../../../../../../node_modules/.bin
  ../../../../../../../node_modules/.bin
)

export PATH
