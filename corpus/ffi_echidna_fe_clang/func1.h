int f1(int, int, int);

typedef int foo_t;
struct bar_t;

void
f2(struct bar_t *, foo_t);

typedef struct bar_t bar_t;

void
f3(bar_t *, foo_t);

typedef struct baz {
  int a, b, c;
} baz;


int *f4(int [3], int *);

typedef int frooble_t[3];

int *f5(frooble_t a, int *b);
