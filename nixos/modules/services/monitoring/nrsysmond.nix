{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nrsysmond;

  logDir = "/var/log/newrelic";
  logFile = "${logDir}/nrsysmond.log";

  cfgFile = pkgs.writeText "nrsysmond.cfg" ''
    license_key=${cfg.licenseKey}
    logfile=${logFile}
  '';

in

{
  options = {
    services.nrsysmond = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the New Relic system monitor.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.nrsysmond;
        description = "The nrsysmond package to use.";
      };

      licenseKey = mkOption {
        type = types.str;
        default = "";
        description = "The nrsysmond package to use.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      { assertion = cfg.licenseKey != "";
        message = "nrsysmond: When enabled, a licenseKey must be provided";
      }
    ];

    users.extraGroups.newrelic.gid = config.ids.gids.newrelic;
    users.extraUsers.newrelic = {
      description = "New Relic Monitoring User";
      uid = config.ids.uids.newrelic;
      group = "newrelic";
      home = "/var/log/newrelic";
      createHome = true;
    };

    systemd.services.nrsysmond = {
      description = "New Relic server monitoring daemon";
      path     = [ pkgs.procps ];
      wantedBy = [ "multi-user.target" ];
      after    = [ "network-interfaces.target" ];

      serviceConfig = {
        User = "newrelic";
        Group = "newrelic";
        ExecStart = "${cfg.package}/bin/nrsysmond -f -c ${cfgFile}";
        Restart = "always";
        RestartSec = 2;
        PermissionsStartOnly = true;
      };
    };
  };
}

