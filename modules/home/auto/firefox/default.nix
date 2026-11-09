{
  inputs,
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  cfg = config.introdus.firefox;
in
{
  options.introdus.firefox = {
    profileID = lib.mkOption {
      description = "The value of firefox.profile.<*>.id which can be defined per host";
      type = lib.types.int;
      default = 0;
      example = 1;
    };
    profileName = lib.mkOption {
      description = "The value of firefox.profile.<*>.name which can be defined per host";
      type = lib.types.str;
      default = "default";
      example = "main";
    };
    extensions = lib.mkOption {
      description = "List of extra extensions to add, in addition to the introdus defaults";
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [ ];
      example = "[ (import ./extraExtensions.nix { inherit lib; }) ]";
    };
    search = lib.mkOption {
      description = "List of extra search engines to add, in addition to the introdus defaults";
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [ ];
      example = "[ (import ./extraSearch.nix { inherit lib; }) ]";
    };
    autoRestart = lib.mkOption {
      description = "Auto restart firefox if it is closed. Useful for media boxes, etc";
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf osConfig.hostSpec.useWindowManager (
    lib.mkMerge [
      {
        programs.firefox = {
          enable = true;
          # NOTE: configPath Set because stateVersion < 26.05
          configPath = "${config.xdg.configHome}/mozilla/firefox";
          # Refer to https://mozilla.github.io/policy-templates or `about:policies#documentation` in firefox
          policies = {
            AppAutoUpdate = false; # Disable automatic application update
            BackgroundAppUpdate = false; # Disable automatic application update in the background, when the application is not running.
            DefaultDownloadDirectory = "${homeDir}/downloads";
            DisableBuiltinPDFViewer = false;
            DisableFirefoxStudies = true;
            DisableFirefoxAccounts = false; # Enable Firefox Sync
            DisablePocket = true;
            DisableTelemetry = true;
            DisableFeedbackCommands = true;
            # To facilitate proper DNS filtering
            DNSOverHTTPS = {
              Enabled = false;
              Locked = true;
            };
            DontCheckDefaultBrowser = true;
            OfferToSaveLogins = false;
            HttpsOnlyMode = "force_enabled";
            StartDownloadsInTempDirectory = true; # Avoid failed download clutter
            UserMessaging = {
              ExtensionRecommendations = false;
              SkipOnboarding = true;
            };
            EnableTrackingProtection = {
              Value = true;
              Locked = true;
              Cryptomining = true;
              Fingerprinting = true;
              EmailTracking = true;
            };
            SearchBar = "unified";
            SearchEngines.Default = "DuckDuckGo";
            ExtensionUpdate = true;
            ExtensionSettings = {
              # Disable built-in search engines
              "amazondotcom@search.mozilla.org" = {
                installation_mode = "blocked";
              };
              "bing@search.mozilla.org" = {
                installation_mode = "blocked";
              };
              "ebay@search.mozilla.org" = {
                installation_mode = "blocked";
              };
              "google@search.mozilla.org" = {
                installation_mode = "blocked";
              };
              #  "*" = {
              #  installation_mode = "blocked";
              #  blocked_install_message = "Install your extensions with Nix";
              # };
            };
          };
          profiles =
            let
              commonSettings = {
                "signon.rememberSignons" = false; # Disable built-in password manager
                "browser.compactmode.show" = true;
                "browser.uidensity" = 1; # enable compact mode
                "browser.aboutConfig.showWarning" = false;
                "browser.download.dir" = "${homeDir}/downloads";
                "browser.startup.page" = 3; # restore previous session
                # Inline PDF viewing preserves the "Save As" dialog so users
                # can choose the save location, instead of auto-downloading
                # to a temp directory with no user interaction.
                "browser.download.open_pdf_attachments_inline" = true;

                "browser.tabs.firefox-view" = true; # Sync tabs across devices
                "ui.systemUsesDarkTheme" = 1; # force dark theme
                "extensions.pocket.enabled" = false;

                # Remove common fingerprinting vectors
                #"privacy.resistFingerprinting" = true; # https://support.mozilla.org/en-US/kb/firefox-protection-against-fingerprinting
                # Silo cookie storage
                # "privacy.firstparty.isolate" = true; # https://bugzilla.mozilla.org/show_bug.cgi?id=1260931

                # Disable prefetching of pages/sites
                "network.prefetch-next" = false;
                "network.dns.disablePrefetch" = true;
                "network.http.speculative-parallel-limit" = 0;

                # Reduce attack surface by disabling JIT, etc
                # "javascript.options.baselinejit" = false;
                # "javascript.options.ion" = false;
                # "javascript.options.wasm" = false;
                # "javascript.options.asmjs" = false;
                # "webgl.disabled" = true;

                # Disable alt to trigger file menu
                "ui.key.menuAccessKey" = 0;
                "ui.key.menuAccessKeyFocuses" = false;
              };
            in
            {
              default = {
                id = cfg.profileID;
                name = cfg.profileName;
                isDefault = true;
                settings = commonSettings;
                # Allow us to load javascript for some custom keybinds
                extraConfig = ''
                  user_pref("general.config.filename", "firefox.cfg");
                  user_pref("general.config.obscure_value", 0);
                '';
                extensions = lib.mkMerge (
                  lib.flatten [
                    (import ./extensions.nix { inherit pkgs inputs lib; })
                    cfg.extensions
                  ]
                );
                search = lib.mkMerge (
                  lib.flatten [
                    (import ./search.nix { inherit lib pkgs; })
                    cfg.search
                  ]
                );
              };
            };
        };

        # Keep firefox running if it's closed
        systemd.user.services = lib.optionalAttrs cfg.autoRestart {
          firefox = {
            Unit = {
              description = "Firefox Browser";
              After = [
                "graphical-session.target"
                "graphical-session-pre.target"
              ];
              PartOf = [ "graphical-session.target" ];
            };
            Install.WantedBy = [ "graphical-session.target" ];
            Service = {
              Type = "simple";
              ExecStart = "${config.home.homeDirectory}.nix-profile/bin/firefox";
              Restart = "always";
              RestartSec = 5;
            };
          };
        };

        # home.file.".mozilla/firefox/firefox.cfg".text = ''
        #   // Modern Firefox Autoconfig - First line must be a comment
        #   const { ChromeUtils } = globalThis;
        #   const { Services } = ChromeUtils.importESModule("resource://gre/modules/Services.sys.mjs");
        #
        #   function overrideSidebarShortcut(win) {
        #     win.addEventListener("DOMContentLoaded", () => {
        #       // Modern sidebar key elements
        #       let sidebarKey = win.document.getElementById("key_sidebar")
        #                     || win.document.getElementById("key_toggleSidebar")
        #                     || win.document.getElementById("viewBookmarksSidebarKb");
        #
        #       if (sidebarKey) {
        #         sidebarKey.setAttribute("key", "z");
        #         sidebarKey.setAttribute("modifiers", "control,alt");
        #       } else {
        #         // Fallback for newer sidebar architecture: attach listener directly to mainKeyset
        #         let mainKeyset = win.document.getElementById("mainKeyset");
        #         if (mainKeyset) {
        #           let newKey = win.document.createXULElement("key");
        #           newKey.setAttribute("id", "key_custom_sidebar_toggle");
        #           newKey.setAttribute("key", "z");
        #           newKey.setAttribute("modifiers", "control,alt");
        #           newKey.setAttribute("oncommand", "SidebarController.toggle();");
        #           mainKeyset.appendChild(newKey);
        #         }
        #       }
        #     }, { once: true });
        #   }
        #
        #   Services.obs.addObserver((subject) => {
        #     overrideSidebarShortcut(subject);
        #   }, "chrome-document-global-created", false);
        # '';
      }
      # shut up stylix warning about profile name
      (lib.mkIf osConfig.hostSpec.isAutoStyled {
        stylix.targets.firefox.profileNames = [
          cfg.profileName
        ];
      })
    ]
  );
}
