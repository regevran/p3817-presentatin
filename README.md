# P3817 — conference talk materials

The paper is the spine of the talk. A few words of a sentence are marked like
a highlighter; clicking one jumps into a slide deck, which you drive with the
keyboard, and the last thing you press is "back to the paper" — landing
exactly where you jumped from, not just at the section.

`slides/abstract.md` holds the first real content: structured bindings as they
are today, then what P3817 adds. `slides/motivation.md` is still Lorem ipsum
placeholders.

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

## Design notes

- Dark decks, body text never below ~28px effective, one idea per screen.
- Code wraps rather than scrolls. A snippet too long to fit is a signal to cut
  the snippet, not to hide the tail from the back row.
- `body { max-width: none !important }` is required in the decks: pandoc's
  standalone HTML template caps `body` at `36em`, which silently shrink-wraps
  every slide.

## Verified

Driven through Chromium, over **both** `http://` and `file://`:

```
http  click      705 -> deck(abstract.html?y=705)   -> #/2 -> back -> p3817.html?y=705 @ 705  EXACT
http  Escape     874 -> deck(motivation.html?y=874) -> #/2 -> back -> p3817.html?y=874 @ 874  EXACT
file  click      705 -> deck(abstract.html?y=705)   -> #/2 -> back -> p3817.html?y=705 @ 705  EXACT
file  Backspace  874 -> deck(motivation.html?y=874) -> #/2 -> back -> p3817.html?y=874 @ 874  EXACT
file  Escape     705 -> deck(abstract.html?y=705)   -> #/2 -> back -> p3817.html?y=705 @ 705  EXACT
```

Each run arrows forward twice and back once before exiting, so the
history-per-slide regression cannot pass by accident.

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

**`.today` and `.proposal`** on a slide mark which world it belongs to. They
render as a grey rule under the heading (what the language does now) versus an
accent rule (what P3817 adds). The distinction is carried visually rather than
explained in prose.

**The hidden variable is named per world**: `__e_today` for current C++,
`__e_p3817` for what the proposal expands to. The suffix names the paper, so
it must never appear in an example of today's behaviour.

## Open

- `slides/motivation.md` is still placeholder Lorem ipsum.
- The deck runtime is ~120 lines of hand-rolled JS. If we want fragments
  (progressive line reveal), speaker notes, overview mode and PDF export,
  swap `slides/assets/slide.js` for reveal.js and leave the slide sources
  alone.
