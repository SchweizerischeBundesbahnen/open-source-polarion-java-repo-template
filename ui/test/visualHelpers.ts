// Shared by the visual suites: what a page has to have finished before it is worth photographing.
import { userEvent } from 'vitest/browser';

/** The parked pointer's resting place. Created once per file and kept in the DOM (see `parkPointer`). */
let parkingSpot: HTMLElement | undefined;

/**
 * Moves the pointer onto a spot of its own, and leaves it there.
 *
 * The mouse position survives a test, and a browser-mode file, since all of them run in one page - so
 * whatever the pointer last touched stays hovered while the next file takes its screenshot, and the
 * controls of these pages do react.
 *
 * The spot is NOT removed afterwards. Blink re-runs the hover hit test at the last known pointer
 * position whenever the hovered node leaves the DOM, so removing it would hand the hover straight to
 * whatever sits in that corner - and the settle that follows would then be long enough to fade that
 * element's shadow IN rather than out. It paints nothing (no background, no border), so it cannot show
 * up in a capture; it is `position: fixed` in the corner, above everything, and transparent to the
 * pointer's own hit testing only after the hover has landed on it.
 */
export async function parkPointer(): Promise<void> {
  if (!parkingSpot) {
    parkingSpot = document.createElement('div');
    parkingSpot.dataset.visualParkingSpot = '';
    parkingSpot.style.cssText = 'position:fixed;right:0;bottom:0;width:4px;height:4px;z-index:2147483647;';
    document.body.appendChild(parkingSpot);
  }
  // `force` skips the actionability check, which a modal <dialog> would otherwise fail: its ::backdrop
  // sits in the top layer, above every z-index. The pointer still moves, which is all this needs.
  await userEvent.hover(parkingSpot, { force: true });
}

/**
 * Waits for what changes layout, BEFORE a caller measures the element it is about to capture.
 *
 * Call it before reading `scrollHeight` to size the viewport: a height measured while a font is still
 * loading sizes the whole capture from a layout that has not settled, and `settleBeforeCapture` cannot
 * repair that afterwards - by then the viewport is already wrong.
 */
export async function settleLayout(): Promise<void> {
  await document.fonts.ready;
  await frame();
}

/**
 * Everything a page has to have finished before it is worth photographing: the fonts settled, the
 * pointer parked off any control, and a frame painted. Call it as the LAST thing before the capture,
 * once the viewport is final; call `settleLayout` before the measurement that sizes the viewport.
 *
 * Transitions and animations are off for the whole file (see test/setup.ts), so there is nothing left
 * to outrun with a sleep here.
 *
 * @param park whether to move the pointer away, for the captures that aim it somewhere themselves.
 */
export async function settleBeforeCapture(park = true): Promise<void> {
  await document.fonts.ready;
  if (park) {
    await parkPointer();
  }
  await frame();
  assertNotResampled();
}

/** Two frames: the first lets the style changes be laid out, the second lets them be painted. */
const frame = (): Promise<void> =>
  new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve())));

/**
 * Fails the capture if Vitest had to scale the test iframe to fit the browser window.
 *
 * The window is sized in vitest.config.ts to be larger than every viewport the suites ask for, but the
 * viewports are computed from page content, so a UI change can outgrow it without touching that file.
 * The reference would then be silently resampled, which looks exactly like a legitimate one. This turns
 * that into a failure that names the fix.
 */
function assertNotResampled(): void {
  const frameElement = window.frameElement as HTMLElement | null;
  if (!frameElement) {
    return;
  }
  const rendered = frameElement.getBoundingClientRect().width;
  const requested = window.innerWidth;
  if (rendered > 0 && Math.abs(rendered - requested) > 1) {
    throw new Error(
      `The capture would be resampled: the test viewport is ${requested}px wide but is rendered at ` +
        `${Math.round(rendered)}px. Raise contextOptions.viewport in vitest.config.ts above every ` +
        `viewport this suite asks for.`,
    );
  }
}
