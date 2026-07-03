# Bookshelf

A self-hosted library for your EPUB collection, built around the way books actually come — in series. Drop in your files, and Bookshelf reads the metadata out of them, groups the books by series and author, and lets you tidy up the details from a web UI. Edits are written back into the EPUB itself, so the files stay correct wherever you read them.

## Features

- **Bulk upload** — add a whole folder of EPUBs at once; metadata is pulled from each file in the background.
- **Edit that sticks** — fix titles, authors, covers and more; changes are saved back into the EPUB, not just the database.
- **Organised by series** — books are grouped into series and by author, with ratings and notes.
- **Search** — full-text search across your series and authors.
- **Share a shelf** — expose your library as a read-only public page for others to browse.

## Self-hosting

See [`compose.example.yml`](compose.example.yml) for a Docker Compose setup and [`.env.example`](.env.example) for the available environment variables (master key, hostname, SMTP, tuning). Copy both, fill in `.env`, and `docker compose up -d --build`.

Bookshelf processes uploaded EPUBs in a background job (Solid Queue), so **something has to run the worker** — just serving the web image is not enough. The example keeps it simple and runs the worker inside the web process via Solid Queue's Puma plugin (`SOLID_QUEUE_IN_PUMA=1`), which is fine for a personal instance.

If you expect heavier usage, run the worker as a dedicated container instead so large uploads don't compete with web requests. The example file documents that alternative in a comment block; both containers just need to share the same `storage/` volume, since all SQLite databases (including the job queue) live there.

## Development

```sh
bin/reset
bin/dev
```
