#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char ** argv) {
	if (argc != 3) {
		fputs("Expected two arguments", stderr);
		exit(1);
	}

	FILE * outfile = fopen(argv[1], "wb");
	FILE * infile = fopen(argv[2], "rb");
	if (!infile) {
		perror("input file");
		exit(1);
	}
	if (!outfile) {
		perror("output file");
		exit(1);
	}

	while (1) {
		uint16_t color = (uint8_t) fgetc(infile);
		color |= (uint8_t) fgetc(infile) << 8;
		if (feof(infile)) break;
		fputc((color >> 5 & 0b11111) * 8, outfile);
		fputc((color & 0b11111) * 8, outfile);
		fputc((color >> 10) * 8, outfile);
	}
	fclose(infile);
	fclose(outfile);

	return 0;
}
