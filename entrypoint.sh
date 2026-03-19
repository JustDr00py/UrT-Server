#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Urban Terror 4.3 Dedicated Server – Entrypoint
# All settings are driven by environment variables with sane defaults.
# ──────────────────────────────────────────────────────────────────────────────

GAME_DIR="/opt/urtserver/game"
DATA_DIR="/opt/urtserver/data"
CONFIG_DIR="${DATA_DIR}/q3ut4"
SERVER_CFG="${CONFIG_DIR}/server.cfg"

# ── Locate server binary ──────────────────────────────────────────────────────
find_binary() {
    for bin in \
        "${GAME_DIR}/Quake3-UrT-Ded.x86_64" \
        "${GAME_DIR}/Quake3-UrT-Ded.i386" \
        "${GAME_DIR}/ioq3urt.x86_64" \
        "${GAME_DIR}/ioq3urt.i386"; do
        if [[ -x "$bin" ]]; then
            echo "$bin"
            return 0
        fi
    done
    return 1
}

if ! SERVER_BIN=$(find_binary); then
    echo "────────────────────────────────────────────────────────────"
    echo " ERROR: No UrT dedicated server binary found in ${GAME_DIR}"
    echo ""
    echo " Place the Urban Terror 4.3 server files in the directory"
    echo " mapped to /opt/urtserver/game (see docker-compose.yml)."
    echo " Run ./scripts/download-urt.sh to fetch them automatically."
    echo "────────────────────────────────────────────────────────────"
    exit 1
fi

echo "[UrT] Using binary: ${SERVER_BIN}"

# ── Environment variable defaults ────────────────────────────────────────────

# Server identity
: "${URT_HOSTNAME:=Urban Terror Server}"
: "${URT_MOTD:=Welcome! Have fun and play fair.}"
: "${URT_ADMIN_NAME:=Admin}"

# Auth / passwords  (leave blank to disable)
: "${URT_RCON_PASSWORD:=changeme_rcon}"
: "${URT_REFEREE_PASSWORD:=changeme_ref}"
: "${URT_SERVER_PASSWORD:=}"          # empty = public server

# Network
: "${URT_PORT:=27960}"
: "${URT_MAX_RATE:=50000}"            # generous for modern broadband
: "${URT_MIN_RATE:=8000}"
: "${URT_MAX_PING:=0}"                # 0 = no ping limit; set e.g. 300 to kick high pingers
: "${URT_MIN_PING:=0}"
: "${URT_FPS:=40}"                    # server-side fps (higher = smoother hits)
: "${URT_SNAPS:=20}"

# Player limits
: "${URT_MAX_CLIENTS:=16}"
: "${URT_PUBLIC:=2}"                  # 0=private, 1=LAN, 2=internet

# Gameplay – defaults tuned for Team Survivor
: "${URT_GAMETYPE:=4}"                # 4 = Team Survivor (TS)
: "${URT_TIMELIMIT:=20}"              # minutes
: "${URT_FRAGLIMIT:=0}"               # 0 = disabled in TS
: "${URT_ROUNDLIMIT:=0}"              # 0 = unlimited rounds
: "${URT_CAPTURELIMIT:=0}"
: "${URT_OVERTIME:=1}"                # allow overtime
: "${URT_FRIENDLY_FIRE:=1}"           # 0=off 1=half 2=full 3=reflect
: "${URT_TEAM_BALANCE:=1}"            # auto rebalance
: "${URT_GEAR:=0}"                    # 0 = all weapons; use bitmask to restrict
: "${URT_GRAVITY:=800}"
: "${URT_SPEED:=320}"
: "${URT_JUMP_VELOCITY:=270}"
: "${URT_STAMINA:=0}"                 # 0=unlimited sprint
: "${URT_RESPAWN_PROTECTION:=0}"      # seconds of spawn protection
: "${URT_SMOOTH_CLIENTS:=1}"          # interpolation for smoother movement
: "${URT_FALL_DAMAGE:=0}"             # 0=no fall damage 1=enabled

