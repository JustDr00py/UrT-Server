# Urban Terror 4.3 – Dockerized Dedicated Server

16-player Team Survivor server, fully configurable via environment variables.

## Quick Start

### 1. Get the UrT server files
```bash
mkdir -p urt-game
# Download Urban Terror 4.3.4 Linux dedicated server from urbanterror.info
# Extract so that urt-game/ contains the binary + q3ut4/ folder
bash scripts/download-urt.sh   # prints instructions; pass URT_DOWNLOAD_URL= to auto-download
```

### 2. Configure
```bash
cp .env .env.local    # optional – docker compose reads .env automatically
# Edit .env and change passwords at minimum:
#   URT_RCON_PASSWORD
#   URT_REFEREE_PASSWORD
```

### 3. Run
```bash
docker compose up --build -d
docker compose logs -f
```

### 4. RCON access
```
# In-game console or any UrT RCON client:
/rcon <URT_RCON_PASSWORD> status
/rcon <URT_RCON_PASSWORD> map ut4_uptown
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `URT_HOSTNAME` | `My Urban Terror Server [TS 16p]` | Server name shown in browser |
| `URT_MOTD` | `Welcome! Play fair, have fun.` | Message of the day |
| `URT_RCON_PASSWORD` | `changeme_rcon` | **Change this!** Remote console password |
| `URT_REFEREE_PASSWORD` | `changeme_ref` | **Change this!** Referee password |
| `URT_SERVER_PASSWORD` | _(empty)_ | Set to make server private |
| `URT_PORT` | `27960` | UDP port |
| `URT_PUBLIC` | `2` | `2`=internet, `1`=LAN, `0`=private |
| `URT_MAX_CLIENTS` | `16` | Max players |
| `URT_GAMETYPE` | `4` | Game mode (see below) |
| `URT_TIMELIMIT` | `20` | Minutes per map |
| `URT_FRAGLIMIT` | `0` | Kill limit (0=off) |
| `URT_FRIENDLY_FIRE` | `1` | `0`=off `1`=half `2`=full `3`=reflect |
| `URT_TEAM_BALANCE` | `1` | Auto-balance teams |
| `URT_GEAR` | `0` | Weapon bitmask (`0`=all) |
| `URT_FPS` | `40` | Server framerate |
| `URT_MAX_RATE` | `50000` | Max client bandwidth (bytes/s) |
| `URT_MAX_PING` | `250` | Kick players above this ping |
| `URT_GRAVITY` | `800` | World gravity |
| `URT_SPEED` | `320` | Player move speed |
| `URT_STAMINA` | `0` | `0`=infinite sprint, `1`=enabled |
| `URT_DO_WARMUP` | `1` | Enable warmup phase |
| `URT_WARMUP_TIME` | `15` | Warmup seconds |
| `URT_ALLOW_VOTE` | `1` | Allow player voting |
| `URT_VOTE_FLAGS` | `255` | Bitmask of allowed votes |
| `URT_PURE` | `1` | Enforce pure server |

### Game Types
| Value | Mode |
|---|---|
| 0 | Free For All (FFA) |
| 1 | Last Man Standing (LMS) |
| 2 | Team Deathmatch (TDM) |
| **4** | **Team Survivor (TS) ← default** |
| 5 | Capture and Hold (CAH) |
| 6 | Capture the Flag (CTF) |
| 7 | Bomb Mode |

---

## Map Rotation
Edit `config/maprotation.cfg` and the container picks it up immediately (it's a read-only bind mount). No rebuild needed. Send `/rcon exec maprotation.cfg` in-game to reload.

## Volume Layout
| Path in container | Purpose |
|---|---|
| `/opt/urtserver/game` | UrT game files (read-only bind mount → `./urt-game/`) |
| `/opt/urtserver/data` | Config, logs, downloaded pk3s (named Docker volume) |

## Performance Notes (16-player optimizations)
- **sv_fps 40** — double the default (20); reduces lag compensation errors
- **sv_maxrate 50000** — allows full-bandwidth clients to stop choppy movement
- **g_smoothClients 1** — interpolates movement between server frames
- **tini** as PID 1 ensures clean SIGTERM → graceful shutdown
