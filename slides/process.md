<a class="back-to-paper" href="../p3817.html#history">◀ back to the paper</a>

::: {.slide .title-slide .process}
# What R1 changed

## How the proposal moved between revisions
:::

::: {.slide .process}
# The motivation got concrete

R0 argued from principle: some environments do not have the standard library. R1 found a place where **the standard exists but is not allowed**.

Fuchsia's Zircon kernel bans `std` in-kernel. This is real code from it, assigning a loop-scoped binding out to a longer-lived variable:

[Today]{.label}

```cpp
auto [fault_status, _] =
    mapping->PageFaultLocked(guest_paddr, pf_flags, 0, &page_request);
status = fault_status;
```

[With P3817]{.label}

```cpp
auto [using status, _] =
    mapping->PageFaultLocked(guest_paddr, pf_flags, 0, &page_request);
```
:::

::: {.slide .process}
# The specifier rules were reversed

R0 made `const`, `constexpr`, `static`, `thread_local` and `constinit` ill-formed with a `using`-marked element. R1 says the opposite: _all of them are well-formed_.

An innocent feedback question about `static` led to deeper investigation →

Then the understanding that they all refer _only_ to the hidden variable →

Then the understanding that all specifiers stand and fall together →

Then the understanding that diverting from today's specification just for a `using`-marked element is wrong →

Then everything became _simpler_.
:::

::: {.slide .process}
# So we wrote the wording

The Wording section was a placeholder: "_Will be completed upon positive response on the direction of the proposal_".

The feedback was to _write it anyway_, on the grounds that *specifying* a design reveals things that reviewing it does not.

[It was right]{.key}

Rules that read well did not survive being written down
:::

::: {.slide .process}
# The duplicate ban was dropped

A rule forbidding the same target twice was drafted and then removed, because it could not be written.

[Unenforceable]{.label}

```cpp
int glob;
int& x = glob;
int& y = glob;
int& f() {return glob;}
int& g() {return glob;}
std::pair<int,int> bar();
auto [using x, using y] = bar();      // two names, one object
auto [using f(), using g()] = bar();  // may return the same object
```

The order rule makes the result well-defined: the last assignment wins.
:::

::: {.slide .process}
# A target may reuse a declared name

[Already handled]{.label}

```cpp
struct Counter {
    int count = 0;                                  // the member
    std::pair<int, int> tick();                     // {delta, running_total}
    int step() {
        auto [count, using count] = tick();
        //    │             └── this is the MEMBER — the binding to its
        //    └── the binding    left is not yet in scope at this point

        use(count);          // the binding — first element (delta)
        return this->count;  // the member  — second element (running_total)
    }
};
```
:::
