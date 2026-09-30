<a class="back-to-paper" href="../p3817.html#abstract">◀ back to the paper</a>

::: {.slide .title-slide .today}
# Structured bindings today

## Declaration — and nothing else
:::

::: {.slide .today}
# The values live in a hidden object

[Given]{.label}

```cpp
auto [a, b] = f();
```

[Expands to]{.label}

```cpp
auto __e_today = f();
```

`a` and `b` name pieces of `__e_today`, and both are **new** names.
:::

::: {.slide .today}
# Declaration Example

[Given]{.label}

```cpp
Point arr[2];
auto& [x, y] = arr;
```

[Expands to]{.label}

```cpp
Point (&__e_today)[2] = arr; // __e_today references arr
Point& x = __e_today[0];     // x is declared as a reference to __e_today[0]
Point& y = __e_today[1];     // y is declared as a reference to __e_today[1]
```
:::

::: {.slide .proposal}
# Assign, don't declare

`using` marks an element that names an existing variable — it is **assigned**, not declared.

[Given]{.label}

```cpp
int id;
auto [using id, name] = get_record(); // id is assigned, name is declared
```
:::

::: {.slide .proposal}
# Assignment Example

[Given]{.label}

```cpp
Point arr[2];
Point x;
auto& [using x, y] = arr;
```

[Expands to]{.label}

```cpp
Point (&__e_p3817)[2] = arr; // __e_p3817 references arr, no change
x = __e_p3817[0];            // x is assigned from __e_p3817[0]
Point& y = __e_p3817[1];     // y is declared as a reference to __e_p3817[1]
```
:::
