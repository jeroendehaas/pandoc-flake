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
          # Separating paths by colons or semicolons
          # did not work. This creates a single directory
          # from all font packages
          OSFONTDIR = pkgs.symlinkJoin {
            name = "combined-fonts";
            paths = fonts pkgs;
          };
          mkDerivation = attrs: pkgs.stdenvNoCC.mkDerivation (attrs // {
            inherit buildInputs
              OSFONTDIR;
            TEXMFHOME=".cache";
            TEXMFVAR=".cache/texmf-var";
          });
          # Sharing cache does not work yet
          #cache = mkDerivation {
          #  name = "luaotfload-cache";
          #  unpackPhase = "true";
          #  buildPhase = ''
          #    luaotfload-tool --update
          #  '';
          #  installPhase = ''
          #    cp -r .cache $out
          #  '';
          #};
      in {
        shell = pkgs.mkShell {
          inherit buildInputs OSFONTDIR;
        };
        mkDoc = {name, target, files, path}: mkDerivation {
          inherit name;
          src = builtins.path { inherit path; inherit name; };
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
