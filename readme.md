# File Share

A simple setup to share a local folder over the internet using [FileBrowser](https://filebrowser.org/) and [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/trycloudflare/).

## Features

- **FileBrowser**: A web-based file manager to browse, upload, and share files.
- **Cloudflare Tunnel**: Securely exposes your local FileBrowser instance to the internet without opening firewall ports.
- **Dual Support**: Run via Docker Compose or a local bash script.

## Prerequisites

### Docker Method (Recommended)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Local Script Method (macOS)
- `cloudflared`: Install via Homebrew: `brew install cloudflared`
- `filebrowser` binary: Download the `darwin-arm64` release from [GitHub](https://github.com/filebrowser/filebrowser/releases) and place it in a `bin/` directory as `bin/filebrowser`.

## Setup

1.  **Configure Environment**:
    Create a `.env` file in the root directory and specify the folder you want to share:
    ```bash
    SHARE_DIR=/path/to/your/shared/folder
    ```

2.  **Initialize Database (Optional)**:
    If you want to pre-configure users or settings, the database is stored in `./data/filebrowser.db` (Docker) or `data-local/filebrowser.db` (Local).

## Usage

### Option 1: Docker Compose

Start the services:
```bash
docker compose up -d
```

Stop the services:
```bash
docker compose down
```

### Option 2: Local Script (macOS)

Run the script:
```bash
./run-local.sh
```
This will:
1. Start FileBrowser on `127.0.0.1:8080`.
2. Start a Cloudflare quick tunnel.
3. Print the public URL once it's ready.

## Access

- **Local**: [http://127.0.0.1:8080](http://127.0.0.1:8080)
- **Public**: The `run-local.sh` script or Docker logs for the `tunnel` service will provide a `*.trycloudflare.com` URL.

## Configuration Details

- **Docker Volumes**:
  - `/srv`: The shared directory (mapped to `SHARE_DIR`).
  - `/database`: Stores `filebrowser.db`.
  - `/config`: Optional configuration files.
- **Ports**:
  - FileBrowser listens on port `80` inside the container, mapped to `127.0.0.1:8080` on the host for security.