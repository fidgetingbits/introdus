# Tool for accessing cyberpunk 2077 media files. Used for creating anki
# deck to practice mandarin terms in game
# https://github.com/seveibar/cyberpunk-2077-mandarin-chinese-anki
#
# To initially generate the deps.json file I had to do the following. Building
# and running ./result was hanging on some arm64 thing
# ```
#  nix shell nixpkgs#dotnet-sdk_10 nixpkgs#nuget-to-json -c bash -c '
#   src_path=$(nix build --no-link --print-out-paths ../../#wolven-kit-cli.src)
#   work_dir=$(mktemp -d)
#   cp -r "$src_path"/* "$work_dir/"
#   chmod -R +w "$work_dir"
#
#   dotnet restore --packages pkgdir "$work_dir/WolvenKit.CLI/WolvenKit.CLI.csproj"
#   nuget-to-json pkgdir > ./deps.json
#   rm -rf pkgdir "$work_dir"
# '
# ```

{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
}:
buildDotnetModule rec {
  name = "wolven-kit-cli";
  version = "9.1.0";

  src = fetchFromGitHub {
    owner = "WolvenKit";
    repo = "WolvenKit";
    rev = version;
    sha256 = "sha256-KWsKNZV8Rc7ecwIyakb5Eq77adMwck7NlJKLkLtKBsg=";
  };

  projectFile = "WolvenKit.CLI/WolvenKit.CLI.csproj";
  nugetDeps = ./deps.json;
  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  runtimeIds = [ "linux-x64" ];

  meta = {
    homepage = "https://github.com/WolvenKit/WolvenKit";
    license = lib.licenses.agpl3Only;
    mainProgram = "WolvenKit.CLI";
  };
}
