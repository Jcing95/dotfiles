# Git configuration shared by all hosts
{ username, email, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = username;
        inherit email;
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