# Warmup
: "${URT_DO_WARMUP:=1}"
: "${URT_WARMUP_TIME:=15}"

# Voting
: "${URT_ALLOW_VOTE:=1}"
: "${URT_VOTE_FLAGS:=255}"            # bitmask of allowed votes
: "${URT_VOTE_LIMIT:=5}"              # max votes per map
: "${URT_VOTE_PASS_PCT:=51}"          # % yes votes required to pass

# Anti-cheat / security
: "${URT_PURE:=1}"                    # enforce pure server (no custom pk3 hacks)
: "${URT_FLOOD_PROTECT:=1}"
: "${URT_ANTICHEAT:=0}"               # 1 requires UrT cheat-check support

# Client auto-download
: "${URT_ALLOW_DOWNLOAD:=1}"          # 1 = clients auto-download missing pk3s
: "${URT_DL_URL:=}"                   # optional redirect URL (HTTP) for faster downloads
: "${URT_EXTRA_MAPS:=}"               # space-separated extra maps to generate mapconfigs for

# Map settings
: "${URT_MAP_VOTE_DELAY:=5}"          # seconds between map vote calls
: "${URT_NEXTMAP:=map ut4_algiers}"   # fallback if maprotation is empty

# ── Generate server.cfg ───────────────────────────────────────────────────────
mkdir -p "${CONFIG_DIR}"

cat > "${SERVER_CFG}" <<EOF
// ─────────────────────────────────────────────────────────────────────────────
// Urban Terror 4.3 – Auto-generated server.cfg
// Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
// Edit via environment variables in docker-compose.yml / .env
// ─────────────────────────────────────────────────────────────────────────────

// ── Server Identity ──────────────────────────────────────────────────────────
set sv_hostname         "${URT_HOSTNAME}"
set server_motd         "${URT_MOTD}"
set sv_adminname        "${URT_ADMIN_NAME}"

// ── Authentication ───────────────────────────────────────────────────────────
set rconpassword        "${URT_RCON_PASSWORD}"
set refereepassword     "${URT_REFEREE_PASSWORD}"
set g_password          "${URT_SERVER_PASSWORD}"

// ── Network ──────────────────────────────────────────────────────────────────
set net_port            ${URT_PORT}
set dedicated           ${URT_PUBLIC}
set sv_fps              ${URT_FPS}
set snaps               ${URT_SNAPS}
set sv_maxrate          ${URT_MAX_RATE}
set sv_minrate          ${URT_MIN_RATE}
set sv_maxping          ${URT_MAX_PING}
set sv_minping          ${URT_MIN_PING}

// ── Player Limits ────────────────────────────────────────────────────────────
set sv_maxclients       ${URT_MAX_CLIENTS}
set sv_privateClients   0
set sv_privatePassword  ""

// ── Gameplay ─────────────────────────────────────────────────────────────────
set g_gametype          ${URT_GAMETYPE}
set timelimit           ${URT_TIMELIMIT}
set fraglimit           ${URT_FRAGLIMIT}
set roundlimit          ${URT_ROUNDLIMIT}
set capturelimit        ${URT_CAPTURELIMIT}
set g_overtime          ${URT_OVERTIME}
set g_friendlyfire      ${URT_FRIENDLY_FIRE}
set g_teambalance       ${URT_TEAM_BALANCE}
set g_gear              ${URT_GEAR}
set g_gravity           ${URT_GRAVITY}
set g_speed             ${URT_SPEED}
set g_jumpvelocity      ${URT_JUMP_VELOCITY}
set g_stamina           ${URT_STAMINA}
set g_respawnprotection ${URT_RESPAWN_PROTECTION}
set g_smoothClients     ${URT_SMOOTH_CLIENTS}
set g_falldamage        ${URT_FALL_DAMAGE}

// ── Warmup ───────────────────────────────────────────────────────────────────
set g_doWarmup          ${URT_DO_WARMUP}
set g_warmup            ${URT_WARMUP_TIME}

