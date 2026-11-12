#!/usr/bin/env zsh
# Run: zsh tests/check-plugin.zsh
set -eu
root="${0:A:h:h}"
plugin="$root/tab-to-find.plugin.zsh"

grep -q '__tab_fd_base_args' "$plugin"
grep -q 'TAB_TO_FIND_INCLUDE_HIDDEN' "$plugin"
grep -q 'zle redisplay' "$plugin"
if grep -Eq 'fd \. .* -HI|fd \. .*--follow -HI' "$plugin"; then
  print -u2 -- "normal search must not use -H/-I"
  exit 1
fi
if grep -q '$(echo.*wc -l' "$plugin"; then
  print -u2 -- "external echo/wc result counting must not return"
  exit 1
fi
print -- "Source-level checks passed."
