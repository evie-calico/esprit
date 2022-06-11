for file in `find src/res/ -name '*.png'`; do
	pngcrush -ow -rem alla "$file"
done
