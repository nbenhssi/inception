*This project has been created as part of the 42 curriculum by nbenhssi.*

# User Documentation

This document is for anyone who just wants to **run and use** the Inception
stack — no development knowledge required.

## 1. What services does the stack provide?

| Service    | Role                                                              |
|------------|--------------------------------------------------------------------|
| `nginx`    | The only entry point. Serves the site over HTTPS (port 443, TLSv1.2/1.3 only). |
| `wordpress`| The WordPress site itself, running PHP through php-fpm.           |
| `mariadb`  | The database that stores all WordPress content (posts, users, settings). |

Only `nginx` is reachable from outside the virtual machine; `wordpress` and
`mariadb` are only reachable from other containers on the internal
`inception` Docker network.

## 2. Starting and stopping the project

All commands are run from the root of the repository, where the
`Makefile` lives.

| Command        | Effect                                                        |
|-----------------|----------------------------------------------------------------|
| `make` / `make all` | Creates the host data folders, builds the images, starts everything in the background. |
| `make up`       | Starts the containers (building first if needed).             |
| `make down`     | Stops and removes the containers (data is kept in the volumes). |
| `make start`    | Resumes previously stopped containers without rebuilding.     |
| `make stop`     | Pauses the containers without removing them.                  |
| `make restart`  | Equivalent to `make down` then `make up`.                     |
| `make clean`    | Removes containers and images.                                |
| `make fclean`   | Removes containers, images, volumes, **and deletes the data folders on the host**. Use with care — this deletes the site and database content. |
| `make re`       | `fclean` followed by `all` — a full reset and rebuild.        |

## 3. Accessing the website and the administration panel

1. Make sure your machine (or the VM) resolves `nbenhssi.42.fr` to the
   VM's IP address — normally via an `/etc/hosts` entry.
2. Open `https://nbenhssi.42.fr` in a browser.
   - The certificate is self-signed, so the browser will show a warning the
     first time; this is expected for this project and can be accepted.
3. To reach the admin panel, go to `https://nbenhssi.42.fr/wp-admin` and
   log in with the WordPress administrator account (see below for where the
   credentials live).

There are two WordPress accounts configured for this project:
- An **administrator** account (its username intentionally does not
  contain "admin"/"administrator", per the subject's rules).
- A regular **editor/author** account.

## 4. Locating and managing credentials

All credentials (database name/user/password, WordPress admin and regular
user accounts, admin email, etc.) live in a single file:

```
srcs/.env
```

This file is deliberately **not committed to Git** — it must be created
locally before running `make` (see `DEV_DOC.md` for the exact variables
it needs to contain). If you need to change a password:

1. Edit the relevant value in `srcs/.env`.
2. Run `make down` then `make up` to restart the containers with the new
   values.
   - Note: the WordPress admin/user accounts and the database are only
     initialized **once**, on first boot of each container (the
     entrypoint scripts check for an existing installation). Changing a
     password in `.env` after the first run will not retroactively change
     it inside WordPress/MariaDB — you'd need to change it through
     `wp-admin` / the database directly, or wipe the volumes with
     `make fclean` and start fresh.

## 5. Checking that the services are running correctly

- `make ps` (or `docker compose -f srcs/docker-compose.yml ps`) lists the
  three containers and their status; all three should show as `running`.
- `make logs` streams the logs of all three containers — useful to see
  the MariaDB/WordPress initialization messages on first boot, or to
  diagnose a container that keeps restarting.
- `docker ps` shows the containers with their restart policy; because the
  Makefile sets `restart: always`, a crashed container should come back up
  on its own.
- Visiting `https://nbenhssi.42.fr` and seeing the WordPress site load is
  the simplest end-to-end check that all three services are working
  together correctly.
