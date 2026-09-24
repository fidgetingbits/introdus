{
  curl,
  lib,
  stdenv,
  stdenvNoCC,
  electron,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  ffmpeg,
  mpv-unwrapped,
}:
let
  version = "1.1.0";
  rawSrc = fetchFromGitHub {
    owner = "brenoaqua";
    repo = "yomipv";
    rev = "v${version}";
    sha256 = "sha256-iwEkkGM5zGbSGrlbxedof6An8YYs9m1BIQS2Teqs/3Y=";
  };

  lookup-app = buildNpmPackage rec {
    pname = "lookup-app";
    src = rawSrc;
    inherit version;
    sourceRoot = "source/scripts/yomipv/lookup-app";

    npmDepsHash = "sha256-DchyEC/SmQhSfpnSME92J1K43cslRGlz7YQDmpiTSBE=";

    npmRebuildFlags = [ "--ignore-scripts" ];

    dontNpmBuild = true;

    preConfigure = ''
      export ELECTRON_SKIP_BINARY_DOWNLOAD=1
    '';

    nativeBuildInputs = [
      makeWrapper
    ];

    installPhase = ''
      runHook preInstall

      ${lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p $out/share/${pname}/app
        cp -r . $out/share/${pname}/app

        makeWrapper ${lib.getExe electron} $out/bin/${pname} \
            --add-flags $out/share/${pname}/app \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
            --inherit-argv0
      ''}

      runHook postInstall
    '';
  };
  excludedPath = "${rawSrc}/scripts/yomipv/lookup-app";
in
stdenvNoCC.mkDerivation rec {
  # buildLua {
  pname = "yomipv";

  src = lib.sources.cleanSourceWith {
    src = "${rawSrc}/scripts/yomipv";
    filter = path: type: !(lib.hasPrefix excludedPath path);
  };
  inherit version;

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    substituteInPlace lib/launcher.lua \
      --replace-fail 'local app_path = "lookup-app"' 'local app_path = "${lookup-app}/bin/lookup-app"'

    if [ -f lib/platform.lua ]; then
      substituteInPlace lib/platform.lua \
        --replace-fail '"curl"' '"${lib.getExe curl}"'
    fi

    # MediaUtils.resolve_binary is only used to call ffmpeg and mpv, so just hardcode paths
    substituteInPlace media/helpers.lua \
      --replace-fail \
        'function MediaUtils.resolve_binary(binary_name)' \
        'function MediaUtils.resolve_binary(binary_name)
           if binary_name == "ffmpeg" then return "${lib.getExe ffmpeg}" end
           if binary_name == "mpv" then return "${lib.getExe mpv-unwrapped}" end'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mpv/scripts/yomipv
    cp -r . $out/share/mpv/scripts/yomipv/

    mkdir -p $out/share/mpv/script-opts
    cp -r ${rawSrc}/script-opts/* $out/share/mpv/script-opts/

    runHook postInstall
  '';

  passthru.scriptName = "main.lua";

  meta = {
    description = "An immersion-focused workflow for looking up and mining words without leaving MPV";
    homepage = "https://github.com/BrenoAqua/Yomipv";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ fidgetingbits ];
    platforms = lib.platforms.all;
  };
}
