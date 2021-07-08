#!/bin/bash

#
# Source: https://gist.github.com/san650/ba500d18179dddb9feb9b3df1d421052
#
# Credits belong to the original author
#

RED=$(printf "\033[31m")
GREEN=$(printf "\033[32m")
GRAY=
CLOSING=$(printf "\033[m")

function color_not_ok() {
  sed "/^not ok/{; s/^/${RED}/; s/$/${CLOSING}/; }"
}

function color_ok() {
  sed "/^ok/{; s/^/"${GREEN}"/; s/$/"${CLOSING}"/; }"
}

function color_debug() {
  sed "/^#/{; s/^/"${GRAY}"/; s/$/"${CLOSING}"/; }"
}

cat \
  | color_not_ok \
  | color_ok \
  | color_debug