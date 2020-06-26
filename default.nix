/* Top-level nix build set.
 * Current target attributes:
 * - devImage: celestica D4040 ONIE installer that starts interactive NixOS
 *             installer in-memory
 * - devImageTest: test of aforementioned image.
 * - target: build target derivation for q3k's lab Celestica D4040
 */

with import(fetchGit {
  name = "nixos-unstable-2020-06-20";
  url = https://github.com/nixos/nixpkgs-channels/;
  rev = "9480bae337095fd24f61380bce3174fdfe926a00";
}) {};

let
  onieInstaller = callPackage ./onie-installer/default.nix {};
in rec {
  devImage = onieInstaller.makeNixOSInitrdImage {
    imports = [
      ./modules/dev-installer.nix
      ./vendor/celestica/smallstone-xp/modules/default.nix
    ];
  };

  devImageTest = onieInstaller.makeTest {
    image = onieInstaller.makeNixOSInitrdImage {
      imports = [
        ./modules/dev-installer.nix
        ./vendor/celestica/smallstone-xp/modules/default.nix
        "${pkgs.path}/nixos/modules/testing/test-instrumentation.nix"
      ];
    };
    testScript = ''
      machine.succeed("true")
    '';
  };

  target = nixos ({ config, pkgs, ... }: {
    imports = [
      ./modules/onie-nos.nix
      ./modules/onie-toolbox.nix
      ./vendor/celestica/smallstone-xp/modules/default.nix
    ];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/4a667b6b-561e-4ea6-8326-ff491e62f1c6";
      fsType = "ext4";
    };
    swapDevices = [];

    networking.useDHCP = false;
    networking.interfaces.enp0s20f0.useDHCP = true;

    users.users.root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMb593DS2IR/ZnRBq9DHTCdQuNW1LghQAoa8WN8h3okC q3k@anathema"
      ];
    };

    system.stateVersion = "20.09"; # Did you read the comment?
  });
}
