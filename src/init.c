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
//
//char *next_filler_line_params(int must_be_last) {
//    char *line;
//    int gnl;
//
//    gnl = get_next_line(0, &line);
//    if (gnl > 0) {
//        return line;
//    }
//    return NULL;
//}
