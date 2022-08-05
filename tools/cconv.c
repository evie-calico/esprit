#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

// Converts 5-bit hex colors (like those used by BGB) to 8-bit decimal colors (used by the engine).

int main(int argc, char ** argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <value> ...", *argv);
        return 1;
    }

    for (int i = 1; i < argc; i++) {
        if (i % 3 == 1) {
            if (i != 1) putchar('\n');
            printf("Color %i: ", (i + 2) / 3);
        }
        errno = 0;
        char * end;
        long long value = strtoll(argv[i], &end, 16);
        if (errno || argv[i] == end) {
            fprintf(stderr, "Value %i (%s) is invalid.\n", i, argv[i]);
            value = 0;
        }
        printf("%lli, ", value * 8);
    }
    putchar('\n');
}
