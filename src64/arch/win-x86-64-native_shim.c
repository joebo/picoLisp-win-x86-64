#include <stdlib.h>
#include <strings.h>

#ifdef __CYGWIN__
#include <windows.h>
#else
#define HANDLE void*
#endif

//gcc -c native_shim.c
//gcc -o picolisp.exe win-x86-64.windows.base.s native_shim.o //c/mingw64/x86_64-w64-mingw32/lib/libkernel32.a //c/mingw64/x86_64-w64-mingw32/lib/libadvapi32.a

__declspec(dllexport) void* mydlsym(HANDLE handle, char *func) {
#ifdef __CYGWIN__
    if (handle == 0) {
        return GetProcAddress(GetModuleHandle(NULL), func);
    } else {
        return GetProcAddress(handle, func);
    }
#else
    return 0;
#endif    
}

__declspec(dllexport) HANDLE mydlopen(char *file) {
#ifdef __CYGWIN__
    if (file == 0) {
        return GetModuleHandle(NULL);
    } else {
        return LoadLibrary(file);
    }
#else
    return 0;
#endif    
}


__declspec(dllexport) void* mymalloc(size_t size) {
    //mingw is not linking malloc correctly with midipix
    //jumping to 0x19514b0 <__imp_malloc>                loopne 0x19514fd <__imp_read+5>
    return realloc(0, size);
}

__declspec(dllexport) void myfree(void *buf) {
    return free(buf);
}

__declspec(dllexport) void mybzero(void *buf, size_t size) {
    bzero(buf, size);
}

