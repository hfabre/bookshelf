# README

Web application to manage your epub files. It's mainly focused on books from series.

## Features

- Upload multiple books in one time
- Fetch metadata from epub file
- Update book and their epub file
- Rate and annotate series


```sh
#!/usr/bin/env sh

if ! gem list foreman -i --silent; then
  echo "Installing foreman..."
  gem install foreman
fi

# Default to port 3000 if not specified
export PORT="${PORT:-3000}"

# Let the debug gem allow remote connections,
# but avoid loading until `debugger` is called
export RUBY_DEBUG_OPEN="true"
export RUBY_DEBUG_LAZY="true"

exec foreman start -f Procfile.dev "$@"
```
