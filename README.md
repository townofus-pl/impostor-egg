# impostor-egg

The Among Us server for Drama Afera league matches: [Impostor](https://github.com/Impostor/Impostor) with the [Reactor.Impostor](https://github.com/NuclearPowered/Reactor.Impostor) plugin, packed as a Pterodactyl egg.

- Image: `ghcr.io/townofus-pl/impostor:league`
- Egg: [`egg-impostor.json`](egg-impostor.json)
- Pinned versions: the `ARG` lines at the top of the [`Dockerfile`](Dockerfile)

## How it works

Impostor and the plugin are inside the image. The egg downloads nothing. Wings removes and recreates the container on every server start, and it pulls the image each time. So a restart deploys the latest `:league` build. See [ADR 0002](docs/adr/0002-impostor-baked-into-docker-image.md).

All config comes from `IMPOSTOR_*` environment variables, so a reinstall overwrites nothing:

| Setting | Where |
|---|---|
| Game port (UDP) | primary allocation |
| HTTP matchmaker port | `HTTP_PORT` variable, second allocation |
| Public IP | `PUBLIC_IP` variable, or the primary allocation IP when empty |
| AntiCheat | fixed in the `Dockerfile` ([ADR 0001](docs/adr/0001-league-server-anticheat-partly-off.md)) |

Among Us accepts only an HTTPS matchmaker, and Impostor has no TLS. Put a reverse proxy with TLS on port 443 in front of `HTTP_PORT`. Game traffic goes direct to the game port over UDP.

## Install on a Pterodactyl panel

1. Import `egg-impostor.json` (Admin → Nests → Import Egg).
2. Create a server with two allocations: the game port (primary, for example 22023) and the HTTP port (for example 22024).
3. Set `HTTP_PORT` to the second allocation port.
4. Start the server. The log must show `Enabling plugin gg.reactor.impostor`.
5. Add a schedule that restarts the server every day, outside league nights. The restart deploys new builds.

## Add a plugin

Impostor loads plugins from two places: `/opt/impostor/plugins` in the image (Reactor.Impostor) and `plugins/` on the server volume. The entrypoint makes `plugins/` and `libraries/` on each start.

1. Stop the server.
2. In the panel file manager, upload the plugin DLL to `plugins/`.
3. If the plugin needs other DLLs, upload them to `libraries/`.
4. Upload the plugin config file, if it has one, to the server root.
5. Start the server. The log must show `Enabling plugin <plugin id>`.

To remove a plugin, delete its DLL and restart. An image update does not change the volume, so update a volume plugin by hand. Do not upload a plugin that is already in the image.

## Updates

1. Every Monday the "Check for new versions" workflow compares the pins with the latest releases.
2. If a release is newer, the workflow opens a PR that changes the pins. It also builds the image for that branch.
3. Read the release notes and merge the PR.
4. The merge builds and pushes `:league`. The server takes it on its next restart.

To change anything else, edit the `Dockerfile` or the egg in a PR. A change to the egg needs a new import in the panel. A change to the image does not.

## Run it locally

```sh
docker build -t impostor-egg:local .
docker run --rm -p 22023:22023/udp -p 127.0.0.1:22024:22024 \
  -e SERVER_IP=127.0.0.1 -e SERVER_PORT=22023 -e HTTP_PORT=22024 \
  -e STARTUP="$(jq -r .startup egg-impostor.json)" \
  impostor-egg:local
```

## One-time GitHub setup

- After the first push to `main`, set the `impostor` package to public (Package settings → Change visibility). Wings then pulls it without a login.
- Allow GitHub Actions to create pull requests (Settings → Actions → General → Workflow permissions).
