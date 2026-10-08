#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

trap 'echo "Backup stopped at line $LINENO. Check the error above." >&2' ERR

# Check tools and OneDrive connection before creating the backup.
for tool in dnf tar rclone sha256sum; do
    if ! command -v "$tool" >/dev/null; then
        echo "Missing required tool: $tool" >&2
        exit 1
    fi
done

echo "Checking OneDrive connection..."
rclone lsd onedrive: >/dev/null
sudo -v

backup_dir="$HOME/Fedora-Backups/$(date +%Y-%m-%d_%H%M%S)"
mkdir -p "$backup_dir"

# GNU tar returns 1 if files change during a live backup.
archive() {
    local status=0
    "$@" || status=$?

    if (( status == 1 )); then
        echo "Some files changed during backup. See tar warnings above." >&2
    elif (( status != 0 )); then
        return "$status"
    fi
}

echo "Saving package lists..."

dnf repoquery --userinstalled \
    --queryformat '%{name}.%{arch}' \
    | sort -u > "$backup_dir/packages-reinstall.txt"

dnf repoquery --installed \
    --queryformat '%{name}.%{arch} %{evr} %{from_repo}' \
    > "$backup_dir/packages-full.txt"

dnf repolist --all > "$backup_dir/repositories.txt"
cp /etc/os-release "$backup_dir/fedora-version.txt"

if command -v flatpak >/dev/null; then
    flatpak list --app --columns=application,origin,installation \
        > "$backup_dir/flatpak-apps.txt"

    flatpak remotes --show-details \
        > "$backup_dir/flatpak-remotes.txt"
fi

echo "Backing up user settings, themes, fonts and scripts..."

home_items=()
for item in \
    .config .local/share .local/bin .local/state \
    .themes .icons .fonts .oh-my-zsh \
    .zshrc .zprofile .bashrc .bash_profile \
    .profile .p10k.zsh .gitconfig bin Applications
do
    if [[ -e "$HOME/$item" || -L "$HOME/$item" ]]; then
        home_items+=("$item")
    fi
done

archive tar --acls --xattrs \
    --exclude='.local/share/Trash' \
    --exclude='.local/share/Steam' \
    --exclude='.local/share/flatpak' \
    -czf "$backup_dir/home-settings.tar.gz" \
    -C "$HOME" "${home_items[@]}"

# Preserve this backup script too.
cp -- "${BASH_SOURCE[0]}" "$backup_dir/fedora-backup.sh"

echo "Backing up system settings and manually installed software..."

system_items=()
for item in etc usr/local opt usr/src var/lib/dkms; do
    [[ -e "/$item" ]] && system_items+=("$item")
done

archive sudo tar --acls --xattrs \
    -czf "$backup_dir/system-reference.tar.gz" \
    -C / "${system_items[@]}"

sudo chown "$(id -u):$(id -g)" \
    "$backup_dir/system-reference.tar.gz"
chmod 600 "$backup_dir/system-reference.tar.gz"

cat > "$backup_dir/RESTORE.txt" <<'EOF'
FEDORA RESTORE NOTES

1. Install Fedora and enable the required third-party repositories.
   Consult repositories.txt and packages-full.txt.

2. Reinstall RPM packages:
   xargs -r -a packages-reinstall.txt sudo dnf install

3. Verify downloaded archives:
   sha256sum -c SHA256SUMS

4. Restore user settings while logged out of Plasma.
   Run as your normal user from a text console:
   tar --acls --xattrs -xzf home-settings.tar.gz -C "$HOME"

5. Use flatpak-apps.txt and flatpak-remotes.txt to reinstall Flatpaks.

6. Extract system-reference.tar.gz into a separate review folder.
   Do NOT extract the entire archive over a fresh system.
   Review and restore individual system customizations as needed.
   Compiled plugins may need rebuilding for the new KWin version.

COVERAGE
Includes selected home settings and application data, plus:
  /etc /usr/local /opt /usr/src /var/lib/dkms

Excludes Steam data, Flatpak installations and Trash.
Does not cover all documents, photos, browser profiles, source repositories
or AppImages stored elsewhere in your home directory.
Package-owned custom edits elsewhere under /usr are not included.
Archives contain private configuration and may contain credentials.
EOF

echo "Verifying archives..."

tar -tzf "$backup_dir/home-settings.tar.gz" >/dev/null
tar -tzf "$backup_dir/system-reference.tar.gz" >/dev/null

(
    cd "$backup_dir"
    sha256sum home-settings.tar.gz system-reference.tar.gz \
        > SHA256SUMS
)

remote_dir="onedrive:Fedora-Backups/$(basename "$backup_dir")"

echo "Uploading to OneDrive..."
rclone copy "$backup_dir" "$remote_dir" --progress

echo "Checking uploaded files..."
rclone check "$backup_dir" "$remote_dir" --one-way

echo
echo "Backup complete."
echo "Local copy: $backup_dir"
echo "OneDrive:   $remote_dir"
