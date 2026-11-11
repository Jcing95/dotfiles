# Packages taken from nixpkgs master instead of nixos-unstable, for apps that
# should update as soon as nixpkgs merges a bump rather than when the channel
# advances. Listed packages are built against master's dependency tree.
nixpkgs-master: final: prev: {
  master = import nixpkgs-master {
    inherit (final.stdenv.hostPlatform) system;
    inherit (final) config;
  };

  inherit (final.master)
    argocd
    bolt-launcher
    brave
    claude-code
    discord
    fzf
    github-copilot-cli
    google-cloud-sdk
    heroic
    k9s
    lazygit
    obsidian
    osu-lazer-bin
    runelite
    signal-desktop
    spotify
    telegram-desktop
    wezterm
    ;
}
