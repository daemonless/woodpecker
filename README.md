# Woodpecker CI

Woodpecker CI server and agent on FreeBSD.

| | |
|---|---|
| **Port** | 8000 |
| **Registry** | `ghcr.io/daemonless/woodpecker` |
| **Source** | [https://github.com/woodpecker-ci/woodpecker](https://github.com/woodpecker-ci/woodpecker) |
| **Website** | [https://woodpecker-ci.org/](https://woodpecker-ci.org/) |

## Deployment

### Podman Compose

```yaml
services:
  woodpecker:
    image: ghcr.io/daemonless/woodpecker:latest
    container_name: woodpecker
    environment:
      - WOODPECKER_SERVER_ENABLE=true
      - WOODPECKER_DATABASE_DRIVER=sqlite3
      - WOODPECKER_DATABASE_DATASOURCE=/config/woodpecker.sqlite
      - WOODPECKER_AGENT_SECRET=agent-secret
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - /path/to/containers/woodpecker:/config
    ports:
      - 8000:8000
      - 9000:9000
    restart: unless-stopped
```

### Podman CLI

```bash
podman run -d --name woodpecker \
  -p 8000:8000 \
  -p 9000:9000 \
  -e WOODPECKER_SERVER_ENABLE=true \
  -e WOODPECKER_DATABASE_DRIVER=sqlite3 \
  -e WOODPECKER_DATABASE_DATASOURCE=/config/woodpecker.sqlite \
  -e WOODPECKER_AGENT_SECRET=agent-secret \
  -e PUID=@PUID@ \
  -e PGID=@PGID@ \
  -e TZ=@TZ@ \
  -v /path/to/containers/woodpecker:/config \ 
  ghcr.io/daemonless/woodpecker:latest
```
Access at: `http://localhost:8000`

### Ansible

```yaml
- name: Deploy woodpecker
  containers.podman.podman_container:
    name: woodpecker
    image: ghcr.io/daemonless/woodpecker:latest
    state: started
    restart_policy: always
    env:
      WOODPECKER_SERVER_ENABLE: "true"
      WOODPECKER_DATABASE_DRIVER: "sqlite3"
      WOODPECKER_DATABASE_DATASOURCE: "/config/woodpecker.sqlite"
      WOODPECKER_AGENT_SECRET: "agent-secret"
      PUID: "1000"
      PGID: "1000"
      TZ: "UTC"
    ports:
      - "8000:8000"
      - "9000:9000"
    volumes:
      - "/path/to/containers/woodpecker:/config"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WOODPECKER_SERVER_ENABLE` | `true` | Enable Woodpecker Server (true/false) |
| `WOODPECKER_DATABASE_DRIVER` | `sqlite3` |  |
| `WOODPECKER_DATABASE_DATASOURCE` | `/config/woodpecker.sqlite` |  |
| `WOODPECKER_AGENT_SECRET` | `agent-secret` | Shared secret for server-agent communication |
| `PUID` | `1000` |  |
| `PGID` | `1000` |  |
| `TZ` | `UTC` |  |

### Volumes

| Path | Description |
|------|-------------|
| `/config` | Data directory (database, logs) |

### Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `8000` | TCP | Server Web UI/API |
| `9000` | TCP | GRPC (Server/Agent communication) |

## Notes

- **User:** `bsd` (UID/GID set via PUID/PGID)
- **Base:** Built on `ghcr.io/daemonless/base` (FreeBSD)