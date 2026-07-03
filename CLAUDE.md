# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Bookshelf is a Rails 8.1 (Ruby 3.3.5) web app to manage EPUB files, focused on books grouped into series. Users upload EPUBs, metadata is extracted from the files, and books can be edited (which writes changes back into the EPUB), rated, and shared via public libraries.

## Commands

```sh
bin/dev                         # run the app (web + tailwind watch + solid_queue) via Procfile.dev
bin/setup                       # install deps + prepare db (add --skip-server to not boot)

bin/rails test                  # run the full test suite (parallelized above 50 tests)
bin/rails test path/to/x_test.rb        # single file
bin/rails test path/to/x_test.rb:NN     # single test at line NN
bin/rails test:system           # system tests (Capybara)

bin/rubocop                     # lint (rubocop-rails-omakase)
bin/brakeman                    # security scan
bin/ci                          # everything CI runs: setup, rubocop, importmap audit, brakeman, tests, system tests, seeds
```

## Architecture

**EPUB read/write is the core.** `lib/bs_epub/` is a self-contained library (`BsEpub::Epub`) that parses and mutates EPUB zip archives with Nokogiri. It operates entirely **in memory** — construct it from bytes (`BsEpub::Epub.new(file_bytes)`, which uses `Zip::File.open_buffer`), mutate, and read `current_buffer.string` back. It never touches the file on disk. It's already thoroughly tested in `test/lib/bs_epub/`; **do not re-test it through higher layers** — stub it instead.

**Book content lives in the database, not on disk.** `books.epub_content` is a binary column holding the whole EPUB; covers are stored as `cover_bytes`/`cover_type`. `Book#epub` builds a `BsEpub::Epub` from that column.

**Business logic lives in service objects** under `app/services/`, namespaced per model (`BookServices::`, `SerieServices::`, `AuthorServices::`). Convention: `Service.new(subject).call(args)` returning a result Hash `{ success:, ... }` for the merge services. Key flows:
- `BookServices::SyncFromEpub` — reads EPUB metadata → book attributes + finds/creates serie & authors (used by the upload job).
- `BookServices::SyncToEpub` — writes book attributes/cover back into the EPUB buffer and persists it.
- `BookServices::UpdateAndSync` — the edit path: updates the book, then `SyncToEpub`.
- `*Services::MergeService` / `SimilarityService` — merge records and find similar ones.

**Upload is async.** `BooksController#upload` creates `pending` books and enqueues `EpubProcessorJob`, which runs `SyncFromEpub` and flips `processing_status` (`pending`→`processing`→`completed`/`failed`). Jobs run on **Solid Queue** (`bin/jobs`); the test env overrides the adapter to `:test`.

**Full-text search uses SQLite FTS5.** `series_fts` / `authors_fts` are virtual tables kept in sync via model `after_*_commit` callbacks. The `SimilarityService`s query them with `MATCH` (name tokens joined by `OR`). Because fixtures bypass callbacks, tests must call `Serie.rebuild_search_index` / `Author.rebuild_search_index` before querying. Schema is dumped as `:ruby` (schema.rb) specifically so these virtual tables survive.

**`Serie` is deliberately singular** (model `Serie`, table `series`). Do NOT rename it to `Series`. The inflector is taught the irregular pair in `config/initializers/inflections.rb` (`inflect.irregular "serie", "series"`), so route/path helpers are `serie_path`, `edit_serie_path`, `series_path` (index), etc. — standard `action_singular_model_path` naming.

**Public libraries / sharing.** A user with `public_library: true` exposes read-only browsing via `LibrariesController`, which re-renders the normal `books`/`series`/`authors` views in "library mode" (see `browsing_other_library?` and the `*_path` helpers in `ApplicationHelper`). Admin-only actions (`edit`/`update` on series/authors, all of `UsersController`) are gated by `require_admin`.

**Auth** is the stock Rails 8 generated authentication (cookie session → `Session` model → `Current.session`), not Devise. `Current`/`Session` are framework-generated and intentionally untested.

## Testing conventions

Minitest **spec syntax** (`describe`/`it`/`let`/`subject`, `_(x).must_equal`) with fixtures. Prefer **fewer tests that cover real behavior** over many shallow ones.

- **Service/PORO tests need a class wrapper**: `class Foo::BarTest < ActiveSupport::TestCase` then use the spec DSL inside. A bare top-level `describe SomeService` gets `Minitest::Spec` as its base and loses fixtures. Model tests (`describe Book`) are fine bare — minitest-rails maps AR models to `ActiveSupport::TestCase`.
- **Controller tests**: assert the controller *calls the service* and the resulting redirect/response; leave the logic to the service's own test. Stub services with `Service.stub(:new, ->(*) { mock })` where `mock` is a `Minitest::Mock` (wrap in a lambda — a Mock responds to `:call`, so `stub(:new, mock)` would be misinterpreted). Use the block form `mock.expect(:call, ret) { true }` when the method takes args.
- Sign in with `sign_in_as(user)` (`test/test_helpers/session_test_helper.rb`).
- File uploads use `fixture_file_upload("name", "mime")` (enabled globally in `test_helper.rb`); real fixtures in `test/fixtures/files/`.
- `users(:admin)` is the admin fixture; `users(:one)` owns most fixtures and is `public_library: true`.

## Deploy

Designed to be self-hosted via **Docker Compose** (deliberately not Kamal); see `compose.example.yml`. The app is meant to run behind a **TLS-terminating reverse proxy** and trusts the forwarded proto, so `config.assume_ssl`/`config.force_ssl` are enabled in production. In-container, **Thruster** (`bin/thrust`) adds compression + X-Sendfile in front of Puma. Persistence is **SQLite** with **Solid Queue/Cache/Cable** (jobs via `bin/jobs`; can also run inside Puma with `SOLID_QUEUE_IN_PUMA`).

Release flow: the `publish` job in `.github/workflows/ci.yml` builds the image from the `Dockerfile` and pushes it to GHCR once the rest of CI is green — a version tag `X.Y.Z` publishes `:X.Y.Z`/`:X.Y`/`:latest`, and every push to `main` publishes `:nightly`. Deploy is bumping the image tag in the compose file and `docker compose pull && up -d --wait`.
