# Copyright (c) 2022, Jeroen de Haas
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
{
  description = "A template for building documents using Pandoc";

  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, flake-utils, ... }: {
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
                  let env = self.buildPandocEnv { inherit system fonts extraBuildInputs; };
                  in {
                    devShell = env.shell;
                    packages = builtins.mapAttrs (name: params: env.mkDoc (params // {inherit name;})) targets;
                  };
    checks = flake-utils.lib.eachDefaultSystem (system: self.forDocs {
      targets = [
        { target = "simple.pdf"; files = ["simple.pdf"]; path = ./tests/simple/.; }
      ];
    });
  };
}
