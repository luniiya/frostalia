{
  config,
  lib,
  ...
}:
let
  cfg = config.services.frostalia;
in
{
  options.services.frostalia = {
    enable = lib.mkEnableOption "Frostalia shell systemd service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The frostalia package to use";
    };

    target = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "hyprland-session.target";
      description = "The systemd target for the frostalia service.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [
      ''
        Running frostalia as a systemd service has been deprecated!
        See https://github.com/luniiya/frostalia#nix for details.
      ''
    ];
    systemd.user.services.frostalia = {
      description = "Frostalia Shell - Wayland desktop shell";
      documentation = [ "https://github.com/luniiya/frostalia#readme" ];
      after = [ cfg.target ];
      partOf = [ cfg.target ];
      wantedBy = [ cfg.target ];
      restartTriggers = [ cfg.package ];

      environment = {
        PATH = lib.mkForce null;
      };

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
