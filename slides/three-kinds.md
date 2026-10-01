<a class="back-to-paper" href="../p3817.html#proposal">◀ back to the paper</a>

::: {.slide .title-slide .today}
# Three kinds of decomposition

## What a name in the list binds to
:::

::: {.slide .today}
# The kind decides the bindings

| what is decomposed | how a name binds | example |
|---|---|---|
| an array | element `i` — `__e[i]` | `int& x = __e[0];` |
| a pair or tuple, when `std::tuple_size<E>` is complete | `get<i>(__e)` | `int& x = get<0>(__e);` |
| anything else — a plain struct | the `i`-th data member of `__e` | `int& x = __e.m0;` |

`using` has to be threaded through all three
:::
