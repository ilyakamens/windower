#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build.sh
install_dir="${INSTALL_DIR:-$HOME/Applications}"
mkdir -p "$install_dir"
if pgrep -x Windower >/dev/null; then
    printf 'Quit Windower from its menu before installing.\n' >&2
    exit 1
fi
# Keep the previous local installation recoverable.
if [ -e "$install_dir/Windower.app" ]; then
    backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/windower-backup.XXXXXX")
    mv "$install_dir/Windower.app" "$backup_dir/"
    printf 'Previous app saved in %s\n' "$backup_dir"
fi
ditto build/Windower.app "$install_dir/Windower.app"
open "$install_dir/Windower.app"
printf 'Installed %s/Windower.app\n' "$install_dir"
