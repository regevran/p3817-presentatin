<a class="back-to-paper" href="../p3817.html#packs">◀ back to the paper</a>

::: {.slide .proposal}
# Packs, in one line

```cpp
template <typename Src, typename... Ts> void assign_from(Src&& t, Ts&... targets)
```

[Today]{.label}

```cpp
std::tie(targets...) = std::move(t);                   // only if Src is a std::tuple or pair
[&]<std::size_t... Is>(std::index_sequence<Is...>) {   // otherwise, this
    ((targets = std::get<Is>(std::move(t))), ...);
}(std::index_sequence_for<Ts...>{});
```

[With P3817]{.label}

```cpp
auto [using targets...] = std::move(t);
```
:::

::: {.slide .proposal}
# Possible usage

[Given]{.label}

```cpp
auto [using targets...] = std::move(t);   // into a pack of variables
auto [using arr[Is]...] = std::move(t);   // into chosen elements of arr
```

`Is` is any index pack, supplied at the call — `assign_into<2, 0, 1>(...)`. No `std::index_sequence` is involved.

Taken together, the expansions must produce exactly the structured binding size _less the number of non-pack elements_ — otherwise the program is ill-formed.
:::
