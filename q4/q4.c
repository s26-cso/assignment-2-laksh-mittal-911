#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int main() {
    char op[6]; 
    int num1, num2;

    // parse input until EOF or unexpected input format
    while (scanf("%5s %d %d", op, &num1, &num2) == 3) {

        char libname[16];
        snprintf(libname, sizeof(libname), "./lib%s.so", op);

        void* handle = dlopen(libname, RTLD_LAZY | RTLD_LOCAL);
        if (!handle) {
            fprintf(stderr, "Error loading %s: %s\n", libname, dlerror());
            continue;
        }

        // get the function pointer (casting through void** to silence compiler warnings)
        typedef int (*op_func)(int, int);
        op_func fn;
        *(void**)(&fn) = dlsym(handle, op);

        if (!fn) {
            fprintf(stderr, "Error finding symbol '%s': %s\n", op, dlerror());
            dlclose(handle);
            continue;
        }

        printf("%d\n", fn(num1, num2));

        // unload immediately to handle the 2GB memory constraint
        dlclose(handle);
    }

    return 0;
}
