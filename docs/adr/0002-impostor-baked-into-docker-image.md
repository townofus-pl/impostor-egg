# Impostor and Reactor.Impostor ship inside our own Docker image, not through the egg install

The usual Pterodactyl pattern downloads the server in the egg's install script, so every update needs an egg import and a reinstall, and a reinstall overwrites `config.json`. Wings removes and recreates the container on every server start and pulls the image each time (`pterodactyl/wings`, `OnBeforeStart` and `ensureImageExists`). So `townofus-pl/impostor-egg` builds `ghcr.io/townofus-pl/impostor` with Impostor and `Reactor.Impostor.dll` inside, the egg only points at the image, and all config comes from `IMPOSTOR_*` environment variables. A merge to `main` pushes `:league`, and the next restart deploys it.

## Consequences

- A scheduled restart in Pterodactyl (daily at 06:00) deploys merged changes with no manual step. A manual restart deploys at once.
- The ghcr package must stay public, or Wings needs registry credentials.
- The image must follow the Pterodactyl yolk contract (user `container`, workdir `/home/container`, `STARTUP` entrypoint).
