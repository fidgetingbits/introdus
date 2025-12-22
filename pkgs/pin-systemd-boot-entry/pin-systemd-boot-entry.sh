#!/usr/bin/env bash
# Pins the current nixos generation of a host to the systemd-boot loader menu
#
# This expects your nixos configuration has an entry for picking up the pinned entry, similar to this:
#
# ```nix
#  boot.loader.systemd-boot = {
#    enable = true;
#    # Pin a stable boot entry. In order to generate the pinned-boot-entry.conf
#    # for a "stable" generation run 'just pin'.
#    extraEntries =
#      let
#        pinned = lib.custom.relativeToRoot "hosts/nixos/${config.hostSpec.hostName}/pinned-boot-entry.conf";
#      in
#      lib.optionalAttrs (config.boot.loader.systemd-boot.enable && lib.pathExists pinned) {
#        "pinned-stable.conf" = lib.readFile pinned;
#      };
#  };
# ```

shopt -u expand_aliases
set -eu
HOST="${1-$(hostname)}"

cp_cmd='cp '
if [ "$HOST" != "$(hostname)" ]; then
    cmd_prefix="ssh $HOST"
    cp_cmd="scp $HOST:"
fi

if [ ! -e "hosts/nixos/$HOST/" ]; then
    red "ERROR: there is no $HOST host in this config. "
    red "Pinning expects to be done in a nixos configuration with a hosts/nixos/$HOST folder"
    exit 1
fi

# Create a modified copy of the current systemd-boot entry and denote it as pinned
CURRENT=$(${cmd_prefix:-} sudo nix-env --list-generations --profile /nix/var/nix/profiles/system |
    rg current |
    awk '{print $1}')

if [[ -z $CURRENT ]]; then
    red "ERROR: Failed to find nixos generation."
    exit 1
fi
PINNED="hosts/nixos/$HOST/pinned-boot-entry.conf"
CURRENT_FILE="/boot/loader/entries/nixos-generation-$CURRENT.conf"

if [ -e "$PINNED" ] && rg -q "Generation $CURRENT NixOS" "$PINNED"; then
    yellow "WARNING: Nothing to do. Generation $CURRENT is already pinned"
    exit 0
fi

green "INFO: Setting up pin for generation $CURRENT"

# shellcheck disable=SC2086
${cp_cmd}"$CURRENT_FILE" "$PINNED"
chmod -x "$PINNED"
VERSION=$(grep version "$PINNED" | cut -f2- -d' ')
sed -i "s/sort-key nixos/sort-key pinned/;
        s/title.*/title PINNED: $VERSION/" \
    "$PINNED"

# Set the new root to prevent garbage collection
PINNED_ROOT="/nix/var/nix/gcroots/pinned-$HOST"
${cmd_prefix:-} sudo nix-store --add-root "$PINNED_ROOT" -r /nix/var/nix/profiles/system >/dev/null

if git diff-index --cached --quiet HEAD; then
    if gum confirm "Commit change?"; then
        git add "$PINNED"
        git commit -m "chore: pin $HOST boot entry for generation $CURRENT"
        green "Pinned generation $CURRENT to $PINNED_ROOT"
    fi
else
    yellow "WARNING: git repo already has staged files"
    yellow "\tWon't automatically commit: $PINNED"
fi

# Rebuild in order for the newly pinned generation to populate in systemd-boot,
if gum confirm "Rebuild host with new pin"; then
    green "Rebuilding $HOST to populate boot entry..." && sleep 2
    just rebuild "$HOST"
fi
