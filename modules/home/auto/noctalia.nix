{
  config,
  lib,
  pkgs,
  ...
}:
let
  noctalia-snapshot-settings = pkgs.writeShellApplication {
    name = "noctalia-snapshot-settings";
    runtimeInputs = lib.attrValues {
      inherit (pkgs)
        coreutils
        gawk
        jq
        ;
    };
    text =
      # bash
      ''
        MAX_BACKUPS=5
        DEST_DIR="${config.home.homeDirectory}/.cache/noctalia/backup"
        CURRENT_SETTINGS=$(${lib.getExe config.programs.noctalia-shell.package} ipc call state all | \
          jq -S .settings)
        CURRENT_HASH=$(echo "$CURRENT_SETTINGS" | sha256sum | awk '{print $1}')
        CONFIG_HASH=$(sha256sum ${config.home.homeDirectory}/.config/noctalia/settings.json | awk '{print $1}')
        mkdir -p "$DEST_DIR" || true
        if [ "$CURRENT_HASH" != "$CONFIG_HASH" ]; then
          if ls "$DEST_DIR"/settings_*.json 2>/dev/null; then
              # shellcheck disable=SC2012
              LAST_SAVE=$(ls -t "$DEST_DIR"/settings_*.json | head -1)
          fi
          if [ "''${LAST_SAVE:-}" != "" ]; then
            LAST_HASH=$(sha256sum "$LAST_SAVE" | awk '{print $1}')
            if [ "$LAST_HASH" == "$CURRENT_HASH" ]; then
              # Already saved this change
              exit 0
            fi
          fi
          echo "Detected updated settings. Snapshotting"
          echo "$CURRENT_SETTINGS" > "$DEST_DIR"/settings_"$(date +%Y%m%d_%H%M%S)".json
          # Trim oldest one if necessary
          # shellcheck disable=SC2012
          ls -t "$DEST_DIR"/settings_*.json | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm
        fi
      '';
  };
in
lib.mkIf (config.programs ? "noctalia-shell" && config.programs.noctalia-shell.enable) {
  # A timer to periodically save noctalia-settings so that in the event of a
  # crash, reboot, etc whatever settings were changed can be retained and still
  # ported to nix after.
  systemd.user.timers."noctalia-snapshot-settings" = {
    Unit = {
      Description = "Save any noctalia settings changes";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
    Timer = {
      # man systemd.time
      # systemd-analyze calendar --iterations=8 '*:5/10'
      OnCalendar = "*:5/10"; # Every 5 minutes
    };
  };

  systemd.user.services."noctalia-snapshot-settings" = {
    Unit = {
      Description = "Service to check for and snapshot noctalia settings changes";
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe noctalia-snapshot-settings;
    };
  };
}
