#include <stdio.h>

int fib(int);

int main(void)
{
  int i = fib(10);
  return i;
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

