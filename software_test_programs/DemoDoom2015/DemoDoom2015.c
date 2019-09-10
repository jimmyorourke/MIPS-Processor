//#define DEBUG 1

#ifdef DEBUG
#include<stdio.h>
#endif

void swap(int *p, int *q);
void crazyDiv(int *p, int *q);
int main(void)
{
  int a=5;
  int b=9;
  short int c=0;
#ifdef DEBUG
  printf("orig: a: %d, b: %d\n", a, b);
#endif

  b = b << 2; //  36
  a = a >> 1; // 2
  c = (a * b)  & 0xFF;
#ifdef DEBUG
  printf("shift_orig: a: %d, b: %d, c: %d\n", a, b, c);
#endif
  int *p ;
  int *q ;
  p = &a;
  q = &b;
  swap(p,q);
  // v0 should have a = 36
  a = *p;
  // v1 should have b = 2
  b = *q;
#ifdef DEBUG
  printf("beforeDiv: a: %d, b: %d\n", a, b);
#endif
  crazyDiv(p,q);

  // v0 stores the sum 20
#ifdef DEBUG
  printf("swap: a: %d, b: %d\n", a, b);
#endif
  return a + b;
}

void crazyDiv(int *p, int *q) {
  if (*q != 0) {
    *p = *p / *q;
#ifdef DEBUG
    printf("crazyDiv: p: %d, q: %d\n", *p, *q);
#endif
  }
}

void swap(int *p, int *q)
{
  int temp;
  temp = *p;
  *p=*q;
  *q=temp;
}
