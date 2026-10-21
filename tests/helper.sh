#!/usr/bin/env bash
# Transport regression tests: no real sudo, desktop or credentials required.
set -euo pipefail
umask 077
repo=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
testroot=$(mktemp -d)
trap 'rm -rf -- "$testroot"' EXIT
mkdir "$testroot/bin" "$testroot/runtime"
cp "$repo/tests/fixtures/omarchy-shell" "$testroot/bin/omarchy-shell"
chmod 700 "$testroot/bin/omarchy-shell"
export XDG_RUNTIME_DIR="$testroot/runtime" TESTROOT="$testroot"
export PATH="$testroot/bin:$PATH" HELPER="$repo/bin/askpass"

# Emulate sudo's argv/parent relationship, without calling real sudo.
script='"$HELPER" "Password:"; status=$?; exit "$status"'
odd=$'line one\nline two: '\''quote and backslash \\'
control=$'carriage\rreturn and bidi \u202e marker'
printf -v long '%08000d' 1
run() { bash -c 'exec -a sudo bash -c "$@"' _ "$script" marker "$odd" '' "$control" "$long"; }

output=$(run)
[[ $output == 'test-only: spaces \ quotes' ]]
rendered=$(< "$testroot/command")
eval "reconstructed=( $rendered )"
[[ ${#reconstructed[@]} == 8 ]]
[[ ${reconstructed[0]} == sudo && ${reconstructed[1]} == -c ]]
[[ ${reconstructed[2]} == "$script" && ${reconstructed[3]} == marker ]]
[[ ${reconstructed[4]} == "$odd" && ${reconstructed[5]} == '' && ${reconstructed[6]} == "$control" ]]
[[ ${reconstructed[7]} == "$long" ]]
[[ $rendered != *$'\r'* && $rendered != *$'\u202e'* ]]
printf 'PASS: exact argv round trip, visible controls, FIFO permissions and response\n'

for mode in cancel timeout invalid; do
  if output=$(MODE=$mode OMARCHY_ASKPASS_TIMEOUT=1 run); then
    printf 'FAIL: %s unexpectedly succeeded\n' "$mode"; exit 1
  fi
  [[ -z $output ]]
  printf 'PASS: %s fails without password output\n' "$mode"
done
[[ $(compgen -G "$XDG_RUNTIME_DIR/omarchy-askpass.*" | wc -l) == 1 ]]
printf 'PASS: request cleanup\n'

run > "$testroot/one" & first=$!
run > "$testroot/two" & second=$!
wait "$first"
wait "$second"
cmp "$testroot/one" "$testroot/two"
printf 'PASS: concurrent requests complete\n'

if "$HELPER" </dev/null > "$testroot/rejected" 2>/dev/null; then
  printf 'FAIL: non-sudo parent accepted\n'; exit 1
fi
[[ ! -s $testroot/rejected ]]
printf 'PASS: non-sudo invocation rejected\n'
