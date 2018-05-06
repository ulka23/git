@@
type T;
T *ptr;
@@
- ptr = xmalloc(sizeof(T));
+ ptr = xmalloc(sizeof(*ptr));

@@
type T;
identifier ptr;
@@
- T *ptr = xmalloc(sizeof(T));
+ T *ptr = xmalloc(sizeof(*ptr));
