{
  quickshell,
  cargo,
  rustc,
  rustfmt,
  clippy,
  nixfmt,
  statix,
  deadnix,
  shfmt,
  shellcheck,
  jsonfmt,
  lefthook,
  kdePackages,
  mkShellNoCC,
}:
mkShellNoCC {
  #it's faster than mkDerivation / mkShell
  packages = [
    quickshell
    cargo
    rustc
    rustfmt
    clippy

    # nix
    nixfmt # formatter
    statix # linter
    deadnix # linter

    # shell
    shfmt # formatter
    shellcheck # linter

    # json
    jsonfmt # formatter

    # CoC
    lefthook # githooks
    kdePackages.qtdeclarative # qmlfmt, qmllint, qmlls and etc; Qt6
  ];
}
