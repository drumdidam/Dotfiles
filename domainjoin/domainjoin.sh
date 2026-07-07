#!/usr/bin/env bash
#
# domainjoin.sh — Arch Linux Active-Directory-Join via Samba/winbind
#
# Domain : INTERN.SALIGER.ME
# DC     : DC1.INTERN.SALIGER.ME
#
# Deployt die Konfigurationsdateien aus diesem Repo nach /etc, tritt der
# Domain bei und aktiviert die noetigen Dienste.
#
# Aufruf:  sudo ./domainjoin.sh [ADMIN-USER]
#          (ADMIN-USER default: administrator)

set -euo pipefail

# --- Konstanten -------------------------------------------------------------
REALM="INTERN.SALIGER.ME"
WORKGROUP="INTERN"
DC="DC1.INTERN.SALIGER.ME"
ADMIN_USER="${1:-administrator}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ETC_SRC="$SCRIPT_DIR/etc"
BACKUP_DIR="/root/domainjoin-backup-$(date +%Y%m%d-%H%M%S)"

# --- Helfer -----------------------------------------------------------------
info()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()   { printf '\033[1;31mXX\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Bitte als root ausfuehren (sudo $0)."
[[ -d $ETC_SRC ]] || die "Quellverzeichnis $ETC_SRC nicht gefunden."

# --- 1. Pakete --------------------------------------------------------------
info "Installiere benoetigte Pakete (samba, krb5)..."
pacman -S --needed --noconfirm samba krb5

# --- 2. Konfigurationsdateien deployen (mit Backup) -------------------------
info "Deploye Konfiguration nach /etc (Backup -> $BACKUP_DIR)..."
mkdir -p "$BACKUP_DIR"
while IFS= read -r -d '' src; do
    rel="${src#"$ETC_SRC"/}"          # z.B. samba/smb.conf
    dst="/etc/$rel"
    if [[ -e $dst ]]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        cp -a "$dst" "$BACKUP_DIR/$rel"
    fi
    install -Dm644 "$src" "$dst"
    printf '   %s\n' "$dst"
done < <(find "$ETC_SRC" -type f -print0)

# --- 3. DNS-Check -----------------------------------------------------------
# Fuer den Join muss der Domaincontroller aufloesbar sein. resolv.conf wird
# von NetworkManager verwaltet und daher hier NICHT ueberschrieben.
info "Pruefe DNS-Aufloesung des DC ($DC)..."
if ! host "$DC" >/dev/null 2>&1 && ! nslookup "$DC" >/dev/null 2>&1; then
    warn "$DC ist nicht aufloesbar."
    warn "Stelle sicher, dass ein Domain-DNS-Server aktiv ist, z.B. via NetworkManager:"
    warn "  nmcli con mod <verbindung> ipv4.dns 192.168.178.102 ipv4.ignore-auto-dns yes"
    warn "  nmcli con up <verbindung>"
    read -rp "Trotzdem fortfahren? [y/N] " a; [[ ${a,,} == y ]] || die "Abgebrochen."
fi

# --- 4. Zeitsynchronisation -------------------------------------------------
# Kerberos vertraegt max. ~5 Min Zeitabweichung.
info "Aktiviere Zeitsynchronisation (systemd-timesyncd)..."
timedatectl set-ntp true || warn "Konnte NTP nicht aktivieren."

# --- 5. Kerberos-Ticket holen ----------------------------------------------
info "Hole Kerberos-Ticket fuer $ADMIN_USER@$REALM..."
kinit "$ADMIN_USER@$REALM" || die "kinit fehlgeschlagen."

# --- 6. Domain beitreten ----------------------------------------------------
info "Trete Domain $REALM bei..."
net ads join -U "$ADMIN_USER" || die "Domain-Join fehlgeschlagen."

# --- 7. Dienste aktivieren --------------------------------------------------
info "Aktiviere Dienste (smb, nmb, winbind)..."
systemctl enable --now smb nmb winbind

# --- 8. Verifikation --------------------------------------------------------
info "Verifiziere Join..."
net ads testjoin && info "testjoin OK." || warn "testjoin fehlgeschlagen."
echo "--- Domain-User (wbinfo -u | head) ---"
wbinfo -u 2>/dev/null | head || warn "wbinfo -u lieferte keine User."
echo "--- getent passwd (Domain) ---"
getent passwd | grep -i "$WORKGROUP" | head || true

info "Fertig. Backup der ersetzten Dateien: $BACKUP_DIR"
info "Zum Testen z.B.:  su - <domain-user>   oder abmelden und mit Domain-Konto anmelden."
