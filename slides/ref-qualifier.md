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

`auto` gives `e` an owned object, and assigning *from* it is a move — the object's lifetime ends with the statement anyway.

`auto&` gives `e` an lvalue reference to something that outlives the statement, so copying is the only safe reading.

`auto&&` depends on what it binds to, so it is one or the other.

None of this is new. It is the same rule that already applies to `std::tie`-free structured binding today.
:::
