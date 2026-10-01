<a class="back-to-paper" href="../p3817.html#duplicate-variables-ill-formed-for-assigned-elements">◀ back to the paper</a>

::: {.slide .proposal}
# The same variable, twice

Repeating a variable in a `using`-marked binding list is ill-formed.

[Given]{.label}

```cpp
int x;
auto [using x, using x] = foo();  // ill-formed
```

[Rejected as inherently confusing]{.key}, even for types where repeated assignment would be well-defined — a type whose `operator=` accumulates values.
:::
