{ config, pkgs, ... }: {
  boot.kernelParams = [
    "console=ttyS0,115200"
  ];
  boot.kernelPackages = pkgs.linuxPackages_5_6;
  boot.kernelPatches = [
    { name = "celestica-driver-net-ethernet-intel-igb";
      patch = ../celestica-driver-net-ethernet-intel-igb.patch;
    }
    { name = "driver-celestica-redstone-xp";
      patch = ../driver-celestica-redstone-xp.patch;
      extraConfig = ''
        CEL_REDSTONE_XP_CPLD m
      '';
    }
  ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
}
