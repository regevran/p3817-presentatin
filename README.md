# P3817 — conference talk materials

The paper is the spine of the talk. A few words of a sentence are marked like
a highlighter; clicking one jumps into a slide deck, which you drive with the
keyboard, and the last thing you press is "back to the paper" — landing
exactly where you jumped from, not just at the section.

In front of it all is **`dist/index.html`**, the title slide. That is the file
you open, and it is what sits on screen in the hall before the talk starts.
Any navigation key hands off to the paper; `c` on the paper brings the cover
back, carrying the line you were on.

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
| Further Design Decisions → Returned Lvalues | `slides/returned-lvalues.md` | 2 | `using` before an expression, and the order `std::tie` cannot give |
| Further Design Decisions → the `_` placeholder | `slides/placeholder.md` | 1 | `using x, _` as a library-free `std::tie`/`std::ignore` |
| Further Design Decisions → duplicate variables | `slides/duplicate.md` | 2 | the same variable twice is ill-formed, on purpose |
| Further Design Decisions → Packs | `slides/packs.md` | 2 | a tuple into a pack of existing variables, in one line |
| Examples → Loops | `slides/loops.md` | 1 | a range-based `for` writing to the caller's variable |

The two Semantics rows are presented in the opposite order to how they sit in
the paper: the ref-qualifier sentence is *below* `Order of assignment`, but the
talk takes it first and then scrolls back up. That is presenter navigation,
deliberately not encoded anywhere in the document.

Motivation has no deck on purpose — it is a read-through, since the Abstract
deck already covers most of it.

Further Design Decisions has four decks, one for each of its subsections, and
Examples has one (Loops). Proposal, Specifiers and Alternative Syntaxes
Considered have none yet.

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

**or just open `dist/index.html` in the browser** — the cover, which hands off
to the paper. Everything is static — no server, no build step at presentation
time, no network. Both work identically; see "Returning to the paper" for why
that took deliberate effort.

The cover is `cover.md`, rendered by the same pandoc as everything else — its
one difference is `--embed-resources`, which inlines the image. That is why
`dist/index.html` is ~3.8 MB: a large HTML file that looks alarming in `ls`,
entirely deliberate, and instant to load off disk. See "The cover" below.

The image itself is rasterised from the Google Slides export
`assets/cover.pdf`, once, out of band — building never needs a PDF renderer:

```sh
pdftoppm -png -scale-to-x 2880 -scale-to-y -1 -singlefile \
    assets/cover.pdf assets/cover
```

2880 wide is exactly 1.5× a 1080p projector. Re-run it if the artwork changes.

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
| `cover.md` | the title slide — one image and a link, and nothing else |
| `assets/cover.pdf` | the slide artwork, exported from Google Slides — the source |
| `assets/cover.png` | the artwork rasterised, inlined into `dist/index.html` |
| `assets/cover.css` | cover styling, embedded at build time |
| `assets/cover.js` | cover keyboard nav, embedded at build time |
| `slides/*.md` | slide sources, one file per deck |
| `slides/assets/` | deck CSS + JS, embedded into each deck |
| `dist/` | generated, gitignored |

## Presenting

**Cover,** `dist/index.html` — the title slide. Open this one first; it is what
sits on screen while the hall fills up.

| Key | |
|---|---|
| `Space` `Enter` `→` `↓` `←` `↑` `PageDown` `PageUp` `Backspace` `c`, or click anywhere | hand off to the paper, at the line it was last on |

There is no separate "back" on a title slide — nothing is behind it — so every
key does the same thing, and a presenter who reaches for the wrong one still
lands where they were instead of losing their place.

Deliberate navigation keys only, not "any key". The cover sits unattended on a
lectern for ten minutes before the talk; a stray keypress must not make the
title slide disappear.

`Esc` is bound too, with one exception: under the Fullscreen API the browser
consumes `Esc` to leave full-screen and nothing can prevent that, so advancing
as well would start the talk out of full-screen. That press is the exit only;
the next one advances. (F11-style full-screen is unaffected — `Esc` does not
leave it.)

**Paper:** press `p` to toggle presentation mode — 16px → 40px, and prose
widened from ~200-character lines to ~75, filling ~78% of a 1920 screen
instead of a narrow column. Remembered for the session, so it survives jumping
to a deck and back. Off by default, so the page still looks exactly like a
WG21 paper.

Press `c` — or click **◀ cover**, which appears in the bottom-right corner in
presentation mode and nowhere else — to go back to the title slide. It carries
the line you are on, the same way a highlight does, so it is a round trip
rather than a one-way trip. The link is injected by `paper.js` rather than
written into `P3817.md`, so a `--submission` build carries no conference
chrome at all.

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

## The cover

