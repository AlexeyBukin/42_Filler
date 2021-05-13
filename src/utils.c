#include "filler.h"

char *next_filler_line() {
    char *line;
    int gnl;

    gnl = get_next_line(0, &line);
    if (gnl > 0) {
        return line;
    }
    return NULL;
}
