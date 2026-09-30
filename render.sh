#!/usr/bin/env bash
# Build the P3817 conference-talk materials.
#
#   dist/p3817.html           the paper, with clickable highlight phrases
#   dist/slides/<name>.html   self-contained slide decks (CSS + JS embedded)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./render.sh [OUTDIR] [--submission]

Builds the paper and the slide decks into OUTDIR (default: ./dist).

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
  slides/*.md               slide sources, one file per topic cluster
  slides/assets/slide.css   deck styling   (embedded into each deck)
  slides/assets/slide.js    keyboard nav   (embedded into each deck)

Options:
  --submission   Unwrap every highlighted phrase back to plain text, for a
                 clean paper to hand to WG21. Slides are still built.
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

mkdir -p "$SLIDES_OUT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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
for md in "$SLIDES_SRC"/*.md; do
  name="$(basename "$md" .md)"
  pandoc "$md" \
    -s \
    --metadata title="P3817 — $name" \
    --syntax-highlighting=breezedark \
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
  #references-table                              { width: auto; }
  #references-table td, #references-table code    { white-space: nowrap; }
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
