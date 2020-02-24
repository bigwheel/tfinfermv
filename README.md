## How to run test

```bash
cd test
find .. -not -path '*/tmp*' -a -not -path '*/\.*' | entr ./test.bats
```
