/* NixOS module that creates an interactive installer as an initrd.
 *
 * This can be used to boot an ONIE switch into a NixOS installer without
 * actually installing anything locally, for manual installation on the switch,
 * or various manual debug/test work.
 */
{ config, pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/installation-device.nix"
  ];
  networking.hostName = "nixos-onie-dev-installer";
  system.stateVersion = "20.04";
  nix.maxJobs = 4;
  boot.loader.grub.enable = false;
  boot.kernelParams = [
    "console=tty0"
    "console=tty1"
    "console=tty2"
    "console=ttyS0,115200"
  ];
}
