{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.frostalia;
  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };

  generateToml =
    name: value:
    if lib.isString value then
      pkgs.writeText "frostalia-${name}.toml" value
    else if builtins.isPath value || lib.isStorePath value then
      value
    else
      tomlFormat.generate "frostalia-${name}.toml" value;

  generateJson =
    name: value:
    if lib.isString value then
      pkgs.writeText "frostalia-${name}.json" value
    else if builtins.isPath value || lib.isStorePath value then
      value
    else
      jsonFormat.generate "frostalia-${name}.json" value;
in
{
  options.programs.frostalia = {
    enable = lib.mkEnableOption "Frostalia shell configuration";

    systemd.enable = lib.mkEnableOption "Frostalia shell systemd integration";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = "The frostalia package to use";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          tomlFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
        {
          bar = {
            position = "bottom";
            floating = true;
            backgroundOpacity = 0.95;
          };
          general = {
            animationSpeed = 1.5;
            radiusRatio = 1.2;
          };
          colorSchemes = {
            darkMode = true;
            useWallpaperColors = true;
          };
        }
      '';
      description = ''
        Frostalia shell configuration settings as an attribute set, string
        or filepath, to be written to ~/.config/frostalia/defaults.toml.
        This is a seed copied when a host has no settings file yet. Existing
        ~/.config/frostalia/settings/<hostname>.toml files take precedence;
        subsequent changes to this seed do not overwrite per-host settings.
      '';
    };

    colors = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
         {
           mError = "#dddddd";
           mOnError = "#111111";
           mOnPrimary = "#111111";
           mOnSecondary = "#111111";
           mOnSurface = "#828282";
           mOnSurfaceVariant = "#5d5d5d";
           mOnTertiary = "#111111";
           mOutline = "#3c3c3c";
           mPrimary = "#aaaaaa";
           mSecondary = "#a7a7a7";
           mShadow = "#000000";
           mSurface = "#111111";
           mSurfaceVariant = "#191919";
           mTertiary = "#cccccc";
        }
      '';
      description = ''
        Frostalia shell color configuration as an attribute set, string
        or filepath, to be written to ~/.config/frostalia/colors.json.
      '';
    };

    user-templates = lib.mkOption {
      default = { };
      type =
        with lib.types;
        oneOf [
          tomlFormat.type
          str
          path
        ];
      example = lib.literalExpression ''
        {
          templates = {
            neovim = {
              input_path = "~/.config/frostalia/templates/template.lua";
              output_path = "~/.config/nvim/generated.lua";
              post_hook = "pkill -SIGUSR1 nvim";
            };
          };
        }
      '';
      description = ''
        Template definitions for Frostalia, to be written to ~/.config/frostalia/user-templates.toml.

        This option accepts:
        - a Nix attrset (converted to TOML automatically)
        - a string containing raw TOML
        - a path to an existing TOML file
      '';
    };

    plugins = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
        {
          sources = [
            {
              enabled = true;
              name = "Noctalia Plugins";
              url = "https://github.com/noctalia-dev/noctalia-plugins";
            }
          ];
          states = {
            catwalk = {
              enabled = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
          };
          version = 2;
        }
      '';
      description = ''
        Frostalia shell plugin configuration as an attribute set, string
        or filepath, to be written to ~/.config/frostalia/plugins.json.
      '';
    };

    pluginSettings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          jsonFormat.type
          str
          path
        ]);
      default = { };
      example = lib.literalExpression ''
        {
          catwalk = {
            minimumThreshold = 25;
            hideBackground = true;
          };
        }
      '';
      description = ''
        Each plugin’s settings as an attribute set, string
        or filepath, to be written to ~/.config/frostalia/plugins/plugin-name/settings.json.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.mkIf cfg.systemd.enable [
      ''
        Running frostalia as a systemd service has been deprecated!
        See https://github.com/luniiya/frostalia#nix for details.
      ''
    ];

    systemd.user.services.frostalia = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Frostalia Shell - Wayland desktop shell";
        Documentation = "https://github.com/luniiya/frostalia#readme";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
        X-Restart-Triggers =
          lib.optional (cfg.settings != { }) "${config.xdg.configFile."frostalia/defaults.toml".source}"
          ++ lib.optional (cfg.colors != { }) "${config.xdg.configFile."frostalia/colors.json".source}"
          ++ lib.optional (cfg.plugins != { }) "${config.xdg.configFile."frostalia/plugins.json".source}"
          ++ lib.optional (
            cfg.user-templates != { }
          ) "${config.xdg.configFile."frostalia/user-templates.toml".source}"
          ++ lib.mapAttrsToList (
            name: _: "${config.xdg.configFile."frostalia/plugins/${name}/settings.json".source}"
          ) cfg.pluginSettings;
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };

      Install.WantedBy = [ config.wayland.systemd.target ];
    };

    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile = {
      "frostalia/defaults.toml" = lib.mkIf (cfg.settings != { }) {
        source = generateToml "defaults" cfg.settings;
      };
      "frostalia/colors.json" = lib.mkIf (cfg.colors != { }) {
        source = generateJson "colors" cfg.colors;
      };
      "frostalia/plugins.json" = lib.mkIf (cfg.plugins != { }) {
        source = generateJson "plugins" cfg.plugins;
      };
      "frostalia/user-templates.toml" = lib.mkIf (cfg.user-templates != { }) {
        source =
          if lib.isString cfg.user-templates then
            pkgs.writeText "frostalia-user-templates.toml" cfg.user-templates
          else if builtins.isPath cfg.user-templates || lib.isStorePath cfg.user-templates then
            cfg.user-templates
          else
            tomlFormat.generate "frostalia-user-templates.toml" cfg.user-templates;
      };
    }
    // lib.mapAttrs' (
      name: value:
      lib.nameValuePair "frostalia/plugins/${name}/settings.json" {
        source = generateJson "${name}-settings" value;
      }
    ) cfg.pluginSettings;

    assertions = [
      {
        assertion = !cfg.systemd.enable || cfg.package != null;
        message = "frostalia: The package option must not be null when systemd service is enabled.";
      }
    ];
  };
}
