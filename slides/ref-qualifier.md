<a class="back-to-paper" href="../p3817.html#semantics">◀ back to the paper</a>

::: {.slide .title-slide .proposal}
# Copy, or move?

## The ref-qualifier decides — nothing else
:::

::: {.slide .proposal}
# The ref-qualifier decides the type of _e_

`using` does not change how `e` is formed — it is introduced exactly as it is today. So the ref-qualifier still picks its type, and that is what decides whether the assignment copies or moves.

[No special-casing is required]{.label}

This is the reason the proposal needs no rule of its own here: the existing machinery already gives the right answer.
:::

::: {.slide .proposal}
# The three cases

```cpp
auto   [using x, y] = f();   // e owns the object    -> move
auto&  [using x, y] = f();   // e is an lvalue ref   -> copy
auto&& [using x, y] = f();   // e is either          -> copy or move
```
:::

::: {.slide .proposal}
# Why that is the right answer

`auto` gives `e` an owned object and makes it an _xvalue_, so the assignment moves from it. Nothing can be lost: `e` has no name, and the element moved from is exactly the one that got no binding.

`auto&` gives `e` an _lvalue_ naming an object that outlives the scope, so the assignment copies — a move would gut an object the caller still holds.

`auto&&` is one or the other, depending on what it bound to.

None of this turns on `e` dying soon. `e` lives to the end of the _scope_, exactly as any other variable declared there.
:::
