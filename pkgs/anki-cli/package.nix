{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
let
  fsrs = python3Packages.callPackage ../fsrs/package.nix { };
in
python3Packages.buildPythonApplication {
  pname = "anki-cli";
  version = "0.1.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ubermenchh";
    repo = "anki-cli";
    rev = "303c9e768ed259c4a4033b35f7f1758aab808b43";
    sha256 = "sha256-xMf2zf6YAet0NdNe9xx0pylDbqTrD+YHlj+6MugcjbM=";
  };

  build-system = [
    python3Packages.hatchling
  ];

  propagatedBuildInputs =
    lib.attrValues {
      inherit (python3Packages)
        click
        rich
        pydantic
        httpx
        betterproto
        pyperclip
        markdownify
        textual
        prompt-toolkit
        ;
    }
    ++ [
      fsrs
    ];

  # anki the gui also uses the name anki, so we need to rename
  postInstall = ''
    mv $out/bin/anki $out/bin/anki-cli
  '';

  doCheck = false;

  meta = {
    description = "Hybrid Anki CLI for humans and agents";
    homepage = "https://github.com/ubermenchh/anki-cli";
    license = lib.licenses.mit;
    mainProgram = "anki-cli";
    platforms = lib.platforms.unix;
  };
}
