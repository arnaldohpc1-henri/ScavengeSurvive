#!/usr/bin/env bash
# Applies compatibility fixes to vendored dependencies that are needed for
# this project to compile, but which live in `dependencies/` (gitignored,
# re-fetched by `sampctl ensure`). Re-run this script after every
# `sampctl ensure`.
#
# Background: the root pawn.json pins several dependencies (button, item,
# samp-ini) to older releases to avoid other, worse incompatibilities
# (open.mp migration, a pawn-map rewrite that pulls in an unrelated plugin).
# Those older releases use an older samp-logger API (`err`/`dbg`/`_s`/`_i`)
# and an old YSI include path (`YSI\...`) that current YSI-Includes no
# longer ships. This script brings them in line with the modern API/paths
# that the rest of the project (item, container, inventory, ...) already
# uses, without having to pin samp-logger or YSI-Includes to old versions
# too (which would break other, newer parts of the dependency graph).

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "Patching dependencies/action-text/action-text.inc (YSI include path)"
sed -i 's#<YSI\\y_hooks>#<YSI_Coding\\y_hooks>#' dependencies/action-text/action-text.inc

echo "Patching dependencies/button/button.inc (YSI include paths + logger API + const-correctness)"
sed -i \
	-e 's#<YSI\\y_iterate>#<YSI_Data\\y_iterate>#' \
	-e 's#<YSI\\y_timers>#<YSI_Coding\\y_timers>#' \
	-e 's#<YSI\\y_hooks>#<YSI_Coding\\y_hooks>#' \
	-e 's/\berr(/Logger_Err(/g' \
	-e 's/\b_i(/Logger_I(/g' \
	-e 's/SetButtonLabel(Button:id, text\[\]/SetButtonLabel(Button:id, const text[]/g' \
	dependencies/button/button.inc

echo "Patching dependencies/samp-ini/*.{inc,pwn} (logger API + const-correctness)"
for f in dependencies/samp-ini/ini.inc dependencies/samp-ini/ini-parser.pwn dependencies/samp-ini/ini-writer.pwn; do
	sed -i \
		-e 's/\berr(/Logger_Err(/g' \
		-e 's/\bdbg(/Logger_Dbg(/g' \
		-e 's/\b_s(/Logger_S(/g' \
		-e 's/\b_i(/Logger_I(/g' \
		"$f"
done
for f in dependencies/samp-ini/ini.inc dependencies/samp-ini/ini-access-get.pwn dependencies/samp-ini/ini-access-set.pwn; do
	sed -i \
		-e 's/\bkey\[\]/const key[]/g' \
		-e 's/,\s*value\[\]/, const value[]/g' \
		"$f"
done

echo "Done."
