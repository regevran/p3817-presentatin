<a class="back-to-paper" href="../p3817.html#semantics">◀ back to the paper</a>

::: {.slide .title-slide .proposal}
# In what order?

## Order of assignment
:::

::: {.slide .proposal}
# Left to right, each one finished

For all three decomposition kinds, the elements are resolved in lexical order, and each is fully completed before the next is evaluated.

```cpp
auto [using a, using b, using c] = f();
//        1st       2nd       3rd
```

For a `using`-marked element that means: read from `e`, write via `operator=`, and only then move on.
:::

::: {.slide .proposal}
# Nothing was being written

Without `using`, every element of `auto& [x, y] = arr;` is a reference binding into `e` — and binding a reference has no side effect.

[Expands to]{.label}

```cpp
Point (&__e_today)[2] = arr;
Point& x = __e_today[0];     // a binding, not an assignment
Point& y = __e_today[1];     // a binding, not an assignment
```
:::

::: {.slide .proposal}
# Now something is written

`using` replaces that binding with an assignment through `operator=`, and an assignment **is** observable:

```cpp
auto& [_, using arr[0], using arr[1]] = arr;
```

Read left to right, this is an evict-and-shift. Under any other order, `arr` is silently corrupted.
:::

::: {.slide .proposal}
# Tuple-like already had it

Tuple-like decomposition gets this ordering for free: each element is a separately-initialised variable, sequenced by ordinary declaration semantics.

Array and aggregate never needed a guarantee, because they never had a side effect to order.

[This rule generalises the existing guarantee to the two forms that lacked it]{.label}
:::