A title slide, up in the hall before the talk starts. It is a page and not a
deck, deliberately: a title slide must not carry deck chrome (the `1 / 1`
counter, a "back to the paper" link), and its forward action is *advance to
the paper*, which is not what `slide.js` does — `Space` on a one-slide deck is
a no-op. Keeping it separate also leaves all eleven decks byte-identical.

Built as `dist/index.html` so it is both what you double-click and what
`python3 -m http.server --directory dist` serves at `/`.

**The markdown is one line.** `cover.md` is the image wrapped in a link — that
is the whole content. Everything that makes it look like a cover rather than a
document is `assets/cover.css`, and the keyboard is `assets/cover.js`; both go
in through `-H`, exactly as the decks take `slides/assets/slide.css` and `.js`.
So the markdown is the source of truth for the content and not for the
presentation — worth saying plainly, because it is easy to overestimate what
moving this into markdown bought.

The link is real, so a click advances even with JS off; the script only adds
the `?y=` hand-back.

Pandoc needs three things undone, all of which it does because its standalone
template is built for a document rather than a slide: a title block (from
`--metadata title=`, which is worth keeping for the tab), `body` centred with a
margin, and `body` capped at `36em`. The cap has silently shrink-wrapped things
in this repo before, and it is the same override the paper and the decks carry.

`--resource-path` rather than a `cd`, so `assets/cover.png` in the markdown
resolves no matter which directory `render.sh` was invoked from.

**The raster.** The original export was 960×540 — the slide's own size, which
is a 2× upscale on a 1080p projector and soft on exactly the thing the eye is
on, the title. It is now rasterised from the Slides *PDF* export at 2880 wide,
exactly 1.5× a 1080p screen, so the browser downsamples instead of upsampling.
The PDF is vector, so the type is crisp and the fonts travel inside it; an SVG
export would be equally sharp but risks arriving without its typeface, which
is worse than soft.

`object-fit: contain`, not `cover`. The Core C++ logo and the date sit in the
top-left corner and cropping them is worse than letterboxing. Every hall
projector is 16:9, which is the image's own ratio, so on stage it fills edge to
edge with no mat at all — the mat is only ever visible on the presenter's
laptop, where it is painted the decks' `#12141a` so it reads as slide chrome
rather than as a bug.

**Why 3.8 MB.** `--embed-resources` inlines the PNG as a `data:` URI. That
costs 33% over the 2.9 MB file and makes `dist/index.html` a size that looks
alarming in `ls` — so: the alternative is to link the PNG as a sibling, which
is smaller and tidier, and it was a close call. What decided it is that
`dist/` is thirteen self-contained files and the cover is the one page that has
to work at the very start of the talk with no setup at all. Making it the single
exception buys 1 MB, on a gitignored directory whose HTML is generated and never
read, and costs a mental model with a hole in the one place it matters. It is a
one-flag change if that trade ever looks wrong.

`render.sh` asserts the image really was embedded, because this is the one
property of the file that is invisible when it breaks — a silently un-embedded
cover still renders, just as a broken image in front of the hall.

Measured alternative, if the size does become a problem: a lossy WebP of the
same raster is 292 KB and looked identical to the PNG in a side-by-side of the
title text at presentation scale.

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

**The cover speaks the same protocol.** It is not a deck, but the paper hands
it `index.html?y=4142` and it hands back `p3817.html?y=4142`, so `c` on the
paper and `Esc` on the cover is a round trip that lands on the exact line —
over `file://` too, because it never touches history. Opened cold, with no
`?y=`, it goes to the top, which is what a title slide should do.

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

All eleven markers:

```
[0] slides/abstract.html            -> abstract.html              back @  705 (was  705)  PASS
[1] slides/three-kinds.html         -> three-kinds.html           back @ 1474 (was 1474)  PASS
[2] slides/syntax.html              -> syntax.html                back @ 1669 (was 1669)  PASS
[3] slides/order-of-assignment.html -> order-of-assignment.html   back @ 1955 (was 1955)  PASS
[4] slides/ref-qualifier.html       -> ref-qualifier.html         back @ 2084 (was 2084)  PASS
[5] slides/const.html               -> const.html                 back @ 4142 (was 4142)  PASS
[6] slides/returned-lvalues.html    -> returned-lvalues.html      back @ 5341 (was 5341)  PASS
[7] slides/placeholder.html         -> placeholder.html           back @ 5571 (was 5571)  PASS
[8] slides/duplicate.html           -> duplicate.html             back @ 6068 (was 6068)  PASS
[9] slides/packs.html               -> packs.html                 back @ 6236 (was 6236)  PASS
[10] slides/loops.html              -> loops.html                 back @ 7721 (was 7721)  PASS
```

Each run arrows forward twice and back once before exiting, so the
history-per-slide regression cannot pass by accident.

