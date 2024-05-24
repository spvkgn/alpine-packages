#!/bin/bash
set -euxo pipefail

GENERATE_SINGLE_INDEX_PAGE=true
GENERATE_INDEX_PAGES=false
INDEX_PAGE_TEMPLATE=index.html.tpl
TITLE="Alpine packages"
HERE_DIR="$(dirname "$(readlink -f "$0")")"
WORK_DIR="$1"

generate_index() {
  dir=$1
  add_top_level=$2
  files=${3-}
  cd "$dir"
  if [ -z "$files" ]; then
    files=$(find . -mindepth 1 -maxdepth 1 ! -name "$(printf '*\n*')" ! -name index.html ! -path '*/.*')
  fi
  env="$(mktemp)"
  template="$HERE_DIR/$INDEX_PAGE_TEMPLATE"
  cat <<EOF > "$env"
title="$TITLE"
add_top_level=$add_top_level
EOF
  for file in $files; do
    if [ -d "$file" ]; then
      echo "files.'$file'.size=0" >> "$env"
    else
      echo "files.'$file'.size=$(stat -c %s "$file")" >> "$env"
    fi
    echo "files.'$file'.created_at='$(stat -c %y "$file" | date --utc +"%Y-%m-%dT%H:%M:%SZ" -f -)'" >> "$env"
  done
  if "$add_top_level"; then
    echo "dir='$dir'" >> "$env"
  fi
  if [ -f index.html ] && grep "ABUILD_RELEASER_ACTION_INDEX_TEMPLATE" index.html > /dev/null || [ ! -f index.html ]; then
    tpl -debug -toml -env @"$env" "$template" > index.html
  fi
  rm "$env"
  cd -
}

cd "$WORK_DIR" || exit 1
if [ "$GENERATE_SINGLE_INDEX_PAGE" = "true" ]; then
  files=$(find . ! -name "$(printf '*\n*')" ! -name index.html ! -path '*/.*' -type f)
  generate_index . false "$files"
elif [ "$GENERATE_INDEX_PAGES" = "true" ]; then
  generate_index . false
  tmp="$(mktemp)"
  find . -mindepth 1 ! -name "$(printf '*\n*')" ! -name index.html ! -path '*/.*' -type d > "$tmp"
  while IFS= read -r dir
  do
    generate_index "$dir" true
  done < "$tmp"
  rm "$tmp"
fi
