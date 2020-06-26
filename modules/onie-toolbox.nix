{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    wget vim htop tcpdump pciutils
    rxvt_unicode.terminfo
  ];
  programs.mtr.enable = true;
  services.openssh.enable = true;
}
