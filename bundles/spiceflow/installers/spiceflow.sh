#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Official source: https://github.com/Sipper1236/spiceflow
set -euo pipefail

if ryoku-cmd-present spiceflow; then
  echo "spiceflow: already installed"
  exit 0
fi

commit=4e9a6708b4dff8bfa3adecf1573a64493dfbf0b5
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

git -C "$work" init -q
git -C "$work" remote add origin https://github.com/Sipper1236/spiceflow.git
git -C "$work" fetch -q --depth 1 origin "$commit"
git -C "$work" checkout -q --detach FETCH_HEAD
"$work/install.sh" --install-only

ryoku-cmd-present spiceflow || {
  echo "spiceflow: installer completed but command is not on PATH" >&2
  exit 1
}

echo "spiceflow: installed; run 'spiceflow enable' when ready"
