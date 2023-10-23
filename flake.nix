{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shape-predictor = pkgs.stdenv.mkDerivation {
          name = "shape-predictor-68-face-landmarks";
          src = pkgs.fetchurl {
            url = "http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2";
            hash = "sha256-fWY3uPNN2wwTY+CaRiiss0MUAZ7DVm/Wa4DATdppgPU=";
          };
          # nativeBuildInputs = [pkgs.bzip2];
          # dontUnpack = true;
          unpackCmd = "bunzip2 $curSrc -c > shape-predictor-68-face-landmarks.dat";
          sourceRoot = ".";
          installPhase = "cp shape-predictor-68-face-landmarks.dat $out";
        };
        python = pkgs.python3.withPackages (ps: [ ps.dlib ps.tqdm ps.numpy ps.matplotlib ]);
        writePython = buildPythonPackages: name: pkgs.writers.makeScriptWriter
          {
            inherit (python) interpreter; check = pkgs.lib.optionalString python.isPy3k (pkgs.writers.writeDash "pythoncheck.sh" ''
            exec ${buildPythonPackages.flake8}/bin/flake8 --show-source "$1"
          '');
          }
          name;
        writePythonBin = name: writePython pkgs.python3Packages "/bin/${name}";
        facestab-py = writePythonBin "facestab-py" (builtins.readFile ./facestab.py);
      in
      {
        packages = {
          inherit facestab-py;
          default = self.packages.${system}.facestab-py;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ python ];
          SHAPE_PREDICTOR = "${shape-predictor}";
        };
      });
}
