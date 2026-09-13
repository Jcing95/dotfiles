{
  services.adguardhome = {
    enable = true;
    port = 3380;
    host = "0.0.0.0";
    mutableSettings = false;
    settings = {
      schema_version = 33;
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [ "1.1.1.1" "1.0.0.1" ];
        bootstrap_dns = [ "1.1.1.1" "1.0.0.1" ];
        ratelimit = 0;
      };
      filtering = {
        rewrites = [
          { domain = "*.jcing.de"; answer = "192.168.0.121"; enabled = true; }
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
