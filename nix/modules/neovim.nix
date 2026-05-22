{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
  };

  # LSPs, formatters, and linters for the LazyVim setup.
  # Installed via Nix so the binaries are nix-patched and actually run on NixOS,
  # rather than relying on Mason-downloaded prebuilts.
  environment.systemPackages = with pkgs; [
    # Language servers
    nil                             # nix
    lua-language-server             # lua
    vtsls                           # typescript / javascript
    vscode-langservers-extracted    # json / html / css / eslint
    marksman                        # markdown
    bash-language-server            # bash / sh

    # Formatters
    stylua
    shfmt
    biome
    prettier

    # Linters / misc tools
    markdownlint-cli2
    nodejs                          # required by some lsp / formatter wrappers
  ];
}
