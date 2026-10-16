<a class="back-to-paper" href="../p3817.html#duplicate-targets">◀ back to the paper</a>

::: {.slide .proposal}
# The same variable, twice

A binding list may assign to the same object more than once. The order rule makes that well-defined — the last assignment wins.

[Today]{.label}

```cpp
int x = 0;
std::tie(x, x) = std::make_tuple(1, 2);   // accepted; so x ends as ??
```

`std::tie` accepts it too, and has the same gap: the arguments do not matter — both name `x`. What the library leaves unordered is the *element assignments*, and both of them target `x`, so which value survives is unspecified.

With P3817 it is specified: the writes go left to right, so the last one wins.

A rule forbidding it was drafted and dropped — assigning twice is not a mistake, only pointless, and it cannot be enforced.
:::
