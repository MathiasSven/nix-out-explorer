{
  inputs.nixfzf.url = "github:MathiasSven/nixfzf/nix";
  inputs.nixfzf.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
      nixfzf,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (system: {
        default = self.packages.${system}.nix-out-explorer;

        nix-out-explorer =
          let
            inherit (pkgs.${system}) makeWrapper lib stdenv;
          in
          stdenv.mkDerivation (finalAttrs: {
            pname = "nix-out-explorer";
            version = "0.1.0";

            src = ./.;

            nativeBuildInputs = [ makeWrapper ];

            buildInputs = with pkgs.${system}; [
              curl
              fzf
              nixfzf.packages.${system}.default
            ];

            dontBuild = true;

            installPhase = ''
              install -D nix-out-explorer.sh $out/bin/${finalAttrs.pname}

              wrapProgram $out/bin/${finalAttrs.pname} \
                --prefix PATH : '${lib.makeBinPath finalAttrs.buildInputs}'
            '';
          });
      });
    };
}
