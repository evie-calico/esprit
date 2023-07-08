#!/usr/bin/env bash
set -euo pipefail
. ./res.sh

if [[ $2 = *_glyphs ]]; then
	redo-ifchange "${2%_glyphs}.vwf"
else
	printf 'Don'\''t know how to redo "%s"!\n' "$2"
	exit 1
fi
