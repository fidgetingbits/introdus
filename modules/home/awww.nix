{
  lib,
  config,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = config.introdus.services.awww;
in
{
  options.introdus.services.awww = {
    enable = lib.mkEnableOption "Enable awww services";
    interval = lib.mkOption {
      type = lib.types.int;
      default = (60 * 60); # Hourly
      description = "Interval value for cycling between images";
    };

    cyclePerMonitor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set a different image per monitor";
    };

    transitionFPS = lib.mkOption {
      type = lib.types.int;
      default = 144;
      description = "Transition frames per second";
    };

    transitionStep = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Transition step value";
    };

    transitionTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "random" ];
      description = "Transition animation types";
    };

    transitionDuration = lib.mkOption {
      type = lib.types.float;
      default = 1.5;
      description = "Duration of animation";
    };

    transitionAngles = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = lib.genList (x: x * 15) (builtins.div 360 15);
      description = "Angle of transition for specific animations";
    };

    wallpaperDir = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to the directory of wallpaper images";
    };
  };

  config = lib.mkIf cfg.enable {
    services.swww.enable = true;
    # Delay starting so WAYLAND_DISPLAY is setup via uwsm
    systemd.user.services.swww = {
      Unit = {
        PartOf = [
          config.wayland.systemd.target
        ];
        After = [ config.wayland.systemd.target ];
      };
    };

    services.hyprpaper.enable = lib.mkForce false;
    stylix.targets.hyprpaper.enable = lib.mkForce false;

    programs.zsh.shellAliases = {
      # Skip current wallpaper
      awww-cycle = "systemctl --user kill --signal SIGUSR1 awww-cycle.service";
    };
    systemd.user.services.awww-cycle = lib.mkIf (cfg.wallpaperDir != "") {
      Unit = {
        Description = "Cycle wallpaper images using awww";
        PartOf = [ "swww.service" ];
        After = [ config.wayland.systemd.target ];
      };
      Install = {
        WantedBy = [ "swww.service" ];
      };

      Service =
        let
          awww-cycle = pkgs.writeShellApplication {
            name = "awww-cycle";
            runtimeInputs = lib.attrValues { inherit (pkgs) coreutils swww systemdMinimal; };
            text = ''
              function skip() {
                swww query | while read -r line; do
                  if [[ -z "$line" ]]; then
                      continue
                  fi
                  MONITOR_NAME=$(echo "$line" | cut -d ':' -f 1)
                  IMAGE_PATH=$(echo "$line" | awk '{print $NF}')
                  printf "%s skipped %s\n" "$MONITOR_NAME" "$IMAGE_PATH"
                done
                return
              }
              trap skip SIGUSR1

              function wait_awww() {
                echo "Checking awww daemon is up"
                # Since ConditionEnvironment=WAYLAND_DISPLAY doesn't want to work
                while ! systemctl --user show-environment | grep -q WAYLAND_DISPLAY; do
                    sleep 1;
                done

                # while ! swww query 2>/dev/null; do
                while ! swww query ; do
                  # Handle: 'Error: "Socket file not found. Are you sure swww-daemon is running?"'
                  sleep 1;
                done
                echo "awww daemon is accessible"
              }

              # Any args passed to set_image are passed directly to awww img
              function cycle_image() {
                  types=(${lib.concatStringsSep " " cfg.transitionTypes})
                  angles=(${lib.concatMapStringsSep " " (a: toString a) cfg.transitionAngles})
                  mapfile -t images < <(find ${cfg.wallpaperDir}/ -maxdepth 1)

                  # shellcheck disable=SC2068
                  if ! swww img $@ \
                    "''${images[RANDOM%''${#images[@]}]}" \
                    --transition-type "''${types[RANDOM%''${#types[@]}]}" \
                    --transition-fps ${toString cfg.transitionFPS} \
                    --transition-angle "''${angles[RANDOM%''${#angles[@]}]}" \
                    --transition-duration ${toString cfg.transitionDuration};
                  then
                    echo "awww went down? awww img call failed"
                    wait_awww
                  fi
              }

              wait_awww

              while true; do
                ${
                  if cfg.cyclePerMonitor then
                    ''
                      readarray -t monitors < <(swww query | cut -d ":" -f 2)
                      for m in "''${monitors[@]}"; do
                        cycle_image -o "$m"
                      done
                    ''
                  else
                    "cycle_image"
                }

                sleep ${toString cfg.interval}
                wait $!
              done
            '';
          };
        in
        {
          Type = "simple";
          Restart = "on-failure";
          # Restart = "always";
          # RestartSec = 1;
          ExecStart = "${lib.getExe pkgs.uwsm} app -- ${lib.getExe awww-cycle}";
        };

    };

    assertions = [
      {
        assertion = osConfig.programs.uwsm.enable;
        message = "awww-cycle requires uwsm to be enabled and used to start your window manager";
      }
    ];
  };

}
