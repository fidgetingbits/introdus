{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "yomitan-api";
  version = "0-unstable-2026-06-28";

  src = fetchFromGitHub {
    owner = "yomidevs";
    repo = "yomitan-api";
    rev = "d6a79d184062a048549fa8e82e3a880e2c2783e7";
    hash = "sha256-Xi4APBmsE8lU+BT13KvnaSeHxXzrz/2eMHmNHUiB7GE=";
  };

  buildInputs = [ python3 ];

  patches = [ ./yomitan-api-mutable-paths.patch ];

  postPatch = ''
    patchShebangs .
  '';

  # FIXME: the extension list should come as an arg
  installPhase = ''
    mkdir -p $out/bin $out/lib/mozilla/native-messaging-hosts
    cp yomitan_api.py $out/bin

    cat > $out/lib/mozilla/native-messaging-hosts/yomitan_api.json <<EOF
    {
        "name": "yomitan_api",
        "description": "Yomitan API",
        "type": "stdio",
        "path": "$out/bin/yomitan_api.py",
        "allowed_extensions": ["{6b733b82-9261-47ee-a595-2dda294a4d08}"]
    }
    EOF
  '';

  meta = {
    description = "Native messaging component for https://github.com/yomidevs/yomitan";
    homepage = "https://github.com/yomidevs/yomitan-api";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "yomitan-api.py";
    platforms = lib.platforms.all;
  };
})
