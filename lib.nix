{ nixpkgs }: rec {
    buildPandocEnv = { system, fonts ? (pkgs: []), extraBuildInputs ? (pkgs: []) }:
      let pkgs = import nixpkgs { inherit system; };
          texlive-combined = with pkgs; [(texlive.combine {
            inherit (texlive) scheme-medium collection-latexextra;
          })];
          buildInputs = (with pkgs; [
            texlive-combined
            pandoc
            haskellPackages.pandoc-crossref
          ]) ++ (extraBuildInputs pkgs);
          selectedFonts = fonts pkgs;
          OSFONTDIR=builtins.concatStringsSep ":" selectedFonts;
          mkDerivation = attrs: pkgs.stdenvNoCC.mkDerivation (attrs // {
            inherit buildInputs
              OSFONTDIR;
          });
          cache = mkDerivation {
            name = "luaotfload-cache";
            TEXMFHOME=".cache";
            TEXMFVAR=".cache/texmf-var";
            unpackPhase = "true";
            buildPhase = ''
              luaotfload-tool --update
            '';
            installPhase = ''
              cp -r .cache $out
            '';
          };
      in {
        shell = pkgs.mkShell {
          inherit buildInputs;
          OSFONTDIR = builtins.concatStringsSep ":" selectedFonts;
        };
        mkDoc = {name, target, files, path}: mkDerivation {
          inherit name;
          src = builtins.path { inherit path; inherit name; };
          TEXMFHOME="${cache}";
          TEXMFVAR="${cache}/texmf-var";
          buildPhase = ''
            make ${target}
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
