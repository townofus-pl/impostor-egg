#!/bin/bash
# Pterodactyl yolk entrypoint: the panel passes the egg's startup command in STARTUP,
# with {{VARIABLE}} placeholders for the server's environment variables.
set -e
cd /home/container

# Impostor also loads plugins from ./plugins and ./libraries in its working directory, here the
# server volume. Make the folders, so they show in the panel file manager for uploads.
mkdir -p plugins libraries || echo "Could not make plugins/ and libraries/. Volume plugins are off."

MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# exec, so that the stop signal from Wings reaches Impostor and it shuts down cleanly.
eval "exec ${MODIFIED_STARTUP}"
