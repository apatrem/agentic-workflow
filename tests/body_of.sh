#!/usr/bin/env bash
# Print the NORMALIZED body of a markdown-with-YAML-frontmatter file: everything after a leading
# `--- … ---` frontmatter block, with leading/trailing blank lines and per-line trailing whitespace
# removed. NOTHING ELSE is dropped — an H1 or any sneaked line is part of the body and WILL be
# compared (codex review: H1-stripping let arbitrary leading `# …` content pass invisibly).
# Used to freeze command bodies as fixtures and compare moved skill bodies / exact shim payloads.
awk '
  NR==1 && $0=="---" { fm=1; next }
  fm==1 { if ($0=="---") fm=2; next }
  { buf[++n]=$0 }
  END {
    i=1; while (i<=n && buf[i] ~ /^[ \t]*$/) i++          # first non-blank
    j=n; while (j>=i && buf[j] ~ /^[ \t]*$/) j--          # last non-blank
    for (k=i;k<=j;k++) { line=buf[k]; sub(/[ \t]+$/,"",line); print line }
  }
' "$1"
