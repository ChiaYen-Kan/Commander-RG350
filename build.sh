#!/usr/bin/env bash

set -euo pipefail
source ./targets.sh

usage() {
  echo "Usage: build.sh [target]"
  usage_target
}

if ! check_target "$@"; then
  usage
  exit 64
fi

declare -r TARGET="${1}"

check_buildroot() {
  if [[ -n ${TOOLCHAIN:-} ]] && [[ -d $TOOLCHAIN ]]; then
    return
  elif ! [[ -d $BUILDROOT ]]; then
    echo "Please set the BUILDROOT or TOOLCHAIN environment variable"
    exit 1
  fi
  TOOLCHAIN="${BUILDROOT}/output/host/"
}

make_buildroot() {
  if [[ -z ${BUILDROOT:-} ]]; then
    return
  fi
  cd "$BUILDROOT"
  local -a deps=(toolchain sdl sdl_image)
  if [[ "$TARGET" == retrofw ]]; then
    deps+=(freetype)
  else
    deps+=(sdl_ttf sdl_gfx)
  fi
  if (( ${#deps[@]} )); then
    make "${deps[@]}" BR2_JLEVEL=0
  fi
  cd -
}

build() {
  mkdir -p "build-$TARGET"
  cd "build-$TARGET"
  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DTARGET_PLATFORM="$TARGET" \
    -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN}/usr/share/buildroot/toolchainfile.cmake"
  cmake --build . -j $(getconf _NPROCESSORS_ONLN)
  cd -
}

package_opk() {
  ./package-opk.sh "$TARGET"
}

main() {
  check_buildroot
  set -x
  make_buildroot
  build
  package_opk
}

main