// ── Voting ───────────────────────────────────────────────────────────────────
set g_allowvote         ${URT_ALLOW_VOTE}
set g_voteflags         ${URT_VOTE_FLAGS}
set g_votelimit         ${URT_VOTE_LIMIT}
set g_voteminplayers    2
set g_mapvotedelay      ${URT_MAP_VOTE_DELAY}

// ── Anti-cheat / Security ────────────────────────────────────────────────────
set sv_pure             ${URT_PURE}
set g_floodprotection   ${URT_FLOOD_PROTECT}
set sv_anticheat        ${URT_ANTICHEAT}

// ── Client Auto-download ──────────────────────────────────────────────────────
// sv_allowdownload 1 = clients fetch missing pk3s directly from this server.
// Set sv_dlURL to an HTTP URL to redirect downloads there instead (much faster;
// avoids choking the game port with file transfers during active play).
// g_mapConfigs re-applies sv_allowdownload after every map load (the game
// module resets it to 0 on each SV_SpawnServer call).
set sv_allowdownload    ${URT_ALLOW_DOWNLOAD}
$([ -n "${URT_DL_URL}" ] && echo "set sv_dlURL            \"${URT_DL_URL}\"")
set g_mapConfigs        "mapconfigs"

// ── Logging ──────────────────────────────────────────────────────────────────
set g_log               "games.log"
set g_logsync           1
set logfile             2

// ── Performance tweaks for 16-player smoothness ──────────────────────────────
// Increase packet budget so all 16 clients get timely updates
set sv_packetdelay      0
set sv_paks             0

// ── Map Rotation ─────────────────────────────────────────────────────────────
exec maprotation.cfg

EOF

echo "[UrT] Configuration written to ${SERVER_CFG}"

# ── Generate per-map configs (g_mapConfigs) ───────────────────────────────────
# UrT's game module resets sv_allowdownload on every map load via G_InitGame.
# g_mapConfigs makes UrT exec mapconfigs/<mapname>.cfg after each map loads,
# restoring sv_allowdownload to the configured value.
MAPCFG_DIR="${CONFIG_DIR}/mapconfigs"
mkdir -p "${MAPCFG_DIR}"

# Collect map names from the rotation file + any extras listed in URT_EXTRA_MAPS
ROTATION_MAPS=""
if [[ -f "${CONFIG_DIR}/maprotation.cfg" ]]; then
    ROTATION_MAPS=$(grep -oP '(?<=map )\w+' "${CONFIG_DIR}/maprotation.cfg" 2>/dev/null || true)
fi

for mapname in ${ROTATION_MAPS} ${URT_EXTRA_MAPS}; do
    [[ -z "${mapname}" ]] && continue
    echo "set sv_allowdownload ${URT_ALLOW_DOWNLOAD}" > "${MAPCFG_DIR}/${mapname}.cfg"
done

echo "[UrT] Mapconfigs written to ${MAPCFG_DIR}/"

# ── Patch q3config.cfg ────────────────────────────────────────────────────────
# The engine persists seta sv_allowdownload "0" in q3config.cfg from a previous
# install. Patch it now so the engine never reads the stale 0 value.
Q3CFG="${CONFIG_DIR}/q3config.cfg"
if [[ -f "${Q3CFG}" ]]; then
    sed -i 's/seta sv_allowdownload "0"/seta sv_allowdownload "1"/' "${Q3CFG}"
    echo "[UrT] Patched sv_allowdownload in q3config.cfg"
fi

# ── Launch server ─────────────────────────────────────────────────────────────
echo "[UrT] Starting Urban Terror dedicated server on port ${URT_PORT}..."
echo "[UrT] Game type: ${URT_GAMETYPE} | Max clients: ${URT_MAX_CLIENTS} | FPS: ${URT_FPS}"

exec "${SERVER_BIN}" \
    +set fs_basepath        "${GAME_DIR}" \
    +set fs_homepath        "${DATA_DIR}" \
    +set dedicated          "${URT_PUBLIC}" \
    +set net_port           "${URT_PORT}" \
    +exec                   server.cfg \
    +set sv_allowdownload   "${URT_ALLOW_DOWNLOAD}" \
    +vstr                   d1
