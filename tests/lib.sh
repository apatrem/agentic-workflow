# Tiny assertion helpers for the bash test scripts (this repo ships docs, not code,
# so the gate is shell assertions, not a unit-test framework). Each *.test.sh sources
# this, runs assertions, and `exit $fails`.
fails=0
ok(){ echo "  ok   $1"; }
no(){ echo "  FAIL $1"; fails=$((fails+1)); }
have_file(){ [ -f "$1" ] && ok "file: $1" || no "missing file: $1"; }
have_dir(){ [ -d "$1" ] && ok "dir: $1" || no "missing dir: $1"; }
# grep_q <file> <ERE> <description>
grep_q(){ grep -qiE "$2" "$1" 2>/dev/null && ok "$3" || no "$3"; }
# ngrep_q <file> <ERE> <description>  (asserts the pattern is ABSENT)
ngrep_q(){ grep -qiE "$2" "$1" 2>/dev/null && no "$3" || ok "$3"; }
