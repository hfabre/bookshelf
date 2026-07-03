## Cleanup

## Missing feature

## Release

- Add github action to push docker image to github registry when releasing (pushing a tag)

## Maybe

- Add an OPDS catalog feed so e-reader apps (KOReader, Moon+ Reader, etc.) can browse the library and download books directly, instead of manual download + transfer. Maps onto existing models and the public-library/sharing plumbing.
- Add a Discord webhook to alert on failed epub processing (avoids configuring/paying for an SMTP). Hook it where `EpubProcessorJob` sets a book to `failed` (book-level failure, not visible in Mission Control), so the alert carries the reason. Keep it a small `DiscordNotifier` service, only active when `DISCORD_WEBHOOK_URL` is present.
- Series gap detection: using `serie_index`, flag missing volumes in a series (e.g. have 1, 2, 4 → missing 3). Later this can feed the Anna's Archive request feature to request the missing volume.
- Add a button on book to gather metadata from google api (should show an intermediate step to see the data which will be imported)
- Add a request book page to request book from [annas archive](https://annas-archive.org/) api (needs an api key), the link to the page should be shown only if key is present
