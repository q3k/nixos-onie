/* NixOS module to provide minimum configuration required to be a full-fledged ONIE NOS.
 *
 * Currently this supports Legacy/MBR GRUB devices only.
 */
{ config, pkgs, ... }: {
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    extraEntries = ''
      menuentry ONIE {
          search --no-floppy --label --set=root ONIE-BOOT
          echo    'Loading ONIE ...'
          chainloader +1
      }
    '';
  };
}
