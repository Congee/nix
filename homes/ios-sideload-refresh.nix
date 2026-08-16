# Re-sign apps sideloaded off a free personal team before their 7-day profile lapses.
#
# Each app gets its own agent, and each agent decides for itself whether to act: it wakes on a
# fixed interval, and returns immediately unless the signature is close to expiry AND the phone
# is reachable. Scheduling and expiry live here; building and installing stay in each app's own
# repo, named by `command`.
{ config, pkgs, lib, ... }:

let
  cfg = config.services.ios-sideload-refresh;

  # writeScriptBin, not writeShellScriptBin: the script carries its own #!/bin/zsh and relies on
  # zsh globbing, so it must not be handed to bash.
  refresh = pkgs.writeScriptBin "ios-sideload-refresh"
    (builtins.readFile ../scripts/ios-sideload-refresh.sh);

  appModule = lib.types.submodule {
    options = {
      bundleId = lib.mkOption {
        type = lib.types.str;
        example = "me.congee.alfa";
        description = "Bundle identifier, used to find the profile and to key the saved expiry.";
      };
      workdir = lib.mkOption {
        type = lib.types.str;
        description = "Directory `command` runs in — normally the app's checkout.";
      };
      device = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "Monad";
        description = ''
          Device name to install to. Leave empty only when exactly one iOS device is ever
          paired; with several paired, an empty name is ambiguous and the agent skips.
        '';
      };
      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        example = [ "Tools/alfa-install.sh" "Monad" ];
        description = "Installer to run, relative to `workdir`. Owns the build and the install.";
      };
      renewDays = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Per-app override for the global renewDays threshold.";
      };
    };
  };
in
{
  options.services.ios-sideload-refresh = {
    enable = lib.mkEnableOption "re-signing sideloaded iOS apps before their profile expires";

    interval = lib.mkOption {
      type = lib.types.int;
      default = 21600;
      description = ''
        Seconds between checks. Wants to be well under the renewDays window so a phone that is
        only occasionally reachable still gets caught: 6h against a 3-day window is ~12 chances.
      '';
    };

    renewDays = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Refresh once fewer than this many days remain on the signature.";
    };

    apps = lib.mkOption {
      type = lib.types.attrsOf appModule;
      default = { };
      description = "Apps to keep signed, one launchd agent each.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Also puts `ios-sideload-refresh --bundle-id ID --status` on PATH for checking by hand.
    home.packages = [ refresh ];

    launchd.agents = lib.mapAttrs'
      (name: app:
        let log = "${config.home.homeDirectory}/Library/Logs/ios-sideload-refresh-${name}.log";
        in lib.nameValuePair "ios-sideload-refresh-${name}" {
          enable = true;
          config = {
            ProgramArguments =
              [
                "${refresh}/bin/ios-sideload-refresh"
                "--bundle-id" app.bundleId
                "--workdir" app.workdir
                "--renew-days" (toString (if app.renewDays == null then cfg.renewDays else app.renewDays))
              ]
              ++ lib.optionals (app.device != "") [ "--device" app.device ]
              ++ [ "--" ] ++ app.command;
            StartInterval = cfg.interval;
            RunAtLoad = true;
            StandardOutPath = log;
            StandardErrorPath = log;
            # launchd agents get a bare PATH; xcodebuild and friends live in /usr/bin.
            EnvironmentVariables.PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
            ProcessType = "Background";
            LowPriorityIO = true;
          };
        })
      cfg.apps;
  };
}
