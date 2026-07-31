# Extension Name UI

A React + Vite single-page app on [react-sbb-polarion](https://github.com/grigoriev/react-sbb-polarion)
(RSP). It replaces the legacy `about.jsp`, which was a two-line wrapper around generic's
server-rendered About page. The whole page comes from RSP's shared `About` component; this app only
feeds it the extension's REST hook, icon and REST-API URL.

> **Replace `src/assets/app-icon.svg`.** It ships as the neutral SBB card - the red header band and no
> product glyph - which is what an extension without an icon of its own uses. It is a binary asset, so
> the search-and-replace that turns this template into a real extension does not touch it, and the only
> test that looks at it just asserts that an `.app-icon` element exists. After replacing it, regenerate
> the About reference screenshot: `npm run test:update:docker`.

## Feature routing

There is one `index.html` / bundle. The page to render is chosen from the `feature` query parameter:

- `/` (no param) renders a development landing page listing every feature.
- `/?feature=about` renders the About page.

Features are declared in [`src/features.tsx`](src/features.tsx). Add a page component under
`src/pages/`, register it there, and it appears on the landing page automatically. The ids must stay
in sync with the `pageUrl`s in `src/main/resources/META-INF/hivemodule.xml` — a mismatch shows up as a
blank page in Polarion and no test catches it.

## Local development

No Polarion restart is needed to develop the UI:

```bash
cd ui
cp .env.local.template .env.local   # optional: VITE_BASE_URL / VITE_BEARER_TOKEN for real REST calls
npm install
npm run dev                          # http://localhost:5173/
```

REST calls are proxied to the Polarion instance in `VITE_BASE_URL`; a personal access token in
`VITE_BEARER_TOKEN` switches `useRemote` from the session `/internal` endpoints to the token `/api`
ones.

## Running the tests

**One command, locally and in CI: `npm run test:coverage:docker`.** It runs the full suite (behavior +
visual regression) plus the 80% istanbul coverage gate inside the pinned Playwright Docker image,
which is what the Maven `test` phase and the pre-commit hook execute. Docker must be running.

```bash
npm run test:coverage:docker   # the canonical run: full suite + coverage gate, in the pinned image
npm run test:coverage          # fast local loop: behavior only + the gate, no Docker, no pixels
npm run test:update:docker     # regenerate the committed reference PNGs after an intentional UI change
```

> Do **not** run `npm run test:coverage:full` directly outside a container. It is the inner command the
> Docker wrapper invokes; the visual suites detect that they are not in the reference environment and
> skip themselves, so a run there proves nothing about the screenshots.

## Formatting & linting

```bash
npm run format          # Prettier: format every file in place
npm run format:check    # Prettier: check only (what pre-commit / CI runs)
npm run lint            # ESLint: report problems
npm run lint:fix        # ESLint: auto-fix what it can
```

The repo's pre-commit hooks run `format:check`, `lint` and the dockerized coverage suite on any change
under `ui/`. They are check-only and never modify your files.

## Production build

`npm run build` emits the bundle to `ui/dist/app` with base path
`/polarion/extension-name-app/ui/app/`. The Maven build (frontend-maven-plugin +
maven-resources-plugin) runs this automatically and copies the bundle into
`src/main/resources/webapp/extension-name-app/app`, where `ExtensionNameAppServlet` serves it at
`/polarion/extension-name-app/ui/app/index.html`.
