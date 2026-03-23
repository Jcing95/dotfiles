# Git configuration shared by all hosts
{ ... }:

{
  programs.git = {
    enable = true;
    userName = "jcing";
    userEmail = "dev@jcing.de";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };
}
