# Verifying UI changes locally (headless browser)

How to boot the app and drive it with a headless browser to visually confirm a
change. Written for a fresh Claude session so it doesn't have to rediscover the
setup.

## App facts

- Rails 8, SQLite dev DB (`storage/development.sqlite3`).
- Dev login: `test@example.org` / `password` (admin). Login is a `resource
  :session` → `GET /session/new`, `POST /session`.
- Tailwind v4. CSS is compiled to `app/assets/builds/tailwind.css`.

## Boot a stable server

`bin/dev` runs `tailwindcss:watch` under foreman, but in a headless/non-tty
shell that watch process exits immediately and foreman then tears everything
down. So don't rely on `bin/dev` for automation. Instead:

```bash
bin/rails tailwindcss:build          # one-shot CSS compile
PORT=3009 bin/rails server -p 3009 -b 127.0.0.1 > /tmp/server.log 2>&1 &
```

Use a non-default port (e.g. **3009**) so it never collides with the user's own
`bin/dev` on 3000.

## Drive it (puppeteer-core + the installed Chrome)

No system Playwright. Chrome.app is installed. Node is old (v16), so use
`puppeteer-core@21` (no browser download — points at the installed Chrome):

```bash
cd <scratchpad> && npm init -y && npm install puppeteer-core@21
```

```js
const puppeteer = require('puppeteer-core');
const browser = await puppeteer.launch({
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: 'new',
  args: ['--no-sandbox', '--window-size=1400,900'],
});
const page = await browser.newPage();
await page.setViewport({ width: 1400, height: 900 });

// login
await page.goto('http://127.0.0.1:3009/session/new', { waitUntil: 'networkidle0' });
await page.type('input[name="email_address"]', 'test@example.org');
await page.type('input[name="password"]', 'password');
await Promise.all([page.waitForNavigation({ waitUntil: 'networkidle0' }), page.keyboard.press('Enter')]);

// ... navigate, screenshot, and measure geometry with page.evaluate(getBoundingClientRect)
await browser.close();
```

Then Read the PNG to look at it. For layout bugs, also assert geometry
numerically in `page.evaluate` (element `x`/`width`/`top`) — it's more objective
than eyeballing and makes before/after obvious.

**Always report the full absolute path of every verification screenshot** in
your reply so the user can open and double-check them. Don't just describe or
inline them — give the path.

## Triggering a flash message

The reported flash-layout bugs need a flash present on a page:

- **Any flash quickly:** submit the upload form with no file selected —
  `document.querySelector('form[action*="upload"]').requestSubmit()` — the
  controller redirects back with an alert ("No valid EPUB files were found.").
- **A success/notice flash:** upload a real `.epub`, or perform an author/series
  merge.

## Reproduce-the-bug probe

Views hot-reload in dev, so to confirm a fix is what changed things: `git stash`
the view, re-run the driver (no reboot needed), compare geometry, then
`git stash pop`.

## Cleanup (always)

```bash
kill <server_pid>; lsof -ti :3009 | xargs kill -9 2>/dev/null
```

Leave port 3009 free so the user's own `bin/dev` won't hit a conflict.
