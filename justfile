set dotenv-load := true

# Launch watchtower container
up args="-d":
  docker compose up {{args}}

# Show watchtower log
logs:
  docker logs --tail=100 -f watchtower

# Stop watchtower container
down args="":
  docker compose down {{args}}

# Ask watchtower to check/update the enabled containers
watchtower:
  #!/bin/bash
  AUTH="Authorization: Bearer ${WATCHTOWER_HTTP_API_TOKEN}"
  curl -H "$AUTH" "$WATCHTOWER_UPDATE_ENDPOINT"
