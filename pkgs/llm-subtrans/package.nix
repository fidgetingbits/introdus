{
  lib,
  python3Packages,
  fetchFromGitHub,
  makeWrapper,

  # Optional provider feature flags (defaults to false for light base footprint)
  withGui ? false,
  withOpenai ? true, # Default true for NVIDIA NIM / OpenRouter compatibility
  withClaude ? false,
  withGemini ? false,
  withMistral ? false,
  withBedrock ? false,
  withLitellm ? false,
  withQwenAsr ? false,
}:

let
  # Collect optional packages based on explicit flag toggles
  optionalDeps =
    lib.optionals withGui (
      with python3Packages;
      [
        darkdetect
        pyside6
      ]
    )
    ++ lib.optionals withOpenai [ python3Packages.openai ]
    ++ lib.optionals withClaude [ python3Packages.anthropic ]
    ++ lib.optionals withGemini (
      with python3Packages;
      [
        google-genai
        google-api-core
      ]
    )
    ++ lib.optionals withMistral [ python3Packages.mistralai ]
    ++ lib.optionals withBedrock [ python3Packages.boto3 ]
    ++ lib.optionals withLitellm [ python3Packages.litellm ]
    ++ lib.optionals withQwenAsr [ python3Packages.qwen-asr ];
in
python3Packages.buildPythonPackage rec {
  pname = "llm-subtrans";
  version = "1.7.1";
  pyproject = true;

  disabled = python3Packages.pythonOlder "3.10";

  src = fetchFromGitHub {
    owner = "machinewrapped";
    repo = "llm-subtrans";
    rev = "v${version}";
    hash = "sha256-xGW1Q33VWCWRmf5B3JPzMF/+ihs4RFJGcNB7rUnpo7w=";
  };

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  dependencies =
    (with python3Packages; [
      python-dotenv
      srt
      pysubs2
      regex
      babel
      appdirs
      blinker
      requests
      httpx
    ])
    ++ optionalDeps;

  nativeBuildInputs = [ makeWrapper ];

  passthru.optional-dependencies = {
    gui = with python3Packages; [
      darkdetect
      pyside6
    ];
    openai = [ python3Packages.openai ];
    azure = [ python3Packages.openai ];
    claude = [ python3Packages.anthropic ];
    gemini = with python3Packages; [
      google-genai
      google-api-core
    ];
    mistral = [ python3Packages.mistralai ];
    bedrock = [ python3Packages.boto3 ];
    litellm = [ python3Packages.litellm ];
    qwen-asr = [ python3Packages.qwen-asr ];
  };

  pythonImportsCheck = [ "PySubtrans" ];

  postInstall = ''
    SITE_PKGS="$out/${python3Packages.python.sitePackages}"
    mkdir -p $out/bin

    if [ -d "scripts" ]; then
      cp -r scripts "$SITE_PKGS/"
    fi
    if [ -f "check_imports.py" ]; then
      cp check_imports.py "$SITE_PKGS/"
    fi

    PY_PATH="$SITE_PKGS:$SITE_PKGS/scripts:${python3Packages.makePythonPath dependencies}"

    makeWrapper ${python3Packages.python.interpreter} $out/bin/llm-subtrans \
      --prefix PYTHONPATH : "$PY_PATH" \
      --add-flags "$SITE_PKGS/scripts/llm-subtrans.py"

    # 4. Optional wrapper for the GUI
    ${lib.optionalString withGui ''
      makeWrapper ${python3Packages.python.interpreter} $out/bin/gui-subtrans \
        --prefix PYTHONPATH : "$PY_PATH" \
        --add-flags "-m GuiSubtrans.GUI"
    ''}
  '';

  meta = with lib; {
    description = "Subtitle translation tools using large language models";
    homepage = "https://github.com/machinewrapped/llm-subtrans";
    license = licenses.mit;
    mainProgram = "pysubtrans";
    platforms = platforms.unix;
  };
}
