#include <stdio.h>
#include <stdlib.h>

#define PLUM_UNPREFIXED_MACROS
#include "libplum.h"

#define CHARACTER_WIDTH 9
#define CHARACTER_HEIGHT 8

#define error(...) do { fprintf(stderr, __VA_ARGS__); exit(1); } while (0);

int main(int argc, char ** argv) {
	if (argc != 3) error("Usage:\n\t%s input_file output_file\n", argv[0]);

	unsigned err;
	struct plum_image * image = plum_load_image(
		argv[1], PLUM_MODE_FILENAME, PLUM_COLOR_32, &err
	);

	if (!image)
		error("%s: load error (%s)\n", argv[1], plum_get_error_text(err));

	if (image->width % CHARACTER_WIDTH != 0)
		error("%s: width must be a multiple of 9", argv[1]);
	if (image->height % CHARACTER_HEIGHT != 1)
		error("%s: width must be a multiple of 8, plus 1", argv[1]);

	uint32_t bg_color = PIXEL32(image, 0, 0, 0);
	uint32_t fg_color = PIXEL32(image, 1, 0, 0);
	uint32_t null_color = PIXEL32(image, 2, 0, 0);

	uint8_t * data = malloc(512);
	size_t index = 0;
	#define append(val) { data[index++] = (val); if (index % 512 == 0) data = realloc(data, index + 512); }

	for (size_t ty = 0; ty < image->height - 1; ty += CHARACTER_HEIGHT) {
		for (size_t tx = 0; tx < image->width; tx += CHARACTER_WIDTH) {
			uint8_t size = 0;
			for (size_t y = ty + 1; y < ty + 1 + CHARACTER_HEIGHT; y++) {
				uint32_t byte = 0;
				size = CHARACTER_WIDTH;
				for (size_t x = tx; x < tx + CHARACTER_WIDTH; x++) {
					byte <<= 1;
					uint32_t pixel = PIXEL32(image, x, y, 0);
					if (pixel == fg_color)
						byte |= 1;
					else if (pixel == null_color)
						size -= 1;
					else if (pixel != bg_color)
						fprintf(stderr, "WARNING: pixel at (x:%zu, y:%zu) is none of the 3 font pixels; treating as blank. Note: only monochrome fonts are supported!", x, y);
				}
				if (byte & (1 << (CHARACTER_WIDTH - 8) - 1))
					error("Row at (x:%zu, y:%zu): only the first 8 pixels of a character can be non-blank!", tx, y);
				append(byte >> (CHARACTER_WIDTH - 8));
			}
			append(size);
		}
	}

	#undef append

	plum_destroy_image(image);

	FILE * output = fopen(argv[2], "w");
	for (size_t i = 0; i < index; i++)
		fputc(data[i], output);
	fclose(output);
	free(data);

	return 0;
}
