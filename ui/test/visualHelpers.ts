// Shared by the visual suites: what a page has to have finished before it is worth photographing.
import { userEvent } from 'vitest/browser';

/**
 * Moves the pointer onto a spot of its own.
 *
 * The mouse position survives a test, and a browser-mode file, since all of them run in one page - so
 * whatever the pointer last touched stays hovered while the next file takes its screenshot. The controls
 * of these pages do react: the `sbb-btn` and dropdown-trigger rules paint a shadow, and a reference that
 * carries one disagrees with every run in which the pointer happened to rest elsewhere.
 *
 * The spot is `position: fixed` in the corner and above everything, so it has no styling of its own and
 * nothing can intercept the hover. `force` skips the actionability check for the sake of the captures
 * taken inside a modal `<dialog>`, whose backdrop sits above every z-index.
 */
export async function parkPointer(): Promise<void> {
  const spot = document.createElement('div');
  spot.style.cssText = 'position:fixed;right:0;bottom:0;width:4px;height:4px;z-index:2147483647;';
  document.body.appendChild(spot);
  try {
    await userEvent.hover(spot, { force: true });
  } finally {
    spot.remove();
  }
}

/**
 * Everything a page has to have finished before it is worth photographing: its fonts settled, the pointer
 * off any control, the hover styling that pointer leaves behind faded out, and a frame painted. Call it as
 * the LAST thing before the capture, once the viewport is final. The antialiasing, the fourth cause, is
 * pinned once for the whole file in test/setup.ts.
 *
 * @param park whether to move the pointer away, for the captures that aim it somewhere themselves.
 */
export async function settleBeforeCapture(park = true): Promise<void> {
  await document.fonts.ready;
  if (park) {
    await parkPointer();
  }
  // The hover styling of whatever the pointer leaves behind fades over `transition: box-shadow .15s`, and
  // a capture in the middle of that fade is a reference that only sometimes reproduces.
  await new Promise((resolve) => setTimeout(resolve, 200));
  // Two frames: the first lets the style changes above be laid out, the second lets them be painted.
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve(undefined))));
}
