{ config, pkgs, ... }: {
  boot.kernelParams = [
    "console=ttyS0,115200"
  ];
}
