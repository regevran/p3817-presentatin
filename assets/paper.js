/* Paper-side behaviour for the talk.
 *
 * Three jobs:
 *
 *  1. Remember where the reader was when they jump into a deck, and hand that
 *     position to the deck. The deck gives it back on the way out, so the
 *     return lands on the exact line rather than at the top of the section.
 *
 *     This travels in the URL (?y=1234) rather than through history.back(),
 *     because browsers do not send a referrer for file:// navigations — so a
 *     history/referrer-based return quietly degrades when you just open the
 *     built HTML from disk, which is exactly how you present from a laptop.
 *
 *  2. Restore that position when handed back.
 *
 *  3. "Presentation mode" — the paper renders at 16px with ~200-character
 *     lines, fine on a desk and unreadable from the back of a hall. Press "p"
 *     to scale the type up and pull prose in to a readable measure. Off by
 *     default, so the page still looks exactly like a WG21 paper.
 */
(function () {
  'use strict';

  var MODE_KEY = 'p3817.present';
  var POS_KEY = 'y';

  function withPos(href, y) {
    var hash = '';
    var hi = href.indexOf('#');
    if (hi !== -1) { hash = href.slice(hi); href = href.slice(0, hi); }
    var sep = href.indexOf('?') === -1 ? '?' : '&';
    // The hash is dropped deliberately: with an explicit position the anchor
    // scroll only competes with ours, and the two can land in either order.
    return href + sep + POS_KEY + '=' + y;
  }

  function rememberedPos() {
    var raw;
    try { raw = new URLSearchParams(location.search).get(POS_KEY); }
    catch (e) { return null; }
    if (raw === null) return null;
    var n = parseInt(raw, 10);
    return isNaN(n) ? null : n;
  }

  /* --- presentation mode ------------------------------------------------ */

  function apply(on) {
    document.documentElement.classList.toggle('present', on);
  }

  function stored() {
    try { return sessionStorage.getItem(MODE_KEY) === '1'; } catch (e) { return false; }
  }

  function remember(on) {
    try { sessionStorage.setItem(MODE_KEY, on ? '1' : '0'); } catch (e) { /* private mode */ }
  }

  function init() {
    apply(stored());

    document.addEventListener('keydown', function (e) {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.key !== 'p' && e.key !== 'P') return;
      var tag = (document.activeElement || {}).tagName;
      if (tag === 'INPUT' || tag === 'TEXTAREA') return;

      var on = !document.documentElement.classList.contains('present');
      apply(on);
      remember(on);
    });

    /* Carry the current position into the deck we are about to open. */
    document.addEventListener('click', function (e) {
      var link = e.target.closest && e.target.closest('a.elab');
      if (!link) return;
      var href = link.getAttribute('href');
      if (!href) return;
      e.preventDefault();
      location.href = withPos(href, Math.round(window.scrollY));
    });

    /* Restore a position handed back by a deck. The browser may still be
       settling its own fragment/scroll restoration, so do it after load. */
    var y = rememberedPos();
    if (y !== null) {
      if ('scrollRestoration' in history) history.scrollRestoration = 'manual';
      var jump = function () { window.scrollTo(0, y); };
      if (document.readyState === 'complete') requestAnimationFrame(jump);
      else window.addEventListener('load', function () { requestAnimationFrame(jump); });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
