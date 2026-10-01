<a class="back-to-paper" href="../p3817.html#returned-lvalues">◀ back to the paper</a>

::: {.slide .proposal}
# Not only a name

`using` may precede any expression designating a modifiable lvalue — a call that returns a reference, a subscript, not just an identifier.

[Today]{.label}

```cpp
std::tie(foo(), s[0]) = get_pair();
```

[With P3817]{.label}

```cpp
auto [using foo(), using s[0]] = get_pair();
```

Same assignment, no library call — and the destinations are no longer function arguments.
:::

::: {.slide .proposal}
# Left to right

In `std::tie(foo(), s[0])` both destinations are function arguments, and argument evaluation has no order:

> The initialization of a parameter, including every associated value computation and side effect, is indeterminately sequenced with respect to that of any other parameter. — [expr.call]

No library wording can impose one, and `std::tuple`'s assignment does not sequence the assignments either.

With P3817 they are not arguments. Each element is resolved in lexical order: `foo()` is evaluated and assigned before `s[0]` is evaluated.
:::
