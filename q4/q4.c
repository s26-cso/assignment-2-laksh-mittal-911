#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <string.h>

int main() {
    // buffer for operation name leaving room for null terminator
    char op[6];
    // variables to hold our target numbers
    int num1, num2;

    // read exactly three inputs from standard input loop terminates on end of file
    while (scanf("%5s %d %d", op, &num1, &num2) == 3) {

        // buffer for the dynamic library filename
        char libname[16];
        // construct string with dot slash so linux explicitly checks current directory
        snprintf(libname, sizeof(libname), "./lib%s.so", op);

        // load the shared library into memory using lazy binding
        void* handle = dlopen(libname, RTLD_LAZY);
        if (!handle) {
            // if the library file is missing we print an error and skip to the next iteration
            fprintf(stderr, "error loading library %s\n", libname);
            continue;
        }

        // extract the function pointer by its string name and cast it directly
        int (*fn)(int, int) = (int (*)(int, int)) dlsym(handle, op);

        if (!fn) {
            // if the function is not found inside the library we print an error
            fprintf(stderr, "error finding function %s\n", op);
            // we must close the handle before skipping to prevent a memory leak
            dlclose(handle);
            continue;
        }

        // execute the dynamically loaded function and print the result
        printf("%d\n", fn(num1, num2));

        // immediately unload the library from ram
        // this load and unload cycle is what keeps our total memory footprint under the limit
        dlclose(handle);
    }

    return 0;
}
