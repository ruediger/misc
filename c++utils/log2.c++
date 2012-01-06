#include <iostream>

template<typename Int>
inline
Int
floor_log2(Int i) {
  Int ret(0);
  while(i >>= 1) {
    ++ret;
  }
  return ret;
}

#define USE_BUILTIN
#ifdef USE_BUILTIN
// x86 asm could use bsr
#include <limits.h>

inline
unsigned int
floor_log2(unsigned int l) {
  int const n = __builtin_clz(l);
  return sizeof(l)*CHAR_BIT - n - 1;
}

inline
unsigned long
floor_log2(unsigned long l) {
  int const n = __builtin_clzl(l);
  return sizeof(l)*CHAR_BIT - n - 1;
}

inline
unsigned long long
floor_log2(unsigned long long l) {
  int const n = __builtin_clzll(l);
  return sizeof(l)*CHAR_BIT - n -1;
}

#endif

int main() {
  std::cout << floor_log2(2) << ' ' << floor_log2(2ul) << std::endl;
}
