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

          wine = pkgs.wineWow64Packages.staging;

          ommExe = pkgs.fetchurl {
            url = ommUrl;
            hash = ommHash;
          };

          ommeInit = pkgs.writeShellApplication {
            name = "omme-init";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.winetricks
              wine
            ];
            text = ''
              set -euo pipefail

              export WINEPREFIX="''${OMME_WINEPREFIX:-''${XDG_DATA_HOME:-$HOME/.local/share}/omme/prefix}"
              export WINEARCH=win64
              export WINEDEBUG="''${OMME_WINEDEBUG:--all}"
              export WINETRICKS_LATEST_VERSION_CHECK=disabled

              marker="$WINEPREFIX/.omme-initialized"

              mkdir -p "$WINEPREFIX"
              wineboot -i

              if [ ! -e "$marker" ]; then
                winetricks -q vcrun2022

                wine reg add 'HKLM\System\CurrentControlSet\Services\WineBus' \
                  /v 'Enable SDL' /t REG_DWORD /d 0 /f
                wine reg add 'HKLM\System\CurrentControlSet\Services\WineBus' \
                  /v DisableHidraw /t REG_DWORD /d 0 /f

                touch "$marker"
              fi
            '';
          };

          ommeRun = pkgs.writeShellApplication {
            name = "omme";
            runtimeInputs = [
              pkgs.coreutils
              wine
            ];
            text = ''
              set -euo pipefail

              export WINEPREFIX="''${OMME_WINEPREFIX:-''${XDG_DATA_HOME:-$HOME/.local/share}/omme/prefix}"
              export WINEARCH=win64
              export WINEDEBUG="''${OMME_WINEDEBUG:--all}"

              if [ ! -e "$WINEPREFIX/.omme-initialized" ]; then
                ${ommeInit}/bin/omme-init
              fi

              exec wine "${ommExe}" "$@"
            '';
          };

          ommeDebug = pkgs.writeShellApplication {
            name = "omme-debug";
            runtimeInputs = [
              ommeRun
            ];
            text = ''
              set -euo pipefail

              export OMME_WINEDEBUG="''${OMME_WINEDEBUG:-+plugplay,+hid,+hid_report,+setupapi,+winebus}"
              exec omme "$@"
            '';
          };

          udevRules = pkgs.writeTextFile {
            name = "omme-udev-rules";
            destination = "/lib/udev/rules.d/70-logitech-omm.rules";
            text = ''
              # Allow the active local session to access Logitech HID raw devices for Wine/OMM.
              KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", MODE="0660", TAG+="uaccess"
            '';
          };

          desktopItem = pkgs.makeDesktopItem {
            name = "omme";
            desktopName = "Logitech Onboard Memory Manager";
            genericName = "Mouse onboard memory utility";
            comment = "Run Logitech Onboard Memory Manager through Wine";
            exec = "omme";
            terminal = false;
            categories = [
              "Settings"
              "HardwareSettings"
            ];
          };
        in
        {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "omme";
            version = ommVersion;

            dontUnpack = true;

            nativeBuildInputs = [
              pkgs.copyDesktopItems
              pkgs.makeWrapper
            ];

            desktopItems = [ desktopItem ];

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/bin" "$out/share/omme"
              cp ${ommExe} "$out/share/omme/OnboardMemoryManager.exe"
              ln -s ${ommeRun}/bin/omme "$out/bin/omme"
              ln -s ${ommeInit}/bin/omme-init "$out/bin/omme-init"
              ln -s ${ommeDebug}/bin/omme-debug "$out/bin/omme-debug"

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
              pkgs.wineWow64Packages.staging
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
