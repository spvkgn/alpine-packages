#!/bin/bash
set -euo pipefail

GENERATE_SINGLE_INDEX_PAGE=false
GENERATE_INDEX_PAGES=true
INDEX_PAGE_TEMPLATE=index.html.tpl
INDEX_PAGE_TITLE="${GITHUB_REPOSITORY#$GITHUB_REPOSITORY_OWNER\/}"
INDEX_PAGE_STYLE="https://$GITHUB_REPOSITORY_OWNER.github.io/${GITHUB_REPOSITORY#$GITHUB_REPOSITORY_OWNER\/}/dist/lit.css"
HERE_DIR="$(dirname "$(readlink -f "$0")")"
WORK_DIR="$1"

generate_index() {
  dir=$1
  add_top_level=$2
  files=${3-}
  cd "$dir"
  if [ -z "$files" ]; then
    files=$(find . -mindepth 1 -maxdepth 1 ! -name "$(printf '*\n*')" ! -name index.html ! -path '*/.*' -printf '%P\n')
  fi
  env="$(mktemp)"
  template="$HERE_DIR/$INDEX_PAGE_TEMPLATE"
  cat <<EOF > "$env"
title="$INDEX_PAGE_TITLE"
style="$INDEX_PAGE_STYLE"
add_top_level=$add_top_level
EOF
  for file in $files; do
    if [ -d "$file" ]; then
      file+="/"
      echo "files.'$file'.size=0" >> "$env"
    else
      echo "files.'$file'.size=$(stat -c %s "$file")" >> "$env"
    fi
    echo "files.'$file'.created_at='$(stat -c %y "$file" | date --utc +"%Y-%m-%dT%H:%M:%SZ" -f -)'" >> "$env"
    # echo "files.'$file'.created_at='$(git log --follow --format=%ad --date iso-strict gh-pages -- "$file" | tail -1)'" >> "$env"
  done
  if "$add_top_level"; then
    echo "dir='/$dir'" >> "$env"
  fi
  if [ -f index.html ] && grep -q "INDEX_TEMPLATE" index.html || [ ! -f index.html ]; then
    tpl -debug -toml -env @"$env" "$template" > index.html
  fi
  rm "$env"
  cd -
}

cd "$WORK_DIR" || exit 1
if [ "$GENERATE_SINGLE_INDEX_PAGE" = "true" ]; then
  files=$(find . ! -name "$(printf '*\n*')" ! -name index.html ! -path '*/.*' -type f -printf '%P\n')
  generate_index . false "$files"
elif [ "$GENERATE_INDEX_PAGES" = "true" ]; then
  generate_index . false
  tmp="$(mktemp)"
  find . -mindepth 1 ! -name "$(printf '*\n*')" ! -name index.html ! -path '*/.*' -type d -printf '%P/\n' > "$tmp"
  while IFS= read -r dir
  do
    generate_index "$dir" true
  done < "$tmp"
  rm "$tmp"
fi
