{ nixpkgs }: rec {
    buildPandocEnv = { system, fonts ? (pkgs: []), extraBuildInputs ? (pkgs: []) }:
      let pkgs = import nixpkgs { inherit system; };
          texlive-combined = with pkgs; [(texlive.combine {
            inherit (texlive) scheme-medium collection-latexextra;
          })];
          buildInputs = (with pkgs; [
            texlive-combined
            gnumake
            pandoc
            haskellPackages.pandoc-crossref
          ]) ++ (extraBuildInputs pkgs);
          selectedFonts = fonts pkgs;
      in {
        shell = pkgs.mkShell {
          inherit buildInputs;
          OSFONTDIR = builtins.concatStringsSep ":" selectedFonts;
        };
        mkDoc = {name, target, files, path}: pkgs.stdenvNoCC.mkDerivation {
          inherit name;
          inherit buildInputs;
          src = builtins.path { inherit path; inherit name; };
          buildPhase = ''
            env OSFONTDIR=${builtins.concatStringsSep ":" selectedFonts} TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var make ${target}
          '';
          installPhase = ''
            mkdir -p $out
            cp -r ${builtins.concatStringsSep " " files} $out
          '';
        };

      };
    forDocs = { targets ? {},
                fonts ? (pkgs: []),
                extraBuildInputs ? (pkgs: [])}: system:
                  let env = buildPandocEnv { inherit system fonts extraBuildInputs; };
                  in {
                    devShell = env.shell;
                    packages = builtins.mapAttrs (name: params: env.mkDoc (params // {inherit name;})) targets;
                  };

}
