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
# Array

[Given]{.label}

```cpp
Point arr[2];
auto& [x, y] = arr;
```

[Expands to]{.label}

```cpp
Point (&__e_today)[2] = arr;
Point& x = __e_today[0];
Point& y = __e_today[1];
```
:::

::: {.slide .today}
# Tuple-like

[Given]{.label}

```cpp
PointPair p;
auto& [x, y] = p;
```

[Expands to]{.label}

```cpp
PointPair& __e_today = p;
Point& x = std::get<0>(__e_today);
Point& y = std::get<1>(__e_today);
```
:::

::: {.slide .proposal}
# Assign, don't declare

`using` marks one element of the list.

[Given]{.label}

```cpp
int id;
auto [using id, name] = get_record();
```

`id` already existed, so it is assigned. `name` is declared.
:::

::: {.slide .proposal}
# Array

[Given]{.label}

```cpp
Point arr[2];
Point x;
auto& [using x, y] = arr;
```

[Expands to]{.label}

```cpp
Point (&__e_p3817)[2] = arr;
x = __e_p3817[0];
Point& y = __e_p3817[1];
```
:::
