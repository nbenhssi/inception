*This project has been created as part of the 42 curriculum by nbenhssi.*

# Developer Documentation

This document is for anyone who wants to **set up, build, and modify** the
Inception stack.

## 1. Setting up the environment from scratch

### Prerequisites

- A Linux VM (Debian/Alpine-based host recommended, to match the
  containers' base image).
- Docker Engine + the Docker Compose plugin (`docker compose version`
  should work).
- `make`.
- Write access to `/home/nbenhssi/data` on the host (this is where the
  named volumes are pinned — see `srcs/docker-compose.yml`).

### Repository layout

```
.
├── Makefile
└── srcs
    ├── docker-compose.yml
    ├── .env                     # NOT committed — create it yourself
    └── requirements
        ├── mariadb
        │   ├── Dockerfile
        │   └── tools/mariadb.sh
        ├── nginx
        │   ├── Dockerfile
        │   └── conf/default.conf
        └── wordpress
            ├── Dockerfile
            └── tools/wordpress.sh
```

### Configuration file: `srcs/.env`

Create `srcs/.env` before the first build. It must define every variable
consumed by the entrypoint scripts and `docker-compose.yml`:

```env
# MariaDB
MARIA_DB=
MARIA_USER=
MARIA_PASSWORD=
MARIA_ROOT_PASSWORD=

# WordPress <-> database
MYSQL_DATABASE=
MYSQL_USER=
MYSQL_PASSWORD=
WORDPRESS_DB_HOST=mariadb

# WordPress site
DOMAIN_NAME=nbenhssi.42.fr
WORDPRESS_TITLE=
WORDPRESS_ADMIN=
WORDPRESS_ADMIN_PASSWORD=
WORDPRESS_ADMIN_EMAIL=
WORDPRESS_USER=
WORDPRESS_USER_EMAIL=
WORDPRESS_USER_PASSWORD=
```

Notes:
- `MARIA_DB`/`MARIA_USER`/`MARIA_PASSWORD` and
  `MYSQL_DATABASE`/`MYSQL_USER`/`MYSQL_PASSWORD` should point to the **same**
  database/user — they're read by two different scripts
  (`mariadb.sh` and `wordpress.sh`) that currently use different variable
  names for the same values, so keep them in sync.
- `WORDPRESS_DB_HOST` must stay `mariadb` — that's the service/container
  name on the `inception` Docker network.
- `WORDPRESS_ADMIN` must **not** contain `admin`/`administrator` in any
  case combination (subject requirement).
- Add `srcs/.env` to a `.gitignore` at the root of the repository — there
  currently isn't one, and the file has been committed in the past. See
  the security note at the end of this document before your evaluation.

## 2. Building and launching with the Makefile / Docker Compose

The `Makefile` is a thin wrapper around
`docker compose -f srcs/docker-compose.yml`:

```bash
make dirs      # mkdir -p the two host data directories
make build     # docker compose build
make up        # docker compose up -d (creates dirs first)
make down      # docker compose down
make start     # docker compose start
make stop      # docker compose stop
make restart   # down + up
make logs      # docker compose logs -f
make ps        # docker compose ps
make clean     # down --rmi all
make fclean    # down --rmi all --volumes --remove-orphans, docker system prune -af, rm -rf the data dir
make re        # fclean + all
```

You can also call `docker compose` directly if you need finer control,
e.g.:

```bash
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml up -d --no-deps wordpress
```

## 3. Managing containers and volumes

Useful commands while developing:

```bash
# Container status / logs
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f mariadb

# Shell into a running container
docker exec -it wordpress bash
docker exec -it mariadb bash

# Inspect the network
docker network inspect srcs_inception

# List / inspect the named volumes
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

Rebuilding a single service after editing its Dockerfile or scripts:

```bash
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress
```

## 4. Where the data lives and how it persists

The two named volumes declared in `srcs/docker-compose.yml` use the
`local` driver with bind options, which pins their actual storage to fixed
paths on the host while keeping them managed as Docker volumes:

- `mariadb_data` → `/home/nbenhssi/data/mariadb` (MariaDB's data
  directory, `/var/lib/mysql` inside the container).
- `wordpress_data` → `/home/nbenhssi/data/wordpress` (the WordPress
  install, `/var/www/html` inside the container — shared with NGINX so it
  can serve static files directly).

These directories are created by `make dirs` (invoked automatically by
`make build`/`make up`) and survive `make down`, `make stop`/`make start`,
and container recreation. They are only removed by `make fclean` (or
`make re`), which also runs `rm -rf` on the whole data directory — don't
run it unless you actually want to lose the site and database content.

The `mariadb.sh` and `wordpress.sh` entrypoint scripts are both
idempotent: they check whether initialization already happened
(`/var/lib/mysql/mysql` for MariaDB, `wp-config.php` for WordPress) and
skip straight to starting the daemon in the foreground if so — which is
what makes it safe to stop/start or restart the containers without
re-running the install every time.

## 5. Security note (read before submission)

`srcs/.env` is currently tracked in this repository's Git history (visible
in the `First commit` and a later `test` commit) with weak, real-looking
passwords. Per the subject, **any credentials found in the Git repository
cause the project to fail**, regardless of whether the file is present in
the latest commit. Before evaluation:

1. Remove `.env` from tracking: `git rm --cached srcs/.env`.
2. Add a `.gitignore` at the repository root containing at least:
   ```
   srcs/.env
   ```
3. Because the file was already pushed, removing it from the latest
   commit is **not enough** — it's still readable in the history. Rewrite
   history to purge it (e.g. with `git filter-repo` or the BFG Repo-Cleaner)
   and force-push, or start from a fresh repository if history rewriting
   isn't practical.
4. Rotate every credential that was exposed (database passwords, root
   password, WordPress admin password) — don't just remove the file and
   keep the same values.
