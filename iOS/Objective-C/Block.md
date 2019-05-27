# Block

block的声明

```
int multiplier = 7;
int (^myBlock)(int) = ^(int num) {
    return num * multiplier;
}

```
