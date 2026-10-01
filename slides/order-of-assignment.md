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
# It was never observable before

Without `using`, every element is a side-effect-free reference binding — there was nothing to order.

`using` adds `operator=` side effects, so the order becomes visible:

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
