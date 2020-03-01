#include <stdio.h>

int fib(int);

int main(void)
{
  fib(10);
  return 0;
}

int fib(int n)
{
  if(n < 2) {
    return 1;
  }
  else {
    return fib(n-1)+fib(n-2);
  }
}