Layout: all eleven decks fit without clipping, and no code block overflows,
at both 1920×1080 and 1366×768.

- Highlight box identical at rest and on hover (377×19, colour-only change).
- `p` toggles presentation mode: 16px → 40px, prose 1502px wide (78% of a
  1920 screen, ~75 characters per line). The setting survives an excursion to
  a deck and back.
- The semantics grid fits inside the viewport in presentation mode, measured
  by the right-most edge of any descendant (1447px of 1920, was 1994px and
  clipped before the table ratio was lowered).
- `--submission` unwraps all eleven highlight phrases, leaving the sentences
  intact and no `elab` link behind.

The cover, also over both protocols:

```
paper --c--> cover carries the line     index.html?y=4142   (paper was at 4142)  PASS
cover --Esc--> paper, exact line        p3817.html?y=4142 @ 4142                 PASS
cold cover --Space--> paper top         p3817.html @ 0                           PASS
1920x1080 / 1366x768 fills, no mat      img fills the viewport exactly           PASS
1440x900 (16:10) letterboxes, no crop   logo and date intact                     PASS
cover link hidden by default, shown after p                                      PASS
cover link carries the line too         index.html?y=3000                        PASS
```

- The cover never scrolls: `scrollHeight == innerHeight` at all three sizes.
- On a 16:9 screen the image box ratio equals the image's own (1.7778), so
  there is no mat at all; on 16:10 the mat appears top and bottom and nothing
  is cropped.
- The **◀ cover** pill is placed bottom-**right**. Measured at five scroll
  positions, the bottom-left corner lands on the Contents list on the first
  screen and on prose everywhere else, because the paper is left-aligned and
  prose is capped at `min(86%, 95ch)`; the right-hand gutter is normally empty.

Build, after the cover became a pandoc document:

- `render.sh` run from a foreign working directory, and into a custom output
  directory, both produce the same cover — that is `--resource-path` doing its
  job.
- Pandoc's template is fully undone in the output: the title block computes to
  `display: none`, `body` margin is `0px`, `max-width` is `none`, and the page
  has exactly two elements, the hidden header and the `<p>` wrapping the image.
- The embed assertion was tested against a build **without**
  `--embed-resources`: pandoc emits `src="assets/cover.png"` and the build
  aborts, so the guard is not vacuous.

### The C++ on the slides

Two examples have been written onto a slide, looked fine, and not compiled:
`std::unique_ptr` members deleting `Obj`'s copy constructor under
`auto [a, using b, c] = obj;`, and a raw `T*` member assumed to leave a hole
when a pointer's move *is* its copy. Snippets get compiled now, not reasoned
about.

P3817's syntax is not in the system clang. The implementation is the working
tree at `/home/ran/dev/ran/llvm-project-fork`, and the feature is off by
default — the flag is mandatory, and the error names it:

```sh
/home/ran/dev/ran/llvm-project-fork/build/bin/clang++ \
    -std=c++26 -Xclang -fstructured-binding-assignment prog.cpp
```

That is clang 24.0.0git. `/usr/bin/clang++` reports a `regevran/llvm-project-fork`
version string but is an older commit that rejects the syntax — a wrong turn
worth not taking twice.

`e` is unnameable by design, so a check that needs to look at the hole recovers
it through a binding: `Obj` is standard-layout and `m0` is first, so
`Obj* e = reinterpret_cast<Obj*>(&a);`.

The ref-qualifier deck's last slide, compiled from the proposal's own syntax:

```
a=1  c=3
b=owns   e.m1=null   obj.m1=owns
&a == &obj.m0  ->  no (a names e, the copy)
```

The same program with `std::unique_ptr` members:

```
error: call to implicitly-deleted copy constructor of 'Obj'
```

And `auto&& [a, using b, c] = std::move(obj);` prints `&a == &obj.m0 -> yes`,
which settles that `e` is a reference to `obj` there rather than a separate
object — `std::move` is a cast. It is also why `auto&&` compiles with move-only
members and `auto` does not.

## Slide conventions

These exist so the decks stay consistent as content lands.

**`[Given]{.label}` / `[Expands to]{.label}`** head each code block, as in the
paper's semantics grid. The declaration and its expansion are *alternatives* —
never both present in one program — so they never share a listing.

**`[Today]{.label}` / `[With P3817]{.label}`** are the same device for a
before/after pair: two programs that do the same thing in different
languages, rather than one program and its rewrite.

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

- Only the eleven points above have decks; the rest of the paper is a read-through.
- The deck runtime is ~120 lines of hand-rolled JS. If we want fragments
  (progressive line reveal), speaker notes, overview mode and PDF export,
  swap `slides/assets/slide.js` for reveal.js and leave the slide sources
  alone.
