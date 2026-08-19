# Re-sign apps sideloaded off a free personal team before their 7-day profile lapses.
#
# Each app gets its own agent, and each agent decides for itself whether to act: it wakes on a
# fixed interval, and returns immediately unless the signature is close to expiry, or an earlier
# install still owes the app a launch. Scheduling, expiry and the launch live here; building and
# installing stay in each app's own repo, named by `command`.
{ config, pkgs, lib, ... }:

let
  cfg = config.services.ios-sideload-refresh;

  # The source keeps `#!/usr/bin/env bash` so shellcheck, bash-language-server and a direct
  # ./scripts run all work on it; the store copy gets an absolute one. Otherwise a launchd agent's
  # PATH=/usr/bin:/bin would resolve to Apple's bash 3.2, frozen in 2007 at the last GPLv2 release.
  refresh = pkgs.writeScriptBin "ios-sideload-refresh"
    (builtins.replaceStrings [ "#!/usr/bin/env bash" ] [ "#!${pkgs.runtimeShell}" ]
      (builtins.readFile ../scripts/ios-sideload-refresh.sh));

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
        example = [ "Tools/alfa-install.sh" ];
        description = ''
          Installer to run, relative to `workdir`. The resolved device UDID is appended, so end
          this list with a flag to pass it as that flag's value; the agent has resolved the device
          anyway for the lock-state probe. Owns the build and the install — but not the launch,
          which the agent does itself once the screen is unlocked. An installer that launches on
          its own must be told not to, or the app is launched twice.
        '';
      };
      launch = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Open the app after installing, and after any wake-up that finds an install still owing a
          launch. On by default: a reinstall wipes the preserved CoreBluetooth state, so iOS will
          not run the app in the background again until it has been launched once.
        '';
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
      default = 300;
      description = ''
        Seconds between checks. Minutes rather than hours, for the launch rather than the signing:
        a freshly installed app has to be launched once before iOS will run it in the background
        again, and that only works while the screen is unlocked — so the agent has to be looking
        when the phone happens to be in use. Runs with nothing to do cost one file read and no
        device I/O at all, which is what makes this cadence affordable.
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
              ++ [ "--launch" (lib.boolToString app.launch) ]
              ++ [ "--" ] ++ app.command;
            # Polled, not event-driven. LaunchEvents can wake a job on USB attach or a network
            # change, but only a job that drains the stream via xpc_set_event_stream_handler(3);
            # a script cannot, so launchd relaunches it every ThrottleInterval forever. Measured:
            # 3 notifications left an agent firing every 10s indefinitely.
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
