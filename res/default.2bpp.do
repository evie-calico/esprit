. ./res.sh

apply_vpath IMG "$2.png"
apply_vpath ARGSFILE "$2.arg"

if ! [[ -e "$ARGSFILE" ]]; then
	unset ARGSFILE
fi

# `-Z` is common enough that making an arg-file for each would be annoying.
# So we do a little hack here.
COLUMNS_FLAG=
if [[ $2 = *.obj ]]; then
	COLUMNS_FLAG=-Z
fi

exec rgbgfx $COLUMNS_FLAG "$IMG" -o "$3" -p "$2.pal" -t "$2.map" -a "$2.pmap" ${ARGSFILE+"@$ARGSFILE"}
