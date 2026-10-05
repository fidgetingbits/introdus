{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  wheel,
  typing-extensions,
}:
buildPythonPackage rec {
  pname = "fsrs";
  version = "6.3.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-f+eZR865LKNf3KPfpRGiOb4VsxfN5j1mQ6LaYRCETZE=";
  };

  build-system = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    typing-extensions
  ];

  doCheck = false;

  meta = {
    description = "Free Spaced Repetition Scheduler";
    homepage = "https://github.com/open-spaced-repetition/py-fsrs";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
