## Cleanup

- See if we can cleanup BooksController#upload
- Clean up the `application.html.erb` layout structure. The `<body>` tag sits mid-document (after the header/sidebar) and the sidebar's outer `<div class="flex">` is intentionally left unclosed to wrap the content column. It works but is invalid/confusing HTML; restructure so `<body>` wraps everything and the sidebar + content column are proper, explicitly-closed flex children.
- Add tests (minitest spec syntaxe / fixtures) should be concise and precise also should avoid testing epub library through service test as it is already tested (i prefere having fewer tests but covering everything than having ton of tests testing nothing or the same thing). Controller test should test we call the service and test redirect or error but let the logic test to the service called, unless controller implement logic, in this case propose to extract the logic to a service)
- Translate all texts (i don't mean really translate keep it english but use I18n)
- Double check if we can clean be_epub


## Missing feature

- Add an admin view listing books with `failed` processing status, each with a link to download the original file and, if possible, a link to the job (Mission Control) or at least the stored backtrace/error. Requires persisting the failure reason/backtrace on the book when `EpubProcessorJob` fails.
- Add filters to the book index (currently only search-by-title). Most useful: filter for books with no series and/or no author assigned, to clean up after a bulk upload.

## Release

- Add github actions to run tests on every push
- Add github action to push docker image to github registry when releasing (pushing a tag)

## Security

_Checked with brakeman (clean) + manual review. Good already: all record lookups are scoped through `current_user` (no IDOR), views escape epub metadata (no stored XSS), downloads are user-scoped, public-library access is gated, login is rate-limited, passwords use bcrypt. Concrete items below:_

- Enable SSL in production. `config.force_ssl` (and likely `config.assume_ssl`, since the Kamal/Thruster proxy terminates TLS) are commented out in `config/environments/production.rb`. The proxy serves HTTPS (`deploy.yml` `ssl: true`) but the app doesn't force it or set HSTS, and the session cookie is `httponly`/`same_site: :lax` but NOT `secure`. Enabling `force_ssl` fixes all of that at once. Highest priority.
- Public library index leaks email addresses. `libraries/index.html.erb` shows each sharing user's `email_address` as the library title, on a page anyone can view. Consider a display name / username instead of the raw email.
- Harden upload file-type validation. `BooksController#upload` trusts the client-provided `content_type` / `.epub` extension. Low risk with trusted users (a bad file just fails processing), but could validate magic bytes with `marcel` (already a dependency).
- `config.action_mailer.default_url_options` is still `host: "example.com"`. Set the real host before relying on any mailer link (tied to the boilerplate password-reset flow).

## Maybe

- Add an OPDS catalog feed so e-reader apps (KOReader, Moon+ Reader, etc.) can browse the library and download books directly, instead of manual download + transfer. Maps onto existing models and the public-library/sharing plumbing.
- Add a Discord webhook to alert on failed epub processing (avoids configuring/paying for an SMTP). Hook it where `EpubProcessorJob` sets a book to `failed` (book-level failure, not visible in Mission Control), so the alert carries the reason. Keep it a small `DiscordNotifier` service, only active when `DISCORD_WEBHOOK_URL` is present.
- Series gap detection: using `serie_index`, flag missing volumes in a series (e.g. have 1, 2, 4 → missing 3). Later this can feed the Anna's Archive request feature to request the missing volume.
- Add a button on book to gather metadata from google api (should show an intermediate step to see the data which will be imported)
- Add a request book page to request book from [annas archive](https://annas-archive.org/) api (needs an api key), the link to the page should be shown only if key is present
