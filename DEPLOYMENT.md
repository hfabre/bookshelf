# Deployment

> Note for later: this file is a scratch note to append into `CLAUDE.md` once it's generated. Kamal is **not** used — the repo's `config/deploy.yml` and Kamal setup can be removed.

## Flow

1. Push a new git tag.
2. A GitHub Action builds the Docker image and pushes it to the registry (GitHub Container Registry). _(see roadmap "Release")_
3. On the server, deploy is a manual/scripted step:
   - `docker compose stop` the service
   - pull the new image
   - `docker compose up` again

## SSL / reverse proxy

The server sits behind the **godoxy** reverse proxy, which terminates TLS and keeps the SSL certificate up to date. The app itself does not manage certificates.

- Because TLS is terminated at the proxy, set `config.assume_ssl = true` and `config.force_ssl = true` in `config/environments/production.rb` so Rails treats requests as HTTPS (secure cookies, HSTS) while trusting the proxy's forwarded proto. _(see roadmap "Security")_

## TODO

- Run DB migrations on deploy. Likely add a migration step to the container startup (e.g. `bin/rails db:prepare` in the Dockerfile entrypoint / compose command) so the schema is up to date before the app boots.
