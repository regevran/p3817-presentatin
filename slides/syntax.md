<a class="back-to-paper" href="../p3817.html#syntax">◀ back to the paper</a>

::: {.slide .title-slide .proposal}
# What may follow `using`?

## One unary-expression, with two conditions on it
:::

::: {.slide .proposal}
# The rule

`using` followed by [a _unary-expression_ that shall designate a modifiable lvalue]{.key}

[Three separate conditions]{.label}

- **unary-expression** — which expressions qualify at all
- **lvalue** — the ones that name an object
- **modifiable** — and one we may write to

The grammar alone would admit a great deal more than the wording allows.
:::

::: {.slide .proposal}
# 1. A unary-expression

[§ expr.unary]{.label}

```cpp
unary-expression:
    postfix-expression                  // a name, arr[i], obj.field
    unary-operator cast-expression      // * & + - ! ~
```

`postfix-expression` is one of its alternatives, so a name, `arr[i]` or `obj.field` all qualify. A binary or conditional operator is not a unary-expression at all:

```cpp
using x + y          // not a unary-expression
```
:::

::: {.slide .proposal}
# 2. An lvalue

`x++` **is** a unary-expression — it arrives through `postfix-expression`. But [§ expr.post.incr]/1 says of its result:

> The result is a prvalue.

```cpp
using x++            // unary-expression, but a prvalue
using ++x            // this one IS an lvalue
```

Without [shall designate a modifiable lvalue]{.key}, `auto [using x++, y] = f();` would be well-formed.
:::

::: {.slide .proposal}
# 3. Modifiable

An lvalue is not automatically modifiable. A `const` object designates an lvalue, and the same clause catches it:

```cpp
const int n = 0;
auto [using n, y] = f();     // n is an lvalue, but not a modifiable one
```
:::

::: {.slide .proposal}
# What that leaves

```cpp
using id             // a name
using *p             // dereference
using arr[i]         // subscript
using obj.field      // member access
using (x)            // parenthesised
using foo()          // a function call
```

All six are unary-expressions, and all six should designate a modifiable lvalue.

Value category is a property of types, not of syntax — no grammar can express it. That is why the condition sits in the wording.
:::
