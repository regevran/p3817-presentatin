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

::: {.slide .proposal}
# The library already allows it

[Given]{.label}

```cpp
int x = 0;
std::tie(x, x) = std::make_tuple(1, 2);   // accepted
```

Both assignments write to `x`, and the wording never says which comes first. libstdc++ happens to leave `x == 2`; nothing requires it to.

P3817 rejects the same duplication outright.
:::
