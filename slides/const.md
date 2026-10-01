<a class="back-to-paper" href="../p3817.html#const">◀ back to the paper</a>

::: {.slide .title-slide .proposal}
# _const_ with _using_

## The rule, and the alternative that was considered
:::

::: {.slide .proposal}
# The rule

A const-qualified structured binding with `using`-marked elements is ill-formed.

[Given]{.label}

```cpp
const auto [using x, y] = ar;   // ill-formed
```

`using` marks an element to be **assigned** — and a const binding offers nothing assignable.
:::

::: {.slide .proposal}
# How _const_ reaches a name

**New names.** `e` is const, and `x` and `y` refer into it — a non-const reference cannot bind into a const object.

[Given]{.label}

```cpp
const auto [x, y] = get_pair();
```

[Expands to]{.label}

```cpp
const PointPair __e_today = get_pair();  // __e_today is const
const Point& x = std::get<0>(__e_today); // a non-const reference cannot bind
const Point& y = std::get<1>(__e_today); // a non-const reference cannot bind
```
:::

::: {.slide .proposal}
# The alternative

Under the alternative, `const` appertains to the hidden variable `e` — not to the `using`-marked targets — and the declaration is well-formed.

[Given]{.label}

```cpp
const auto [using x, y] = ar;   // valid under this rule
```

`e` is const. An existing target is not touched.
:::

::: {.slide .proposal}
# Why it is attractive

New variables still get `const`, exactly as in any other declaration, and an existing target keeps the type it already had.

[Given]{.label}

```cpp
const auto [using p, y] = get_pair();
```

`y` is new, so it is const. `p` already existed, so it keeps its own type.

Mixed declarations keep working, with no special rule.
:::

::: {.slide .proposal}
# What it cannot answer

[Given]{.label}

```cpp
Point p, q;
const auto [using p, using q] = get_pair();
```

`p` and `q` already exist, with types that are already fixed. Does this declaration change those types?

- **Yes** — a declaration cannot retroactively change the type of a variable.
- **No** — then `const` has no observable effect on them at all, which is misleading.
:::

::: {.slide .proposal}
# What it would actually do

The only coherent reading is that `const` lands on `e` alone — an effect the source cannot show.

[Given]{.label}

```cpp
const auto [using p, using q] = get_pair();
```

[Expands to]{.label}

```cpp
const PointPair __e_alt_const = get_pair();
p = std::get<0>(__e_alt_const);   // must be copied since __e_alt_const is const
q = std::get<1>(__e_alt_const);   // must be copied since __e_alt_const is const
```

Assigning from a const `e` **copies instead of moves**. Nothing in the declaration says so.
:::

::: {.slide .proposal}
# And it is not even uniform

`const` on `e` does not suppress `mutable` members. Through a const object they stay modifiable — and still move.

So some elements copy and some move, depending on how the class happens to be written, with nothing in the declaration to explain which.
:::
