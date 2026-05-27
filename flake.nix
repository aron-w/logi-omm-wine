{
  description = "Wine wrapper for Logitech Onboard Memory Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      ommVersion = "2.6.1749";
      ommUrl = "https://download01.logi.com/web/ftp/pub/techsupport/gaming/OnboardMemoryManager_${ommVersion}.exe";
      ommHash = "sha256-rsdlh/HQfFFmfBQMcwo4+CZ1++LYmOeUEzchRrljI1g=";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          lib = pkgs.lib;

          wine = pkgs.wineWow64Packages.stable;

          ommExe = pkgs.fetchurl {
            url = ommUrl;
            hash = ommHash;
          };

          udevRules = pkgs.writeTextFile {
            name = "omme-udev-rules";
            destination = "/lib/udev/rules.d/70-logitech-omm.rules";
            text = builtins.readFile ./udev/70-logitech-omm.rules;
          };

        in
        {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "omme";
            version = ommVersion;

            dontUnpack = true;

            nativeBuildInputs = [
              pkgs.makeWrapper
            ];

            installPhase = ''
              runHook preInstall

              install -Dm755 ${./bin/omme} "$out/bin/omme"
              install -Dm755 ${./bin/omme-init} "$out/bin/omme-init"
              install -Dm755 ${./bin/omme-init-gui} "$out/bin/omme-init-gui"
              install -Dm755 ${./bin/omme-debug} "$out/bin/omme-debug"

              mkdir -p "$out/share/omme"
              cp ${ommExe} "$out/share/omme/OnboardMemoryManager.exe"
              install -Dm644 ${./share/applications/omme.desktop} "$out/share/applications/omme.desktop"
              install -Dm644 ${./share/applications/omme-init.desktop} "$out/share/applications/omme-init.desktop"
              install -Dm644 ${./share/metainfo/io.github.aron-w.omme.metainfo.xml} "$out/share/metainfo/io.github.aron-w.omme.metainfo.xml"

              wrapProgram "$out/bin/omme" \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.bash
                    pkgs.coreutils
                    wine
                  ]
                }
              wrapProgram "$out/bin/omme-init" \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.bash
                    pkgs.coreutils
                    pkgs.curl
                    pkgs.winetricks
                    wine
                  ]
                }
              wrapProgram "$out/bin/omme-init-gui" \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.bash
                    pkgs.xterm
                  ]
                }
              wrapProgram "$out/bin/omme-debug" \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.bash
                    pkgs.coreutils
                    wine
                  ]
                }

              runHook postInstall
            '';

            meta = {
              description = "Wine wrapper for Logitech Onboard Memory Manager";
              homepage = "https://support.logi.com/hc/en-us/articles/360059641133-Onboard-Memory-Manager";
              license = lib.licenses.unfree;
              mainProgram = "omme";
              platforms = lib.platforms.linux;
            };
          };

          omme-udev-rules = udevRules;
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          runtime-contract = pkgs.runCommand "omme-runtime-contract" { } ''
            ${pkgs.bash}/bin/bash -n ${./bin/omme}
            ${pkgs.bash}/bin/bash -n ${./bin/omme-init}
            ${pkgs.bash}/bin/bash -n ${./bin/omme-init-gui}
            ${pkgs.bash}/bin/bash -n ${./bin/omme-debug}
            OMME_TEST_BIN_DIR=${./bin} ${pkgs.bash}/bin/bash ${./tests/runtime-contract.sh}
            touch $out
          '';
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/omme";
          meta.description = "Run Logitech Onboard Memory Manager through Wine";
        };
        init = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/omme-init";
          meta.description = "Initialize the OMME Wine prefix";
        };
        debug = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/omme-debug";
          meta.description = "Run OMME with Wine HID debug logging";
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.default
              pkgs.direnv
              pkgs.just
              pkgs.systemd
              pkgs.winetricks
              pkgs.wineWow64Packages.stable
            ];

            OMME_VERSION = ommVersion;
          };
        }
      );

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.omme;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
          udevRules = self.packages.${pkgs.stdenv.hostPlatform.system}.omme-udev-rules;
        in
        {
          options.programs.omme = {
            enable = lib.mkEnableOption "Logitech Onboard Memory Manager Wine wrapper";

            package = lib.mkOption {
              type = lib.types.package;
              default = package;
              defaultText = lib.literalExpression "inputs.omme.packages.${pkgs.system}.default";
              description = "The OMME package to install.";
            };

            installUdevRules = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether to install Logitech hidraw udev rules for Wine/OMM.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
            services.udev.packages = lib.mkIf cfg.installUdevRules [ udevRules ];
          };
        };
    };
}
