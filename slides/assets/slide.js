/* Minimal slide runtime: keyboard navigation, hash routing, back-to-paper.
 *
 * Deliberately dependency-free and small so a deck is one self-contained
 * file that presents offline. If we later want fragments, speaker notes,
 * overview mode and PDF export, swap this file for reveal.js and leave the
 * slide sources untouched.
 */
(function () {
  'use strict';

  function init() {
    var slides = Array.prototype.slice.call(document.querySelectorAll('.slide'));
    if (!slides.length) return;

    var current = 0;

    function indexFromHash() {
      var m = /^#\/(\d+)$/.exec(location.hash);
      if (!m) return 0;
      var n = parseInt(m[1], 10) - 1;
      return (n >= 0 && n < slides.length) ? n : 0;
    }

    function show(i, record) {
      i = Math.max(0, Math.min(slides.length - 1, i));
      slides[current].classList.remove('active');
      slides[i].classList.add('active');
      current = i;

      /* replaceState, not pushState.
       *
       * pushState adds a history entry per slide, so the stack becomes
       *   paper -> deck#/1 -> deck#/2 -> deck#/3
       * and history.back() then walks back through the deck one slide at a
       * time instead of returning to the paper. Keeping the deck as a single
       * history entry is what makes the return work: the browser pops the
       * whole deck and restores the paper's scroll position.
       *
       * The hash still tracks the slide, so a slide stays directly linkable
       * and a reload lands on the same one. */
      var h = '#/' + (i + 1);
      if (record && location.hash !== h) {
        history.replaceState(null, '', h);
      }

      var counter = document.getElementById('slide-counter');
      if (counter) counter.textContent = (i + 1) + ' / ' + slides.length;
    }

    function next() { show(current + 1, true); }
    function prev() { show(current - 1, true); }

    document.addEventListener('keydown', function (e) {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      switch (e.key) {
        case 'ArrowRight': case 'ArrowDown': case ' ': case 'PageDown': case 'j':
          e.preventDefault(); next(); break;
        case 'ArrowLeft': case 'ArrowUp': case 'PageUp': case 'k':
          e.preventDefault(); prev(); break;
        case 'Home': e.preventDefault(); show(0, true); break;
        case 'End':  e.preventDefault(); show(slides.length - 1, true); break;
        case 'Escape': case 'Backspace': e.preventDefault(); leave(); break;
      }
    });

    // Click right half -> forward, left half -> back. Links keep working.
    document.addEventListener('click', function (e) {
      if (e.target.closest('a')) return;
      var half = document.documentElement.clientWidth / 2;
      show(e.clientX < half ? current - 1 : current + 1, true);
    });

    // Only reachable if the deck was opened directly (no referrer) and the
    // user moves through same-document hash entries.
    window.addEventListener('popstate', function () { show(indexFromHash(), false); });

    /* "Back to the paper" — wired to the link, Esc and Backspace.
     *
     * The href points at the section anchor, so a bookmarked or
     * directly-opened deck works with no JS at all. When the paper sent us
     * here it also passed the position it wants back as ?y=..., and we fold
     * that into the href so the return lands on the exact line rather than
     * at the top of the section.
     *
     * This travels in the URL rather than through history.back() because
     * history and referrer behave differently under file://, and presenting
     * from a local file is the normal case. */
    (function inheritReturnPos() {
      var y;
      try { y = new URLSearchParams(location.search).get('y'); } catch (e) { return; }
      if (y === null || !/^\d+$/.test(y)) return;
      var link = document.querySelector('.back-to-paper');
      if (!link) return;
      var href = link.getAttribute('href') || '';
      var hi = href.indexOf('#');
      if (hi !== -1) href = href.slice(0, hi);
      link.setAttribute('href', href + '?y=' + y);
    })();

    function leave() {
      var link = document.querySelector('.back-to-paper');
      if (link) location.href = link.getAttribute('href');
    }

    var back = document.querySelector('.back-to-paper');
    if (back) {
      back.addEventListener('click', function (e) {
        e.preventDefault();
        leave();
      });
    }

    var counterEl = document.createElement('div');
    counterEl.id = 'slide-counter';
    document.body.appendChild(counterEl);

    show(indexFromHash(), false);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
