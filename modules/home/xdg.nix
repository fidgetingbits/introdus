# NOTE: Associations that are proprietary and/or specific to a single applications
# should be declared in the application specific modules.
# For example, "x-scheme-handler/sgnl" is unique to the signal-desktop app and is
# therefore declared in `introdus/modules/home/signal/`
{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = config.introdus.xdg;
in
{
  options.introdus.xdg = {
    enable = lib.mkEnableOption "Enable xdg settings";
    csvAssociations = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "${osConfig.hostSpec.defaultEditor}.desktop" ];
      example = [
        "libreoffice-calc.desktop"
        "nvim.desktop"
      ];
      description = ''
        Applications specific to csv file association. Allows
                  association with editor or spreadsheet application.'';
    };
    browsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "${osConfig.hostSpec.defaultBrowser}.desktop" ];
      example = [
        "firefox.desktop"
        "brave-browser.desktop"
      ];
      description = ''
        List of browsers to make file type associations with. XDG
                  attempts to launch associated apps in list order.'';
    };
    editors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "${osConfig.hostSpec.defaultEditor}.desktop" ];
      example = [
        "nvim.desktop"
        "code.desktop"
      ];
      description = ''
        List of editors to make file type associations with. XDG
                  attempts to launch associated apps in list order.'';
    };
    mediaPlayers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "vlc.desktop" ];
      example = [
        "vlc.desktop"
        "mpv.desktop"
      ];
      description = ''
        List of media players to make file type associations with.
                  XDG attempts to launch associated apps in list order.'';
    };
    writers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "libreoffice-writer.desktop" ];
      example = [
        "libreoffice-writer.desktop"
        "okular.desktop"
      ];
      description = ''
        List of document writers (for .odt, .doc, etc.) to make
                  file type associations with. XDG attempts to launch associated apps in
                  list order.'';
    };
    spreadsheets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "libreoffice-calc.desktop" ];
      example = [
        "libreoffice-writer.desktop"
      ];
      description = ''
        List of spreadsheet editors to make file type associations
                  with. XDG attempts to launch associated apps in list order.'';
    };
    slidedecks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "libreoffice-impress.desktop" ];
      example = [
        "libreoffice-impress.desktop"
      ];
      description = ''
        List of slidedeck editors to make file type associations
                  with. XDG attempts to launch associated apps in list order.'';
    };
    mathapps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "libreoffice-math.desktop" ];
      example = [
        "libreoffice-math.desktop"
      ];
      description = ''
        List of math applications to make file type associations
                  with. XDG attempts to launch associated apps in list order.'';
    };
  };

  config =
    let
      # Extensive list of associations here:
      # https://github.com/iggut/GamiNiX/blob/80;hjj70528de419703e13b4d234ef39f05966a7fafb/system/desktop/home-main.nix#L77
      mimetypes = {
        editors = [
          "text/english"
          "text/markdown"
          "text/plain"
          "text/x-c"
          "text/x-c++"
          "text/x-c++hdr"
          "text/x-c++src"
          "text/x-chdr"
          "text/x-csrc"
          "text/x-java"
          "text/x-makefile"
          "text/x-moc"
          "text/x-pascal"
          "text/x-tcl"
          "text/x-tex"
          "application/x-zerosize"
          "application/x-shellscript"
          "application/x-perl"
          "application/json"
        ];
        browsers = [
          "image/*"
          "text/html"
          "text/xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "application/x-extension-htm"
          "application/x-extension-html"
          "application/x-extension-shtml"
          "application/xhtml+xml"
          "application/x-extension-xhtml"
          "application/x-extension-xht"
          "application/pdf"
        ];
        mediaPlayers = [
          "application/mxf"
          "application/ogg"
          "application/sdp"
          "application/smil"
          "application/streamingmedia"
          "application/vnd.apple.mpegurl"
          "application/vnd.ms-asf"
          "application/vnd.rn-realmedia"
          "application/vnd.rn-realmedia-vbr"
          "application/x-cue"
          "application/x-extension-m4a"
          "application/x-extension-mp4"
          "application/x-matroska"
          "application/x-mpegurl"
          "application/x-ogg"
          "application/x-ogm"
          "application/x-ogm-audio"
          "application/x-ogm-video"
          "application/x-shorten"
          "application/x-smil"
          "application/x-streamingmedia"
          "audio/3gpp"
          "audio/3gpp2"
          "audio/AMR"
          "audio/aac"
          "audio/ac3"
          "audio/aiff"
          "audio/amr-wb"
          "audio/dv"
          "audio/eac3"
          "audio/flac"
          "audio/m3u"
          "audio/m4a"
          "audio/mp1"
          "audio/mp2"
          "audio/mp3"
          "audio/mp4"
          "audio/mpeg"
          "audio/mpeg2"
          "audio/mpeg3"
          "audio/mpegurl"
          "audio/mpg"
          "audio/musepack"
          "audio/ogg"
          "audio/opus"
          "audio/rn-mpeg"
          "audio/scpls"
          "audio/vnd.dolby.heaac.1"
          "audio/vnd.dolby.heaac.2"
          "audio/vnd.dts"
          "audio/vnd.dts.hd"
          "audio/vnd.rn-realaudio"
          "audio/vorbis"
          "audio/wav"
          "audio/webm"
          "audio/x-aac"
          "audio/x-adpcm"
          "audio/x-aiff"
          "audio/x-ape"
          "audio/x-m4a"
          "audio/x-matroska"
          "audio/x-mp1"
          "audio/x-mp2"
          "audio/x-mp3"
          "audio/x-mpegurl"
          "audio/x-mpg"
          "audio/x-ms-asf"
          "audio/x-ms-wma"
          "audio/x-musepack"
          "audio/x-pls"
          "audio/x-pn-au"
          "audio/x-pn-realaudio"
          "audio/x-pn-wav"
          "audio/x-pn-windows-pcm"
          "audio/x-realaudio"
          "audio/x-scpls"
          "audio/x-shorten"
          "audio/x-tta"
          "audio/x-vorbis"
          "audio/x-vorbis+ogg"
          "audio/x-wav"
          "audio/x-wavpack"
          "video/3gp"
          "video/3gpp"
          "video/3gpp2"
          "video/avi"
          "video/divx"
          "video/dv"
          "video/fli"
          "video/flv"
          "video/mkv"
          "video/mp2t"
          "video/mp4"
          "video/mp4v-es"
          "video/mpeg"
          "video/msvideo"
          "video/ogg"
          "video/quicktime"
          "video/vnd.divx"
          "video/vnd.mpegurl"
          "video/vnd.rn-realvideo"
          "video/webm"
          "video/x-avi"
          "video/x-flc"
          "video/x-flic"
          "video/x-flv"
          "video/x-m4v"
          "video/x-matroska"
          "video/x-mpeg2"
          "video/x-mpeg3"
          "video/x-ms-afs"
          "video/x-ms-asf"
          "video/x-ms-wmv"
          "video/x-ms-wmx"
          "video/x-ms-wvxvideo"
          "video/x-msvideo"
          "video/x-ogm"
          "video/x-ogm+ogg"
          "video/x-theora"
          "video/x-theora+ogg"
        ];
        spreadsheets = [
          "text/csv"
          "application/vnd.ms-excel"
          "application/vnd.oasis.opendocument.spreadsheet"
          "application/vnd.oasis.opendocument.spreadsheet-template"
          "application/vnd.sun.xml.calc"
          "application/vnd.sun.xml.calc.template"
          "application/vnd.stardivision.calc"
        ];
        writers = [
          "application/vnd.ms-word"
          "application/vnd.oasis.opendocument.text"
          "application/vnd.oasis.opendocument.text-master"
          "application/vnd.oasis.opendocument.text-template"
          "application/vnd.oasis.opendocument.text-web"
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
          "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
          "application/vnd.sun.xml.writer"
          "application/vnd.stardivision.writer"
          "application/vnd.sun.xml.writer.global"
          "application/vnd.sun.xml.writer.template"
          "application/vnd.wordperfect"
        ];
        slidedecks = [
          "application/vnd.ms-powerpoint"
          "application/vnd.oasis.opendocument.presentation"
          "application/vnd.oasis.opendocument.presentation-template"
          "application/vnd.openxmlformats-officedocument.presentationml.presentation"
          "application/vnd.openxmlformats-officedocument.presentationml.template"
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
          "application/vnd.stardivision.impress"
          "application/vnd.sun.xml.impress"
          "application/vnd.sun.xml.impress.template"
        ];
      };

      mapTypesToApps = apps: mimetypes: lib.map (type: { "${type}" = apps; }) mimetypes;

      associations =
        lib.attrNames mimetypes
        |> lib.map (n: mapTypesToApps cfg.${n} mimetypes.${n})
        |> lib.flatten
        |> lib.mergeAttrsList;

      finalAssociations = associations // {
        "application/vnd.jgraph.mxfile" = [ "drawio.desktop" ];
        "application/vnd.jgraph.mxfile.realtime" = [ "drawio.desktop" ];
      };

      removals = {
        "application/vnd.oasis.opendocument.text" = [
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
          "calibre-gui.desktop"
        ];
      };
    in
    lib.mkIf cfg.enable {

      xdg = {
        mime.enable = true;
        mimeApps = {
          enable = true;
          defaultApplications = finalAssociations;
          associations.added = finalAssociations;
          associations.removed = removals;
        };

        #
        # Handle `mimeapps.list` collisions
        #
        # Sometimes applications will modify the mimeapps.list on their own
        # (e.g. libreoffice) and that prevents home-manager from writing to
        # the file on rebuild. The failure will stop home-manager from reloading
        # properly and the message to stdout isn't always obvious. This setting
        # allows home-manager to clobber whatever was written to the file.
        configFile."mimeapps.list" = lib.mkIf config.xdg.mimeApps.enable {
          force = true;
        };

        # https://discourse.nixos.org/t/no-such-interface-org-freedesktop-portal-settings/67701/6
        # Fix "No such interface "org.freedesktop.portal.RemoteDesktop"
        # warnings in waybar and similar
        portal =
          let
            portalNames = lib.attrValues {
              inherit (pkgs)
                xdg-desktop-portal
                xdg-desktop-portal-gtk
                xdg-desktop-portal-gnome # required for screencasting in niri
                ;
            };
          in
          {
            enable = true;
            extraPortals = portalNames;
            configPackages = portalNames;
          };
      };

      home.packages = lib.attrValues {
        inherit (pkgs)
          handlr-regex # better xdg-open for desktop apps
          ;
      };
    };
}
