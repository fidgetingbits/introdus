{
  lib,
  python312Packages,
  ffmpeg,
  makeWrapper,
}:

python312Packages.buildPythonApplication rec {
  pname = "ownscribe";
  version = "0.15.0";
  pyproject = true;

  # Point to your source directory or fetchFromGitHub
  src = ./.;

  # Build backend hook specified in pyproject.toml ([build-system])
  build-system = [
    python312Packages.uv-build
  ];

  # Python runtime dependencies listed in [project.dependencies]
  dependencies = lib.attrValues {
    inherit (python312Packages)
      click
      sounddevice
      soundfile
      whisperx
      pyannote-audio
      torchaudio
      llama-cpp-python
      huggingface-hub
      ;
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  # Non-Python runtime dependency
  buildInputs = [
    ffmpeg
  ];

  # Ensure ffmpeg is available in PATH when ownscribe runs
  postInstall = ''
    wrapProgram $out/bin/ownscribe \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}
  '';

  # Disable tests during build if audio hardware/macOS is needed,
  # or configure pytest CheckHook
  doCheck = false;

  pythonImportsCheck = [
    "ownscribe"
  ];

  meta = {
    description = "Fully local meeting transcription and summarization CLI";
    homepage = "https://github.com/paberr/ownscribe";
    license = lib.licenses.mit;
    mainProgram = "ownscribe";
    maintainers = [ ];
  };
}
