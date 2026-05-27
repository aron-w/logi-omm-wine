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

          wineInit = pkgs.wineWow64Packages.stable;
          wineHookfix = pkgs.wineWow64Packages.stagingFull.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              ./patches/wine-hook-count-underflow.patch
            ];
          });

          ommExe = pkgs.fetchurl {
            url = ommUrl;
            hash = ommHash;
          };

          udevRules = pkgs.writeTextFile {
            name = "logi-omm-wine-udev-rules";
            destination = "/lib/udev/rules.d/70-logi-omm-wine.rules";
            text = builtins.readFile ./udev/70-logi-omm-wine.rules;
          };

          mkPackage =
            {
              pname,
              wineRuntime,
            }:
            pkgs.stdenvNoCC.mkDerivation {
              inherit pname;
              version = ommVersion;

              dontUnpack = true;

              nativeBuildInputs = [
                pkgs.makeWrapper
              ];

              installPhase = ''
                runHook preInstall

                install -Dm755 ${./bin/logi-omm-wine} "$out/bin/logi-omm-wine"
                install -Dm755 ${./bin/logi-omm-wine-init} "$out/bin/logi-omm-wine-init"
                install -Dm755 ${./bin/logi-omm-wine-init-gui} "$out/bin/logi-omm-wine-init-gui"
                install -Dm755 ${./bin/logi-omm-wine-debug} "$out/bin/logi-omm-wine-debug"
                install -Dm755 ${./bin/logi-omm-wine-stop} "$out/bin/logi-omm-wine-stop"

                mkdir -p "$out/share/logi-omm-wine"
                cp ${ommExe} "$out/share/logi-omm-wine/OnboardMemoryManager.exe"
                install -Dm644 ${./share/applications/logi-omm-wine.desktop} "$out/share/applications/logi-omm-wine.desktop"
                install -Dm644 ${./share/applications/logi-omm-wine-init.desktop} "$out/share/applications/logi-omm-wine-init.desktop"
                install -Dm644 ${./share/metainfo/io.github.aron-w.logi-omm-wine.metainfo.xml} "$out/share/metainfo/io.github.aron-w.logi-omm-wine.metainfo.xml"

                wrapProgram "$out/bin/logi-omm-wine" \
                  --prefix PATH : ${
                    lib.makeBinPath [
                      pkgs.bash
                      pkgs.coreutils
                      pkgs.gnugrep
                      wineRuntime
                    ]
                  }
                wrapProgram "$out/bin/logi-omm-wine-init" \
                  --prefix PATH : ${
                    lib.makeBinPath [
                      pkgs.bash
                      pkgs.coreutils
                      pkgs.curl
                      pkgs.winetricks
                      wineInit
                    ]
                  }
                wrapProgram "$out/bin/logi-omm-wine-init-gui" \
                  --prefix PATH : ${
                    lib.makeBinPath [
                      pkgs.bash
                      pkgs.xterm
                    ]
                  }
                wrapProgram "$out/bin/logi-omm-wine-debug" \
                  --prefix PATH : ${
                    lib.makeBinPath [
                      pkgs.bash
                      pkgs.coreutils
                      wineRuntime
                    ]
                  }
                wrapProgram "$out/bin/logi-omm-wine-stop" \
                  --prefix PATH : ${
                    lib.makeBinPath [
                      pkgs.bash
                      pkgs.coreutils
                      pkgs.gnugrep
                      wineRuntime
                    ]
                  }

                runHook postInstall
              '';

              meta = {
                description = "Wine wrapper for Logitech Onboard Memory Manager";
                homepage = "https://support.logi.com/hc/en-us/articles/360059641133-Onboard-Memory-Manager";
                license = lib.licenses.unfree;
                mainProgram = "logi-omm-wine";
                platforms = lib.platforms.linux;
              };
            };

        in
        {
          default = mkPackage {
            pname = "logi-omm-wine";
            wineRuntime = wineHookfix;
          };

          logi-omm-wine-stable = mkPackage {
            pname = "logi-omm-wine-stable";
            wineRuntime = pkgs.wineWow64Packages.stable;
          };

          logi-omm-wine-unstable = mkPackage {
            pname = "logi-omm-wine-unstable";
            wineRuntime = pkgs.wineWow64Packages.unstableFull;
          };

          logi-omm-wine-udev-rules = udevRules;
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          runtime-contract = pkgs.runCommand "logi-omm-wine-runtime-contract" { } ''
            ${pkgs.bash}/bin/bash -n ${./bin/logi-omm-wine}
            ${pkgs.bash}/bin/bash -n ${./bin/logi-omm-wine-init}
            ${pkgs.bash}/bin/bash -n ${./bin/logi-omm-wine-init-gui}
            ${pkgs.bash}/bin/bash -n ${./bin/logi-omm-wine-debug}
            ${pkgs.bash}/bin/bash -n ${./bin/logi-omm-wine-stop}
            LOGI_OMM_WINE_TEST_BIN_DIR=${./bin} ${pkgs.bash}/bin/bash ${./tests/runtime-contract.sh}
            touch $out
          '';
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/logi-omm-wine";
          meta.description = "Run Logitech Onboard Memory Manager through Wine";
        };
        init = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/logi-omm-wine-init";
          meta.description = "Initialize the logi-omm-wine Wine prefix";
        };
        debug = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/logi-omm-wine-debug";
          meta.description = "Run logi-omm-wine with Wine HID debug logging";
        };
        stop = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/logi-omm-wine-stop";
          meta.description = "Stop the logi-omm-wine Wine prefix";
        };
        run-stable = {
          type = "app";
          program = "${self.packages.${system}.logi-omm-wine-stable}/bin/logi-omm-wine";
          meta.description = "Run Logitech Onboard Memory Manager through stable Wine";
        };
        run-unstable = {
          type = "app";
          program = "${self.packages.${system}.logi-omm-wine-unstable}/bin/logi-omm-wine";
          meta.description = "Run Logitech Onboard Memory Manager through unstable full Wine";
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
              pkgs.wineWow64Packages.stagingFull
              pkgs.wineWow64Packages.unstableFull
            ];

            LOGI_OMM_WINE_VERSION = ommVersion;
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
          cfg = config.programs.logi-omm-wine;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
          udevRules = self.packages.${pkgs.stdenv.hostPlatform.system}.logi-omm-wine-udev-rules;
        in
        {
          options.programs.logi-omm-wine = {
            enable = lib.mkEnableOption "Logitech Onboard Memory Manager Wine wrapper";

            package = lib.mkOption {
              type = lib.types.package;
              default = package;
              defaultText = lib.literalExpression "inputs.logiOmmWine.packages.${pkgs.system}.default";
              description = "The logi-omm-wine package to install.";
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
