#!/usr/bin/env bash
# Build the P3817 conference-talk materials.
#
#   dist/index.html           the cover — the title slide, shown in the hall
#                             before the talk; hands off to the paper
#   dist/p3817.html           the paper, with clickable highlight phrases
#   dist/slides/<name>.html   self-contained slide decks (CSS + JS embedded)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./render.sh [OUTDIR] [--submission]

Builds the cover, the paper and the slide decks into OUTDIR (default: ./dist).

Marking a phrase for elaboration
--------------------------------
Wrap a few words of a sentence in a normal markdown link carrying the
`elab` class. It renders as a yellow highlighter mark that is clickable:

    ...structured bindings, [allowing assignment to existing variables](slides/abstract.html){.elab}.

Any markdown inside works as usual (emphasis, `code`, links), because this
is a real markdown link with an attribute, not raw HTML.

Files:
  P3817.md                  the paper
  assets/paper.js           paper presentation mode (embedded)
  cover.md                  the title slide, one image and a link
  assets/cover.css          cover styling    (embedded into the cover)
  assets/cover.js           cover keyboard nav (embedded into the cover)
  assets/cover.png          the title slide image (embedded; see below)
  slides/*.md               slide sources, one file per topic cluster
  slides/assets/slide.css   deck styling   (embedded into each deck)
  slides/assets/slide.js    keyboard nav   (embedded into each deck)

The cover
---------
Rendered with pandoc like everything else, so it has a markdown source. The
one difference is --embed-resources, which inlines assets/cover.png as a data:
URI: the cover is then a single file with no sibling asset, the same property
every deck and the paper already have. That is what makes dist/index.html
~3.9 MB, which is deliberate.

assets/cover.pdf is the Google Slides export and is the source of truth for
the artwork; the PNG next to it is rasterised from it once, out of band, so
that building never needs a PDF renderer:

  pdftoppm -png -scale-to-x 2880 -scale-to-y -1 -singlefile \
      assets/cover.pdf assets/cover

2880 wide is exactly 1.5x a 1080p projector, so the browser downsamples and
the title text stays crisp instead of being upscaled 2x from the slide's own
960x540. Re-run it if the artwork changes.

Options:
  --submission   Unwrap every highlighted phrase back to plain text, for a
                 clean paper to hand to WG21. Slides and cover are still built.
  -h, --help     Show this message and exit

Requirements:
  pandoc   (tested with 3.9.0.2; other versions may differ in HTML structure)
  python3  (pre-processes fenced code blocks inside raw HTML tables)
EOF
}

SUBMISSION=0
OUTARG=""
for arg in "$@"; do
  case "$arg" in
    -h|--help)    usage; exit 0 ;;
    --submission) SUBMISSION=1 ;;
    -*)           echo "render.sh: unknown option $arg" >&2; exit 2 ;;
    *)            OUTARG="$arg" ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$SCRIPT_DIR/P3817.md"
SLIDES_SRC="$SCRIPT_DIR/slides"
ASSETS="$SLIDES_SRC/assets"
PAPER_JS="$SCRIPT_DIR/assets/paper.js"
OUTDIR="${OUTARG:-$SCRIPT_DIR/dist}"
PAPER="$OUTDIR/p3817.html"
SLIDES_OUT="$OUTDIR/slides"

for f in "$INPUT" "$ASSETS/slide.css" "$ASSETS/slide.js" "$PAPER_JS"; do
  [ -f "$f" ] || { echo "render.sh: missing $f" >&2; exit 1; }
done
command -v pandoc >/dev/null || { echo "render.sh: pandoc not found on PATH" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 0. Highlight-marker guard
#
# Each highlight phrase in the paper is the only route into its deck. Losing
# one is silent: the paper still renders, the deck still builds, and the talk
# simply cannot reach that slide - which looks exactly like "fine" until it is
# on stage. R1 stripped all eleven markers when it was drafted, so this is a
# demonstrated failure, not a hypothetical one.
#
# The invariant needs no count to maintain: every deck has exactly one marker,
# and every marker names a deck that exists. Delete a deck and its marker
# together and this stays quiet; drop either one alone and the build fails.
# ---------------------------------------------------------------------------
python3 - "$INPUT" "$SLIDES_SRC" <<'PYEOF'
import glob, io, os, re, sys

paper, slides_src = sys.argv[1], sys.argv[2]
text = io.open(paper, encoding='utf-8').read()
names = re.findall(r'\]\(slides/([^)/]+)\.html\)\{\.elab\}', text)

dangling = [n for n in names if not os.path.exists(os.path.join(slides_src, n + '.md'))]
if dangling:
    sys.exit(f'render.sh: markers point at decks with no source: {dangling}')

dupes = sorted({n for n in names if names.count(n) > 1})
if dupes:
    sys.exit(f'render.sh: more than one marker reaches the same deck: {dupes}')

have = {os.path.basename(p)[:-3] for p in glob.glob(os.path.join(slides_src, '*.md'))}
orphans = sorted(have - set(names))
if orphans:
    sys.exit(f'render.sh: no marker reaches these decks: {orphans}')

if not names:
    sys.exit(f'render.sh: {paper} has no highlight markers at all')

print(f'guard   {len(names)} highlight markers -> {len(have)} decks, all reachable')
PYEOF

mkdir -p "$SLIDES_OUT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# 0. The cover
#
# The title slide, up in the hall before the talk starts. Built as
# dist/index.html for two reasons: it is then what you double-click, and it is
# what `python3 -m http.server --directory dist` serves at /.
#
# Rendered exactly like a deck is — same pandoc, same -H header injection —
# so it has a markdown source like every other artifact here. See "The cover"
# in the usage text for why --embed-resources is on.
#
# Pressing a navigation key — or clicking — hands off to the paper, carrying
# the line the paper was last on as ?y=, the same parameter the decks use.
# So the cover is reached and left exactly like a deck is, and "c" on the
# paper brings it back.
# ---------------------------------------------------------------------------

COVER_MD="$SCRIPT_DIR/cover.md"
COVER_CSS="$SCRIPT_DIR/assets/cover.css"
COVER_JS="$SCRIPT_DIR/assets/cover.js"
COVER_PNG="$SCRIPT_DIR/assets/cover.png"
COVER="$OUTDIR/index.html"

for f in "$COVER_MD" "$COVER_CSS" "$COVER_JS" "$COVER_PNG"; do
  [ -f "$f" ] || { echo "render.sh: missing $f" >&2; exit 1; }
done

{
  printf '<style>\n';   cat "$COVER_CSS"; printf '\n</style>\n'
  printf '<script>\n';  cat "$COVER_JS";  printf '\n</script>\n'
} > "$TMP/cover-head.html"

# --resource-path, not a cd: cover.md refers to the image as assets/cover.png
# so the markdown stays a portable source, and this makes that resolve no
# matter which directory render.sh was invoked from.
pandoc "$COVER_MD" \
  -s \
  --embed-resources \
  --resource-path="$SCRIPT_DIR" \
  --metadata title="Structure Binding Assignment (P3817) — Core C++ 2026" \
  -H "$TMP/cover-head.html" \
  -o "$COVER"

# The one property of this file that is invisible when it breaks. If pandoc
# ever stops embedding — a renamed flag, a path it cannot resolve — the cover
# would still render, just as a broken image in front of the hall. Fail the
# build instead.
grep -q 'src="data:image/png;base64,' "$COVER" \
  || { echo "render.sh: cover image was not embedded into $COVER" >&2; exit 1; }

echo "cover   $COVER  ($(du -h "$COVER" | cut -f1), image embedded)"

# ---------------------------------------------------------------------------
# 1. Slide decks
#
# CSS and JS are embedded rather than linked, so each deck is a single file
# that presents offline with no network and no sibling assets to lose.
# ---------------------------------------------------------------------------

{
  printf '<style>\n';   cat "$ASSETS/slide.css"; printf '\n</style>\n'
  printf '<script>\n';  cat "$ASSETS/slide.js";  printf '\n</script>\n'
} > "$TMP/slide-head.html"

shopt -s nullglob
# A renamed or deleted slide source must not leave its HTML behind, or dist/
# silently accumulates decks the talk can no longer reach — and a stale deck
# looks exactly like a live one from the audience. Everything here is
# generated by this script, so clearing it first is safe.
rm -f "$SLIDES_OUT"/*.html
for md in "$SLIDES_SRC"/*.md; do
  name="$(basename "$md" .md)"
  pandoc "$md" \
    -s \
    --metadata title="P3817 — $name" \
    --syntax-highlighting="$ASSETS/code.theme" \
    -H "$TMP/slide-head.html" \
    -o "$SLIDES_OUT/$name.html"
  echo "slide   $SLIDES_OUT/$name.html"
done
shopt -u nullglob

# ---------------------------------------------------------------------------
# 2. Paper
#
# Fenced code blocks inside raw HTML table cells are converted before pandoc
# sees them, so they get syntax highlighting like every other code block.
# ---------------------------------------------------------------------------

PAPER_CSS=$(cat <<'EOF'
<style>
  body          { max-width: none !important; }
  div.sourceCode{ overflow: visible !important; }
  pre           { white-space: pre-wrap; word-break: break-word; }
  /* pandoc sets white-space:pre on `code`, and the text is in that inner
     element — without this the rule above never actually wraps anything.
     Invisible at normal size; matters when the paper is zoomed for a talk. */
  pre code      { white-space: inherit; }
  header#title-block-header { display: none; }
  nav#TOC       { background: #f9f9f9; border: 1px solid #ddd; padding: 0.6em 1.2em; margin: 1.5em 0; display: inline-block; min-width: 20em; }
  nav#TOC h2    { margin-top: 0; font-size: 1em; border-bottom: 1px solid #ddd; padding-bottom: 0.3em; }
  table         { width: 100%; border-collapse: collapse; }
  td, th                              { vertical-align: top; padding: 0.4em 0.6em; }
  td > table, th > table              { margin: 0 auto; width: auto; }
  td > table th                       { vertical-align: middle; }
  #semantics-grid td,
  #semantics-grid th                  { border: 1px solid #aaa; }
  #semantics-grid td > table td,
  #semantics-grid td > table th       { border: 1px solid #aaa; }
  #semantics-grid > tbody > tr > th:first-child { vertical-align: middle; }
  #semantics-grid > tbody > tr > td             { vertical-align: middle; }
  #semantics-grid > tbody > tr > th:nth-child(2),
  #semantics-grid > tbody > tr > td:nth-child(2) { background-color: #f5fff5; }
  #semantics-grid > tbody > tr > th:nth-child(3),
  #semantics-grid > tbody > tr > td:nth-child(3) { background-color: #f5f5ff; }
  #semantics-grid > tbody > tr > th:nth-child(4),
  #semantics-grid > tbody > tr > td:nth-child(4) { background-color: #fff8f0; }
  #cpp26-table td, #cpp26-table th               { border: 1px solid #aaa; }
  :not(pre) > code                               { background-color: #f0f0f0; padding: 0.1em 0.3em; border-radius: 3px; }
  #semantics-summary td, #semantics-summary th   { border: 1px solid #aaa; vertical-align: middle; }
  #semantics-summary td:first-child              { width: 18em; }
  /* The implementation table is R1's runnable-example index: a ‡ column, a
     description, and a Godbolt URL. Sized to content, and the URL column must
     never wrap — a wrapped URL is unreadable and unclickable. */
  #implementation-table                           { width: auto; }
  #implementation-table td:first-child,
  #implementation-table th:first-child            { text-align: right; padding-right: 1em; }
  #implementation-table td:last-child             { white-space: nowrap; }
  pre.sourceCode.diff .va { display: block; background-color: #e6ffe6; color: #006600; }
  pre.sourceCode.diff .st { display: block; background-color: #ffe6e6; color: #cc0000; }

  /* ---- "elaborate here" phrases --------------------------------------
     A few words of a sentence, marked like a highlighter and clickable.
     Written in P3817.md as a markdown link with a class:
         [the marked words](slides/deck.html){.elab}
     Has to be spottable while scrolling fast on stage, and has to read as
     part of the sentence rather than as an inserted button. */
  a.elab {
    background: #ffe066;
    color: inherit;
    text-decoration: none;
    padding: 0.05em 0.12em;
    border-radius: 2px;
    cursor: pointer;
  }
  /* Only the shade changes on hover, never the extent — a fill that grows
     when the pointer arrives reads as the text resizing. */
  a.elab:hover { background: #ffd12e; }

  /* ---- runnable-example references -------------------------------------
     Every listing that has a Godbolt page carries <sub>[[‡ 3]](#ex-3)</sub>
     on its own line, which pandoc makes a paragraph. Unstyled, that is a whole
     paragraph of browser-default <sub> — 0.83em, so 33px at the 40px
     presentation base — inside a 68px line box with a paragraph's 1em
     margins above and below: a wide band of emptiness holding a marker that
     only needs to be glanceable, once under every listing in the paper.

     Two things fix it, and both are needed. Shrinking the *paragraph's*
     font-size is what shrinks the band, because the line box is sized by the
     block's own font-size no matter how small the inline <sub> inside it is.
     The clamp keeps it legible on a desk (11px floor at the 16px base) while
     letting it scale down on a projector (18px ceiling).

     :has() is what finds these without editing all 28 occurrences in
     P3817.md. Nothing else in the paper is a paragraph whose only child is a
     <sub>, so the selector is exact rather than approximate. Without :has()
     support the markers simply keep a paragraph's spacing — degraded, not
     broken. */
  p:has(> sub:only-child) {
    font-size: clamp(12px, 0.42em, 17px);
    margin: 0 0 0.9rem;
    line-height: 1.3;
  }
  /* The listing's own 1em bottom margin is what actually separates the marker
     from the code, not the marker's margin-top: adjacent sibling margins
     collapse and the larger wins, so shrinking only the marker changed the
     font and left the gap exactly where it was. Pull the listing in when a
     reference follows it — the marker is the listing's caption, so the gap
     belongs to the pair rather than to either alone. */
  div.sourceCode:has(+ p > sub:only-child) { margin-bottom: 0.12rem; }

  /* ---- the cover link (press "c") ------------------------------------
     Injected by paper.js, never written into the paper source. Hidden unless
     presentation mode is on: on a desk the page still has to look exactly
     like a WG21 submission, and this is talk furniture.

     Fixed to the bottom-right corner so it is reachable from any scroll
     position mid-talk. That means it floats over the page, which is why it
     gets an opaque pill rather than bare text: a link sitting on top of a
     paragraph still has to read as a link.

     Right and not left, because the paper is left-aligned — prose is capped
     at min(86%, 95ch), so the right-hand gutter is normally empty, while the
     bottom-left corner lands on the Contents list on the first screen and on
     prose everywhere else. Measured at five scroll positions. */
  a.cover-link {
    display: none;
    position: fixed;
    right: 2vw;
    bottom: 2vh;
    z-index: 20;
    font-size: 0.5em;
    line-height: 1.7;
    padding: 0 0.8em;
    border: 1px solid #c8d2e0;
    border-radius: 999px;
    background: #fff;
    color: #2a5db0;
    text-decoration: none;
    opacity: 0.75;
  }
  html.present a.cover-link { display: inline-block; }
  a.cover-link:hover       { opacity: 1; }

  /* ---- presentation mode (press "p") --------------------------------
     The paper's natural 16px / ~200-character lines are unreadable from the
     back of a hall, and the deck you jump into is 32px+, so type size lurches
     on every excursion. This scales the paper up and pulls prose in to a
     readable measure. The wide semantics tables stay full-bleed. */
  html.present                     { font-size: clamp(20px, 2.1vw, 40px); }
  html.present body                { line-height: 1.5; }
  /* Prose fills the screen. A desk-reading measure (~65 characters) leaves
     half a projector empty and looks like a mistake; the audience is glancing
     at this, not reading it, so favour coverage. Capped in ch so an ultrawide
     monitor still does not produce 150-character lines. */
  html.present p,
  html.present li,
  html.present blockquote          { max-width: min(86%, 95ch); }
  html.present h1, html.present h2,
  html.present h3, html.present h4 { max-width: min(92%, 60ch); }
  html.present nav#TOC             { font-size: 0.75em; }
  /* The semantics grid is four columns of code and is the widest thing in the
     paper. At 0.78em it overflowed its cells by 74px at the 40px base and the
     right-hand column was clipped off the screen. It has a different appetite
     from prose, so it scales down harder. Verified to fit at 1920. */
  html.present table               { font-size: 0.64em; }
  html.present pre                 { font-size: 0.62em; }
</style>
EOF
)

# --submission: unwrap the highlight phrases, leaving the sentence intact.
SRC="$INPUT"
if [ "$SUBMISSION" = 1 ]; then
  SRC="$TMP/P3817.submission.md"
  python3 - "$INPUT" "$SRC" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()
# [the marked words](slides/deck.html){.elab}  ->  the marked words
text, n = re.subn(r'\[([^\[\]]*)\]\([^)]*\)\{\.elab\}', r'\1', text)
open(dst, 'w').write(text)
sys.stderr.write(f'submission mode: {n} highlight phrase(s) unwrapped\n')
PYEOF
fi

PREPROC=$(python3 - "$SRC" <<'PYEOF'
import re, sys, subprocess

import shutil
PANDOC = shutil.which('pandoc') or 'pandoc'
md = open(sys.argv[1]).read()

def highlight(lang, code):
    fence = f'```{lang}\n{code}\n```' if lang else f'```\n{code}\n```'
    r = subprocess.run(
        [PANDOC, '--syntax-highlighting=tango', '-f', 'markdown', '-t', 'html'],
        input=fence, capture_output=True, text=True)
    return r.stdout.strip()

def convert_fence(m):
    return highlight(m.group(1), m.group(2))

def convert_html_block(m):
    return re.sub(r'```(\w*)\n(.*?)```', convert_fence, m.group(0), flags=re.DOTALL)

print(re.sub(r'<table[\s\S]*?</table>', convert_html_block, md))
PYEOF
)

{
  printf '%s\n' "$PAPER_CSS"
  printf '<script>\n'; cat "$PAPER_JS"; printf '\n</script>\n'
} > "$TMP/paper-head.html"

echo "$PREPROC" | pandoc - \
  -s \
  --syntax-highlighting=tango \
  --metadata title="Structured Binding Assignments" \
  --toc \
  -H "$TMP/paper-head.html" \
  -o "$PAPER"

# ---------------------------------------------------------------------------
# 3. Move the TOC to just after the paper metadata block
# ---------------------------------------------------------------------------

python3 - "$PAPER" <<'PYEOF'
import re, sys

path = sys.argv[1]
html = open(path).read()

toc_m = re.search(r'<nav id="TOC"[\s\S]*?</nav>', html)
if toc_m:
    toc = toc_m.group(0)
    if '<h2' not in toc:
        toc = re.sub(r'(<nav[^>]*>)', r'\1\n<h2>Contents</h2>', toc, count=1)
    h2_end  = toc.find('</h2>') + len('</h2>')
    nav_close = toc.rfind('</nav>')
    outer_ul_open  = toc.find('<ul>', h2_end)
    outer_ul_close = toc.rfind('</ul>', 0, nav_close)
    outer_ul_close_end = outer_ul_close + len('</ul>')
    inner_ul_open  = toc.find('<ul>', outer_ul_open + len('<ul>'))
    outer_li_close = toc.rfind('</li>', 0, outer_ul_close)
    if inner_ul_open != -1 and outer_li_close != -1:
        toc = toc[:outer_ul_open] + toc[inner_ul_open:outer_li_close] + toc[outer_ul_close_end:]
    html = html[:toc_m.start()] + html[toc_m.end():]
    h1_end = html.find('</h1>') + len('</h1>')
    h2_idx = html.find('<h2 ', h1_end)
    ul_end = html.rfind('</ul>', h1_end, h2_idx)
    if ul_end != -1:
        pos = ul_end + len('</ul>')
        html = html[:pos] + '\n' + toc + html[pos:]

open(path, 'w').write(html)
PYEOF

echo "paper   $PAPER"
