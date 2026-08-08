*This project has been created as part of the 42 curriculum by nbenhssi.*

# Inception

## Description

Inception is a system-administration project whose goal is to build a small,
self-contained web infrastructure entirely with Docker, without relying on
any pre-built images other than the base OS layer.

The stack is composed of three custom-built services, each running in its
own container, wired together through a dedicated Docker network:

- **NGINX** — the single entry point of the infrastructure. It serves HTTPS
  only, restricted to TLSv1.2/TLSv1.3, and forwards PHP requests to WordPress.
- **WordPress + php-fpm** — the application layer. It has no web server of
  its own; it only exposes a FastCGI socket on port 9000 that NGINX talks to.
- **MariaDB** — the database layer used to store the WordPress data.

Two named, persistent volumes hold the WordPress files and the MariaDB data
directory, and everything is orchestrated by a `Makefile` that wraps
`docker compose`.

## Instructions

### Prerequisites

- A Linux virtual machine (this project is meant to run inside a VM).
- Docker Engine and the Docker Compose plugin.
- `make`.
- An entry in `/etc/hosts` (or your local DNS) pointing `nbenhssi.42.fr` to
  the VM's IP address, e.g.:

  ```
  127.0.0.1   nbenhssi.42.fr
  ```

### Setup

1. Clone the repository.
2. Create `srcs/.env` (see [DEV_DOC.md](./DEV_DOC.md) for the full list of
   variables). **This file must never be committed to Git.**
3. From the root of the repository, run:

   ```bash
   make
   ```

   This creates the host data directories, builds the three images, and
   starts the stack in detached mode.

4. Open `https://nbenhssi.42.fr` in a browser (accept the self-signed
   certificate) to reach the WordPress site.

See [USER_DOC.md](./USER_DOC.md) for day-to-day usage and
[DEV_DOC.md](./DEV_DOC.md) for development/setup details and the full
Makefile command reference.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WP-CLI documentation](https://wp-cli.org/)
- [WordPress Codex](https://codex.wordpress.org/)
- 42's own "Docker" and "Inception" peer-review notes and the project
  subject PDF included at the root of this repository.

**AI usage:** an AI assistant was used to help draft this
`README.md`, `USER_DOC.md`, and `DEV_DOC.md` from the existing codebase —
reading the `Dockerfile`s, entrypoint scripts, and `docker-compose.yml` to
describe accurately what the project does — and to review the repository
for the exposed `.env` issue described below. It was not used to write the
Dockerfiles or shell scripts themselves. All generated text was reviewed
and adjusted by the author before submission.

## Project description — Docker choices and comparisons

Every service is built from its **own Dockerfile**, based on the same
Debian (bookworm) base image, and each Dockerfile installs only what that
service needs (NGINX + OpenSSL for the proxy, PHP-FPM + WP-CLI for
WordPress, `mariadb-server` for the database). No service pulls a
ready-made image from Docker Hub. Each container's entrypoint script is
idempotent: on first boot it initializes the database or installs
WordPress, and on subsequent boots it just starts the daemon in the
foreground (PID 1), which is what lets `restart: always` work correctly
without falling back to hacky patches like `tail -f` or `sleep infinity`.

### Virtual Machines vs Docker

A VM virtualizes an entire machine — its own kernel, its own set of
drivers — through a hypervisor, which makes it heavy to boot and to
duplicate, but gives very strong isolation. A Docker container shares the
host's kernel and only isolates the process, filesystem, and network
namespaces, which makes it start in milliseconds and much cheaper to run
many of at once. This project uses a VM as the outer boundary (as required
by the subject) and Docker containers inside it to isolate NGINX,
WordPress, and MariaDB from each other while keeping them lightweight and
easy to rebuild independently.

### Secrets vs Environment Variables

Environment variables (as used here, via `srcs/.env` and `env_file:` in
`docker-compose.yml`) are simple and readable by any process in the
container, and, on most systems, visible to anyone who can inspect the
container (`docker inspect`) or read `/proc/<pid>/environ`. Docker secrets
are mounted as files (typically under `/run/secrets/`), only exposed to the
services that explicitly declare them, never persisted in the container's
metadata, and are not part of the image layers. The subject only makes the
`.env` file mandatory and secrets "strongly recommended"; for a stricter
setup, database/WordPress passwords should be moved to secrets files
referenced with Compose's `secrets:` key instead of plain environment
variables, and only non-sensitive configuration (like `DOMAIN_NAME`) should
stay in `.env`.

### Docker Network vs Host Network

With `network: host`, a container shares the host's network stack
directly — no isolation, no per-container IP, and port conflicts become the
host's problem. A user-defined Docker network (the `inception` network
created in `docker-compose.yml`) gives each container its own network
namespace and a private DNS, so services can reach each other by container
name (e.g. WordPress talking to `mariadb`, NGINX talking to `wordpress`)
without exposing anything except the ports that are explicitly published.
Here, only NGINX publishes a port to the host (443); WordPress and MariaDB
are reachable only from inside the `inception` network, which is the whole
point of using a dedicated bridge network instead of the host's.

### Docker Volumes vs Bind Mounts

A bind mount maps an arbitrary path on the host directly into the
container; Docker doesn't manage it, so its lifecycle, permissions, and
location are entirely up to the user. A named volume is created and
managed by Docker (`docker volume ...`), and its lifecycle is independent
from any single container. This project uses **named volumes**
(`mariadb_data` and `wordpress_data`) configured with the `local` driver
and `bind` driver options so that Docker still manages them as volumes
while their actual files live at a specific host path,
`/home/nbenhssi/data/{mariadb,wordpress}`, as required by the subject.
That combination satisfies both constraints: the storage is a genuine
named volume (survives `docker compose down`, is listed by `docker volume
ls`, can be backed up/inspected the Docker way) while still being pinned to
a predictable location on the host.
