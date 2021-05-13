#include "filler.h"

#include "stdio.h"

int main(int argc, char **argv) {
//    ft_printf("%s\n", argv[0]);
    int a = open("filler.txt", O_WRONLY + O_CREAT, S_IRWXU);
    int i = 0;
    char *line = "";
    while (get_next_line(0, &line) > 0) {
        ft_printf("line:\'%s\'\n", line);
        ft_putstr_fd("line:", a);
        ft_putstr_fd(line, a);
        ft_putstr_fd("\n", a);
    }
    ft_printf("line:\'%s\'\n", line);
    ft_putstr_fd("last line:", a);
    int b = get_next_line(0, &line);
    ft_printf("line:\'%s\'\n", line);
    ft_printf("line:\'%i\'\n", b);
    ft_putstr_fd(line, a);
    ft_putstr_fd("\n", a);
//    for (i = 0; i < argc; i++) {
//        ft_putstr_fd(argv[i], a);
//        ft_putstr_fd("\n", a);
//    }

//    ft_putstr_fd("lmao", a);
    close(a);
    return (0);
}