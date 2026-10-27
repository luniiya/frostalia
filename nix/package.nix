{
  version ? "dirty",
  extraPackages ? [ ],
  runtimeDeps ? [
    brightnessctl
    cliphist
    ddcutil
    wlsunset
    wl-clipboard
    wlr-randr
    imagemagick
    wget
    (python3.withPackages (pp: lib.optional calendarSupport pp.pygobject3))
  ],

  lib,
  stdenvNoCC,
  rustPlatform,
  dbus,
  # build
  qt6,
  quickshell,
  # runtime deps
  brightnessctl,
  cliphist,
  ddcutil,
  wlsunset,
  wl-clipboard,
  wlr-randr,
  imagemagick,
  wget,
  python3,
  wayland-scanner,
  # calendar support
  calendarSupport ? false,
  evolution-data-server,
  libical,
  glib,
  libsoup_3,
  json-glib,
  gobject-introspection,
}:
let
  src = lib.cleanSourceWith {
    src = ../.;
    filter =
      path: type:
      !(builtins.any (prefix: lib.path.hasPrefix (../. + prefix) (/. + path)) [
        /Tools/settings/target
        /Tools/theming/target
        /Tools/kdeconnect/target
        /.github
        /.gitignore
        /Assets/Screenshots
        /Scripts/dev
        /nix
        /LICENSE
        /README.md
        /flake.nix
        /flake.lock
        /shell.nix
        /lefthook.yml
        /CLAUDE.md
        /CREDITS.md
      ]);
  };

  settingsHelper = rustPlatform.buildRustPackage {
    pname = "frostalia-settings";
    inherit version src;
    cargoRoot = "Tools/settings";
    buildAndTestSubdir = "Tools/settings";
    cargoLock.lockFile = ../Tools/settings/Cargo.lock;
  };

  themingHelper = rustPlatform.buildRustPackage {
    pname = "frostalia-theming";
    inherit version src;
    cargoRoot = "Tools/theming";
    buildAndTestSubdir = "Tools/theming";
    cargoLock.lockFile = ../Tools/theming/Cargo.lock;
  };

  kdeconnectHelper = rustPlatform.buildRustPackage {
    pname = "frostalia-kdeconnect";
    inherit version src;
    cargoRoot = "Tools/kdeconnect";
    buildAndTestSubdir = "Tools/kdeconnect";
    cargoLock.lockFile = ../Tools/kdeconnect/Cargo.lock;
    # Integration tests run a private dbus-daemon.
    nativeCheckInputs = [ dbus ];
  };

  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    evolution-data-server
    libical
    glib.out
    libsoup_3
    json-glib
    gobject-introspection
  ];
in
stdenvNoCC.mkDerivation {
  pname = "frostalia";
  inherit version src;

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
  ];

  installPhase = ''
    mkdir -p $out/share/frostalia $out/bin
    cp -r . $out/share/frostalia
    ln -s ${quickshell}/bin/qs $out/bin/frostalia
    install -m 755 ${settingsHelper}/bin/frostalia-settings $out/bin/frostalia-settings
    install -m 755 ${themingHelper}/bin/frostalia-theming $out/bin/frostalia-theming
    install -m 755 ${kdeconnectHelper}/bin/frostalia-kdeconnect $out/bin/frostalia-kdeconnect
  '';

  preFixup = ''
    qtWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ extraPackages)}
      --prefix XDG_DATA_DIRS : ${wayland-scanner}/share
      --set-default QS_CONFIG_PATH "$out/share/frostalia"
      --set FROSTALIA_SETTINGS_HELPER "$out/bin/frostalia-settings"
      --set FROSTALIA_THEMING_HELPER "$out/bin/frostalia-theming"
      --set FROSTALIA_KDECONNECT_HELPER "$out/bin/frostalia-kdeconnect"
      ${lib.optionalString calendarSupport "--prefix GI_TYPELIB_PATH : ${giTypelibPath}"}
    )
  '';

  meta = {
    description = "A sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell.";
    homepage = "https://github.com/luniiya/frostalia";
    license = lib.licenses.gpl3Only;
    mainProgram = "frostalia";
  };
}
