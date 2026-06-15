#!/usr/bin/env bash
# Print the NORMALIZED prompt body of a markdown-with-YAML-frontmatter file:
#   - drop a leading `--- … ---` frontmatter block (if present),
#   - drop a single leading H1 (`# …`) line (so a skill may retitle freely),
#   - strip leading/trailing blank lines and per-line trailing whitespace.
# Used to freeze command bodies as fixtures and to compare the moved skill bodies
# byte-for-byte (T-001 single-source / no-loss / no-duplication contract).
awk '
  NR==1 && $0=="---" { fm=1; next }
  fm==1 { if ($0=="---") fm=2; next }
  { buf[++n]=$0 }
  END {
    i=1; while (i<=n && buf[i] ~ /^[ \t]*$/) i++          # first non-blank
    if (i<=n && buf[i] ~ /^# /) { i++; while (i<=n && buf[i] ~ /^[ \t]*$/) i++ }  # drop one H1
    j=n; while (j>=i && buf[j] ~ /^[ \t]*$/) j--          # last non-blank
    for (k=i;k<=j;k++) { line=buf[k]; sub(/[ \t]+$/,"",line); print line }
  }
' "$1"
