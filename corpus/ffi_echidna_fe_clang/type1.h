typedef int foo_t;
#include <type2.h>
typedef foo_t bar_t;
typedef char baz_t;


typedef int x1;
typedef x1 x2;
typedef x2 x3;
typedef x3 x4;
typedef x4 *x4_ptr;

typedef int a1[42];
typedef int a2[];
