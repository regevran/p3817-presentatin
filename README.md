# P3817 — conference talk materials

The paper is the spine of the talk. A few words of a sentence are marked like
a highlighter; clicking one jumps into a slide deck, which you drive with the
keyboard, and the last thing you press is "back to the paper" — landing
exactly where you jumped from, not just at the section.

## Where the talk pauses

In **document order**:

| Marker in the paper | Deck | Slides | Covers |
|---|---|---|---|
| Abstract | `slides/abstract.md` | 5 | the hidden variable `__e`; an array with and without `using` |
| Proposal → the `sb-identifier-list` sentence | `slides/three-kinds.md` | 2 | the three decomposition kinds, and how a name binds in each |
| Syntax → the `unary-expression` sentence | `slides/syntax.md` | 6 | the three conditions on what may follow `using` |
| Semantics → `Order of assignment` | `slides/order-of-assignment.md` | 5 | lexical order, and why it became observable only now |
| Semantics → the ref-qualifier sentence | `slides/ref-qualifier.md` | 4 | how the ref-qualifier decides copy vs move |
| Specifiers → the `const` rule | `slides/const.md` | 8 | the rule, the alternative, and why it fails |
| Further Design Decisions → the `_` placeholder | `slides/placeholder.md` | 1 | `using x, _` as a library-free `std::tie`/`std::ignore` |
| Further Design Decisions → duplicate variables | `slides/duplicate.md` | 1 | the same variable twice is ill-formed, on purpose |

The last two are presented in the opposite order to how they sit in the paper:
the ref-qualifier sentence is *below* `Order of assignment`, but the talk takes
it first and then scrolls back up. That is presenter navigation, deliberately
not encoded anywhere in the document.

Motivation has no deck on purpose — it is a read-through, since the Abstract
deck already covers most of it.

Further Design Decisions has two decks — the second and third of its four
subsections; Returned Lvalues and Packs are read-through. Proposal,
Specifiers, Examples, Alternative Syntaxes Considered and the rest have none
yet.

## Build

```sh
./render.sh                 # -> dist/
./render.sh --submission    # -> dist/, with highlights unwrapped
./render.sh /tmp/out        # custom output dir
```

Then either serve it:

```sh
python3 -m http.server --directory dist 8801
```

**or just open `dist/p3817.html` in the browser.** Everything is static — no
server, no build step at presentation time, no network. Both work identically;
see "Returning to the paper" for why that took deliberate effort.

Requires `pandoc` and `python3` to *build*; nothing to present.

## Marking a phrase

Wrap the words in a normal markdown link carrying the `elab` class:

```markdown
This proposal introduces an extension to C++ structured bindings,
[allowing assignment to existing variables](slides/abstract.html){.elab}.
```

It renders as a full-height yellow highlight that is clickable, and reads as
part of the sentence rather than as an inserted button. Because it's a real
markdown link with an attribute and not raw HTML, anything that works in
markdown works inside it — emphasis, `code`, even nested links.

**The marked words are plain prose.** No inline-code chips, and a term of art
uses `_..._`: a chip inside the highlight renders as a grey block sitting in
the yellow. The exception is a token that is a glyph rather than a word — the
`_` in the placeholder sentence — where the chip is the only thing that makes
it legible, and the link is kept as narrow as possible around it.

Only the *shade* changes on hover, never the extent: a fill that grows when
the pointer arrives reads as the text resizing.

`--submission` unwraps each one back to plain text, so the sentence still
reads correctly in a paper handed to WG21.

## Adding a deck

Write `slides/<name>.md`. Each screen is a fenced div:

```markdown
::: {.slide}
# Heading

Body text, ```cpp blocks, whatever.
:::

