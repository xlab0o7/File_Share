# File Share

Share one folder on this Mac with people on other networks. They open a link in any browser (phone or computer), log in, and can view, download, and (if allowed) upload files.

It has two parts:

- **FileBrowser** – the website people see: login page, file list, download/upload, share links.
- **Cloudflare tunnel** – gives that website a public `https://….trycloudflare.com` address, so it works from any network without touching your router.

You can run it **with Docker** or **without Docker**. Both do the same thing; pick one and use only that one at a time.

---

## Contents

1. [Folder layout](#1-folder-layout)
2. [Choose the folder to share](#2-choose-the-folder-to-share)
3. [Option A – Run with Docker](#3-option-a--run-with-docker)
4. [Option B – Run without Docker](#4-option-b--run-without-docker)
5. [Give someone access](#5-give-someone-access)
6. [What the other person does](#6-what-the-other-person-does)
7. [Stop sharing](#7-stop-sharing)
8. [Download speed](#8-download-speed)
9. [Security checklist](#9-security-checklist)
10. [Troubleshooting](#10-troubleshooting)
11. [Quick reference](#11-quick-reference)

---

## 1. Folder layout

```
~/file-share/
├── .env                  # Which folder to share (SHARE_DIR=...)
├── admin-password.txt    # Admin login (only you can read it)
├── docker-compose.yml    # Option A: Docker setup
├── run-local.sh          # Option B: no-Docker script
├── bin/filebrowser       # Option B: FileBrowser program (v2.32.0, official release)
├── data/                 # Option A: user accounts & settings
├── data-local/           # Option B: user accounts & settings (separate copy)
├── config/               # Option A: FileBrowser config
└── logs/                 # Option B: filebrowser.log, tunnel.log
```

> **Important:** Option A and Option B keep **separate** user lists (`data/` vs `data-local/`). A user you create in one will **not** exist in the other. Option B copied Option A's users once, the first time it ran.

---

## 2. Choose the folder to share

Only this one folder (and everything inside it) is visible to others.

1. Open `~/file-share/.env` in any text editor.
2. Set the full path of the folder:
   ```
   SHARE_DIR=/Users/zainulabedin/Downloads
   ```
3. Save the file.
4. If the server is already running, **restart it** for the change to apply:
   - Docker: `docker compose up -d --force-recreate`
   - No Docker: press `Ctrl+C`, then run `./run-local.sh` again.

> Tip: Share a dedicated folder (for example `~/Shared-With-Ali`) rather than all of Documents or Downloads. Anything you later drop into the shared folder becomes visible too.

---

## 3. Option A – Run with Docker

### Requirements

- Docker Desktop installed and **running** (whale icon in the menu bar).

### Start

```bash
cd ~/file-share
docker compose up -d
```

### Get the public link

The link is printed by the tunnel. Cloudflare can take from a few seconds to a couple of minutes:

```bash
cd ~/file-share
docker compose logs tunnel | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' | grep -v api | tail -1
```

If nothing prints, wait 30 seconds and run it again. The tunnel retries by itself.

### Check it is running

```bash
docker compose ps
```

Both `filebrowser` and `tunnel` should say `running`.

### Use it yourself on this Mac

Open http://127.0.0.1:8080

---

## 4. Option B – Run without Docker

### Requirements (one-time)

- `cloudflared`: `brew install cloudflared`
- `bin/filebrowser`: already in place. If it is ever missing, download
  `darwin-arm64-filebrowser.tar.gz` for **v2.32.0** from
  https://github.com/filebrowser/filebrowser/releases and extract `filebrowser` into `~/file-share/bin/`.

> Do **not** use `brew install filebrowser`. That build has no web interface (every page shows 404) and is deprecated.

### Start

First make sure the Docker version is **not** running (both use port 8080):

```bash
cd ~/file-share
docker compose stop        # skip if you don't use Docker
./run-local.sh
```

You will see:

```
Sharing: /Users/zainulabedin/Downloads
Local:   http://127.0.0.1:8080
Waiting for public link (Cloudflare can take a few minutes)...
Public:  https://some-random-words.trycloudflare.com
Press Ctrl+C to stop sharing.
```

The `Public:` line is the link to send. Keep this Terminal window open — closing it or pressing `Ctrl+C` stops sharing.

### Run on a different port

```bash
PORT=8090 ./run-local.sh
```

### Logs

- `logs/filebrowser.log` – web server activity and errors
- `logs/tunnel.log` – Cloudflare connection and retries

---

## 5. Give someone access

First log in yourself:

1. Open http://127.0.0.1:8080 (or the public link).
2. Username: `admin`
3. Password: in `~/file-share/admin-password.txt`
   ```bash
   cat ~/file-share/admin-password.txt
   ```

> **Never give the admin password to anyone.** Admin can delete files, change settings, and create users.

Then choose **one** of the two ways below.

### Way 1 – Share link (no account needed; best for a few files)

1. Click a file or folder to select it.
2. Click the **Share** icon (top bar).
3. Optional: set an **expiry time** (e.g. 1 day) and a **password**.
4. Click **Share** and copy the link.
5. Send the link (and password, separately) to the person.

To cancel a share later: **Settings → Shares** → delete it.

### Way 2 – Personal login (best when they need to browse the whole folder)

1. Go to **Settings → User Management → New**.
2. Enter a username and a strong password.
3. Under **Permissions**, untick everything they should not do. For **view and download only**, leave only **Download** ticked; untick Create, Rename, Modify, Delete, Share, Execute.
4. Optional: set **Scope** to a sub-folder (e.g. `/ProjectX`) to limit them to that folder only.
5. Click **Save**.
6. Send them the public link, their username, and password.

To remove access later: **Settings → User Management** → open the user → **Delete**.

---

## 6. What the other person does

1. Open the link you sent in any browser (Chrome, Safari) on their phone or computer.
2. If it says "site can't be reached", wait 1–2 minutes and try again — new links take a moment to become available.
3. Log in with the username/password you gave them (not needed for a share link).
4. Tap a file → **Download** icon.
   - For a whole folder, select it and use **Download** → choose `zip` to get one file.

They do not need to install anything.

---

## 7. Stop sharing

| Running as | Stop | Start again |
|---|---|---|
| Docker | `cd ~/file-share && docker compose stop` | `docker compose up -d` |
| No Docker | `Ctrl+C` in the Terminal running the script | `./run-local.sh` |

Sharing also stops if the Mac sleeps, shuts down, loses internet, or (Docker) Docker Desktop quits.

> **The public link changes every time the tunnel restarts.** After a restart, get the new link (section 3 or 4) and send it again. Accounts and passwords stay the same.

---

## 8. Download speed

The other person's download speed **can never be higher than this Mac's internet upload speed**. Check yours:

```bash
networkQuality -s
```

Look at `Uplink capacity`. Divide by 8 to get MB/s (e.g. 13.4 Mbps ≈ 1.6 MB/s ≈ 10 minutes per GB).

The free Cloudflare tunnel also routes traffic through a Cloudflare data centre (e.g. Singapore), which adds delay. Ways to improve:

| Option | Effect | Notes |
|---|---|---|
| **Zip before sending** | Faster for folders with many files | One big file transfers far better than hundreds of small ones |
| **One download at a time** | Each download gets the full speed | Parallel downloads share the same upload |
| **Pause other uploads** | Frees upload bandwidth | iCloud, Google Photos, Dropbox sync |
| **Wired / near the router** | More stable speed | Wi-Fi far from router loses speed |
| **Tailscale** | Direct phone ↔ Mac connection, no detour | Other person installs the Tailscale app once |
| **ngrok (India region)** | Closer relay than Singapore | Free account; monthly data limit |
| **Google Drive / Dropbox** | They download at *their* full speed | You upload once; works while Mac is off |

For large files or many recipients, Google Drive/Dropbox is the fastest for the end user.

---

## 9. Security checklist

- [ ] Share a **specific folder**, never your whole home folder.
- [ ] Never share the **admin** password; give each person their own user or a share link.
- [ ] Use **view/download-only** permissions unless they truly need to upload.
- [ ] Put an **expiry** and **password** on share links.
- [ ] **Stop the server** when you are not sharing.
- [ ] Do **not** share patient, client, or other confidential data through the quick public link — anyone who gets the link can reach the login page. Use Tailscale or company-approved storage instead.
- [ ] Keep `admin-password.txt` private (it is readable only by your user account).

### Change the admin password

Log in as admin → **Settings → Profile Settings** → enter new password → **Update**. Then update `admin-password.txt` (or delete it once you've saved the password in your password manager).

Remember Option A and Option B have separate user lists, so change it in each one you use.

---

## 10. Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| No public link appears | Cloudflare's free service is slow to respond (`context deadline exceeded` in logs) | Wait. Both options retry automatically. Docker: `docker compose restart tunnel` to force a new try |
| Link opens "site can't be reached" right after starting | The new address hasn't spread through DNS yet, or the device cached an old "not found" | Wait 1–2 minutes, or try on mobile data / a different device |
| Old link stopped working | Tunnel restarted, so a new link was created | Get the new link (section 3/4) and resend |
| `Port 8080 is in use` when running `run-local.sh` | Docker version is running | `docker compose stop`, or run `PORT=8090 ./run-local.sh` |
| `Set SHARE_DIR in .env to an existing folder` | `.env` missing, empty, or path typo | Fix the path in `.env` (section 2) |
| `docker compose up` error: `Set SHARE_DIR in .env…` | Same as above | Same as above |
| Every page shows 404 (no-Docker version) | Homebrew's `filebrowser` is being used | Use `bin/filebrowser` from the official release (section 4) |
| Login rejected | Wrong password, or user exists only in the other option's database | Check `admin-password.txt`; recreate the user in the option you're running |
| Docker still shares the old folder after editing `.env` | Docker reads `.env` only when containers are created | `docker compose up -d --force-recreate` |
| Very slow downloads | Upload speed limit / Cloudflare relay | See section 8 |
| `cert.pem` error in tunnel logs | Normal for quick tunnels | Ignore |

Useful log commands:

```bash
# Docker
docker compose logs --tail 50 filebrowser
docker compose logs --tail 50 tunnel

# No Docker
tail -50 ~/file-share/logs/filebrowser.log
tail -50 ~/file-share/logs/tunnel.log
```

---

## 11. Quick reference

```bash
# --- Docker ---
cd ~/file-share
docker compose up -d                                   # start
docker compose logs tunnel | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' | grep -v api | tail -1   # get link
docker compose up -d --force-recreate                  # apply .env change
docker compose stop                                    # stop

# --- No Docker ---
cd ~/file-share
docker compose stop      # make sure Docker version is off
./run-local.sh           # start (link is printed); Ctrl+C to stop

# --- Both ---
cat ~/file-share/admin-password.txt   # admin login
networkQuality -s                     # check upload speed
```
