# Git configuration shared by all hosts
{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "jcing";
        email = "dev@jcing.de";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "cmd -- cd"
    ];
  };

}