::: {.slide}
# Next screen
:::
```

Put the back-link once, outside the slides, before the first one:

```html
<a class="back-to-paper" href="../p3817.html#<section-id>">◀ back to the paper</a>
```

Then `./render.sh`.

## Layout

| Path | What it is |
|---|---|
| `P3817.md` | the paper, with highlight phrases inline |
| `assets/paper.js` | return position + presentation mode, embedded at build time |
| `slides/*.md` | slide sources, one file per deck |
| `slides/assets/` | deck CSS + JS, embedded into each deck |
| `dist/` | generated, gitignored |

## Presenting

**Paper:** press `p` to toggle presentation mode — 16px → 40px, and prose
widened from ~200-character lines to ~75, filling ~78% of a 1920 screen
instead of a narrow column. Remembered for the session, so it survives jumping
to a deck and back. Off by default, so the page still looks exactly like a
WG21 paper.

The semantics grid scales down harder than prose (0.64em vs the 40px base)
because it is four columns of code and is the widest thing in the paper — at
the prose ratio its right-hand column ran off the screen.

**Decks:**

| Key | |
|---|---|
| `→` `↓` `Space` `PageDown` `j` | next slide |
| `←` `↑` `PageUp` `k` | previous slide |
| `Home` / `End` | first / last |
| `Esc` / `Backspace` | back to the paper |
| click left half / right half | back / forward |

In full-screen, `Esc` is also the browser's exit-full-screen key, so
`Backspace` is the safer exit if you present that way.

The URL tracks the slide (`#/3`), so a slide stays directly linkable and a
reload lands on the same one.

## Returning to the paper — don't "fix" this

Two things here are load-bearing and were each a bug once.

**The deck is one history entry.** Arrow navigation uses
`history.replaceState`, **not** `pushState`. With `pushState` the stack becomes
`paper → deck#/1 → deck#/2 → deck#/3`, and `history.back()` walks back one
*slide* at a time instead of returning to the paper — the exit silently
becomes "previous slide", and gets worse the more you arrow around.

**The return position travels in the URL, not through history.**
Clicking a highlight navigates to `slides/abstract.html?y=705`; the deck folds
that into its back-link, giving `../p3817.html?y=705`; the paper scrolls there
on load.

It would be simpler to `history.back()` and let the browser restore the scroll
— that works over `http://`. It does **not** work over `file://`, because
browsers don't send a referrer for `file://` navigations, so there is no way
to tell "we came from the paper" from "this deck was opened directly". Since
presenting from a local file is the normal case, the position is carried
explicitly instead. Both protocols now behave identically.

The back-link's `href` still points at the section anchor, so a deck opened
directly, or with JS off, degrades to landing at the top of the right section.

## Code colouring

`slides/assets/code.theme` is a custom pandoc syntax theme — JSON, generated
once from `breezedark`'s schema so all 31 token keys are valid, then recoloured.
Edit it directly to change a colour; no regeneration step.

Dracula-family hues — high chroma, well tested on dark backgrounds. All ten
token colours are AAA on the panel.

| | colour | contrast |
|---|---|---|
| keyword (`auto`, `using`) | `#ff79c6` hot pink, bold | 8.2:1 |
| data type (`int`) | `#8be9fd` electric cyan | 14.0:1 |
| built-in (`std::`) | `#8be9fd` electric cyan | 14.0:1 |
| function (`get_record`) | `#50fa7b` spring green | 14.2:1 |
| number | `#bd93f9` electric purple | 8.1:1 |
| string | `#f1fa8c` bright yellow | 17.4:1 |
| comment | `#8a9ad6` periwinkle, italic | 7.1:1 |
| operator | `#a8b6d1` soft slate | 9.5:1 |
| everything else | `#f8f8f2` | 18.2:1 |

Operators are kept quiet deliberately. Comments are the dimmest thing on the
slide on purpose, but still clear of the 4.5:1 AA floor so they survive a
projector.

### There is a ceiling on how colourful this can get

Worth knowing before spending more time on palettes. Pandoc's lexer tags only
what it can recognise without semantic analysis. Measured across the current
deck:

```
op  x55   [ , ] = ; & (      <- punctuation: 75% of every coloured token
dv  x 8   2 0 1
kw  x 7   auto, using
co  x 2   // comments
dt  x 1   int
```

`Point`, `PointPair`, `arr`, `x`, `y`, `__e_today` get **no tag at all** —
they fall through to the base colour, because pandoc cannot know `Point` is a
type. Punctuation dominates and has to stay quiet or the code reads as noise.
So a palette can only ever colour a minority of the glyphs on screen.

Three levers, in increasing cost:

1. **Tint the base colour** (the `text-color` at the top of the theme). It
   reaches every identifier at once — the single highest-coverage change —
   but it is one hue everywhere, not variety.
2. **Colour operators more strongly.** 55 of 73 tokens. Effective, but `[`,
   `]`, `=` and `;` in a strong colour is exactly what makes code look busy.
3. **Supply a custom C++ syntax definition** via `--syntax-definition=FILE`,
   so capitalised identifiers become types and `name(` becomes a function.
   This is the only route to genuinely more colours. It costs vendoring
   ~800 lines of KDE XML (pandoc compiles its lexers in, so there is nothing
   on disk to copy), and a hand-rolled lexer risks mis-highlighting more
   complex snippets later.

A content lever too: snippets that use strings, `std::` names or function
calls light up far more than the current ones, which are mostly declarations.

**Gotcha:** pandoc only reads a theme file when the extension is `.theme`. The
same JSON named `.json` is treated as an unknown style name and silently falls
back to a built-in — no warning, no error. Keep the `.theme` extension.

The paper is unaffected; it stays on `tango` because it renders on white.

## Design notes

- Dark decks, body text never below ~28px effective, one idea per screen.
- Code wraps rather than scrolls. A snippet too long to fit is a signal to cut
  the snippet, not to hide the tail from the back row.
- `body { max-width: none !important }` is required in the decks: pandoc's
  standalone HTML template caps `body` at `36em`, which silently shrink-wraps
  every slide.

## Verified

Driven through Chromium, over **both** `http://` and `file://`:

All eight markers:

```
[0] slides/abstract.html            -> abstract.html              back @  705 (was  705)  PASS
[1] slides/three-kinds.html         -> three-kinds.html           back @ 1474 (was 1474)  PASS
[2] slides/syntax.html              -> syntax.html                back @ 1669 (was 1669)  PASS
[3] slides/order-of-assignment.html -> order-of-assignment.html   back @ 1955 (was 1955)  PASS
[4] slides/ref-qualifier.html       -> ref-qualifier.html         back @ 2084 (was 2084)  PASS
[5] slides/const.html               -> const.html                 back @ 4142 (was 4142)  PASS
[6] slides/placeholder.html         -> placeholder.html           back @ 5571 (was 5571)  PASS
[7] slides/duplicate.html           -> duplicate.html             back @ 6068 (was 6068)  PASS
```

Each run arrows forward twice and back once before exiting, so the
history-per-slide regression cannot pass by accident.

Layout: all eight decks fit without clipping, and no code block overflows,
at both 1920×1080 and 1366×768.

- Highlight box identical at rest and on hover (377×19, colour-only change).
- `p` toggles presentation mode: 16px → 40px, prose 1502px wide (78% of a
  1920 screen, ~75 characters per line). The setting survives an excursion to
  a deck and back.
- The semantics grid fits inside the viewport in presentation mode, measured
  by the right-most edge of any descendant (1447px of 1920, was 1994px and
  clipped before the table ratio was lowered).
- `--submission` unwraps 2 highlight phrases, leaving the sentences intact.

## Slide conventions

These exist so the decks stay consistent as content lands.

**`[Given]{.label}` / `[Expands to]{.label}`** head each code block, as in the
paper's semantics grid. The declaration and its expansion are *alternatives* —
never both present in one program — so they never share a listing.

**Headings carry no inline-code chips either** — `<h1>` runs to 5.5rem, where
the chip's padding scales with it and the block starts competing with the
heading. `_term_` (the accent-blue second level) instead; it says "keyword"
without the weight.

**`.today` and `.proposal`** on a slide mark which world it belongs to. They
render as a grey rule under the heading (what the language does now) versus an
accent rule (what P3817 adds). The distinction is carried visually rather than
explained in prose.

**The hidden variable is named per world**: `__e_today` for current C++,
`__e_p3817` for what the proposal expands to. The suffix names the paper, so
it must never appear in an example of today's behaviour.

## Open

- Only the eight points above have decks; the rest of the paper is a read-through.
- The deck runtime is ~120 lines of hand-rolled JS. If we want fragments
  (progressive line reveal), speaker notes, overview mode and PDF export,
  swap `slides/assets/slide.js` for reveal.js and leave the slide sources
  alone.
