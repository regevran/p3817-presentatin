/* Cover-page behaviour: the title slide that sits on screen in the hall before
 * the talk starts.
 *
 * The cover is a door. Every navigation key — and a click anywhere — goes to
 * the paper. There is no "previous" from the first thing in the talk, so
 * splitting the keys into forward and back buys nothing, and a presenter who
 * reaches for the wrong one still lands where they were rather than losing
 * their place mid-talk.
 *
 * The position travels the same way it does for a deck: the paper sends
 * ?y=<scrollY>, and we fold it into the link. So stepping to the cover
 * mid-talk and back returns to the exact line rather than the top of the
 * paper. Opened cold — the normal case before the talk — there is no ?y= and
 * it simply lands at the top.
 *
 * The image is wrapped in a real <a>, so a click advances even with JS off.
 * This file only adds the ?y= hand-back and the keyboard.
 */
(function () {
  'use strict';

  /* Fold in the position the paper handed us, if it handed us one. A deck
     does the same thing with the same parameter; the cover is not a deck, but
     from the paper's side it behaves like one. */
  function target() {
    var link = document.querySelector('a.cover');
    var href = (link && link.getAttribute('href')) || 'p3817.html';
    var y;
    try { y = new URLSearchParams(location.search).get('y'); } catch (e) { return href; }
    if (y === null || !/^\d+$/.test(y)) return href;
    return href + '?y=' + y;
  }

  function advance() { location.href = target(); }

  document.addEventListener('keydown', function (e) {
    if (e.metaKey || e.ctrlKey || e.altKey) return;

    /* Deliberate navigation keys only — not "any key". This page sits
       unattended on a lectern for ten minutes while the hall fills up, and a
       stray keypress brushing the laptop must not make the title slide
       disappear. Everything here is something a clicker or a presenter
       actually sends. */
    switch (e.key) {
      case 'Escape':
        /* Under the Fullscreen API the browser consumes Escape to leave
           full-screen, and preventing that is not possible — so advancing as
           well would start the talk out of full-screen. Let this press be the
           exit only, and the next one advance. (F11-style full-screen is not
           affected: Escape does not leave it.) */
        if (document.fullscreenElement) return;
        e.preventDefault(); advance(); break;

      case ' ': case 'Enter':
      case 'ArrowRight': case 'ArrowDown': case 'ArrowLeft': case 'ArrowUp':
      case 'PageDown': case 'PageUp':
      case 'Backspace': case 'c': case 'C':
        e.preventDefault(); advance(); break;
    }
  });

  /* Left click only: modified and middle clicks still mean "open in a new
     tab", the same as they would on any other link. */
  document.addEventListener('click', function (e) {
    if (e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    e.preventDefault();
    advance();
  });
})();
