# README

Web application to manage your epub files. It's mainly focused on books from series.

## Features

- Upload multiple books in one time
- Fetch metadata from epub file
- Update book and their epub file
- Rate and annotate series

## Self-hosting

See [`compose.example.yml`](compose.example.yml) for a Docker Compose setup and [`.env.example`](.env.example) for the available environment variables (master key, hostname, SMTP, tuning). Copy both, fill in `.env`, and `docker compose up -d --build`.

Bookshelf processes uploaded EPUBs in a background job (Solid Queue), so **something has to run the worker** — just serving the web image is not enough. The example keeps it simple and runs the worker inside the web process via Solid Queue's Puma plugin (`SOLID_QUEUE_IN_PUMA=1`), which is fine for a personal instance.

If you expect heavier usage, run the worker as a dedicated container instead so large uploads don't compete with web requests. The example file documents that alternative in a comment block; both containers just need to share the same `storage/` volume, since all SQLite databases (including the job queue) live there.

## Development

```sh
bin/reset
bin/dev
```
