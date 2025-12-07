CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email_address" varchar NOT NULL, "password_digest" varchar NOT NULL, "admin" boolean DEFAULT FALSE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "public_library" boolean DEFAULT FALSE NOT NULL);
CREATE UNIQUE INDEX "index_users_on_email_address" ON "users" ("email_address");
CREATE TABLE IF NOT EXISTS "sessions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "ip_address" varchar, "user_agent" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_758836b4f0"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_sessions_on_user_id" ON "sessions" ("user_id");
CREATE TABLE IF NOT EXISTS "series" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "user_id" integer NOT NULL, "completion_state" varchar, "reading_state" varchar, "rating" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_2de52c31fb"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_series_on_user_id" ON "series" ("user_id");
CREATE UNIQUE INDEX "index_series_on_user_id_and_name" ON "series" ("user_id", "name");
CREATE TABLE IF NOT EXISTS "books" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar, "description" text, "language" varchar, "date" date, "publisher" varchar, "serie_id" integer, "user_id" integer NOT NULL, "serie_index" integer DEFAULT 1, "epub_content" blob, "filename" varchar, "cover_bytes" blob, "cover_type" varchar, "processing_status" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_e0646f0d27"
FOREIGN KEY ("serie_id")
  REFERENCES "series" ("id")
, CONSTRAINT "fk_rails_bc582ddd02"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_books_on_serie_id" ON "books" ("serie_id");
CREATE INDEX "index_books_on_user_id" ON "books" ("user_id");
CREATE UNIQUE INDEX "index_books_on_user_id_and_serie_id_and_serie_index" ON "books" ("user_id", "serie_id", "serie_index");
CREATE TABLE IF NOT EXISTS "authors_books" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "book_id" integer NOT NULL, "author_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_f7acfea2b6"
FOREIGN KEY ("book_id")
  REFERENCES "books" ("id")
, CONSTRAINT "fk_rails_d4a76af72d"
FOREIGN KEY ("author_id")
  REFERENCES "authors" ("id")
);
CREATE INDEX "index_authors_books_on_book_id" ON "authors_books" ("book_id");
CREATE INDEX "index_authors_books_on_author_id" ON "authors_books" ("author_id");
CREATE UNIQUE INDEX "index_authors_books_on_book_id_and_author_id" ON "authors_books" ("book_id", "author_id");
CREATE TABLE IF NOT EXISTS "authors" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "user_id" integer NOT NULL, CONSTRAINT "fk_rails_46e884287b"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_authors_on_user_id" ON "authors" ("user_id");
CREATE UNIQUE INDEX "index_authors_on_user_id_and_name" ON "authors" ("user_id", "name");
CREATE VIRTUAL TABLE authors_fts USING fts5 (name, user_id UNINDEXED)
/* authors_fts(name,user_id) */;
CREATE TABLE IF NOT EXISTS 'authors_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'authors_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'authors_fts_content'(id INTEGER PRIMARY KEY, c0, c1);
CREATE TABLE IF NOT EXISTS 'authors_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'authors_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
INSERT INTO "schema_migrations" (version) VALUES
('20251203204351'),
('20251203204350'),
('20251203204349'),
('20251129000000'),
('20251121200000'),
('20251121194327'),
('20250607153903'),
('20250607153715'),
('20250607153614'),
('20250607153316'),
('20250607153004'),
('20250607153003');

