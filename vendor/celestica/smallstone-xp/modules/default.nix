{ config, pkgs, ... }: {
  boot.kernelParams = [
    "console=ttyS0,115200"
  ];
  boot.kernelPackages = pkgs.linuxPackages_5_6;
  boot.kernelPatches = [
    {
      name = "celestica-driver-net-ethernet-intel-igb";
      patch = ../celestica-driver-net-ethernet-intel-igb.patch;
    }
  ];
}
