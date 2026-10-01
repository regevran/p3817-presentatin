<a class="back-to-paper" href="../p3817.html#c26-_-placeholder">◀ back to the paper</a>

::: {.slide .proposal}
# Discarding, without a library

P3817 composes with C++26's `_` placeholder. The result is a complete replacement for `std::tie` with `std::ignore` — with no library at all.

| `std::tie` with `std::ignore` | With P3817 and C++26 |
|---|---|
| `std::tie(x, std::ignore) = get_pair();` | `auto [using x, _] = get_pair();` |
| `std::tie(std::ignore, y) = get_pair();` | `auto [_, using y] = get_pair();` |

`using _` is ill-formed — `_` is a discard placeholder, and cannot be the target of an assignment.
:::
