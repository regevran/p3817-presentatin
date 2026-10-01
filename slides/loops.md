<a class="back-to-paper" href="../p3817.html#loops">◀ back to the paper</a>

::: {.slide .proposal}
# Reassigned every iteration

```cpp
Point latest{};                // the result, kept outside the loop
```

[Today]{.label}

```cpp
for (auto& [pos, t] : trajectory) {
    latest = pos;              // pos exists only to be handed to latest
    plot(latest, t);
}
```

[With P3817]{.label}

```cpp
for (auto& [using latest, t] : trajectory) { plot(latest, t); }
```
:::

