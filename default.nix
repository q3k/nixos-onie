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
      ./vendor/celestica/smallstone-xp/modules/default.nix
    ];

    system.stateVersion = "20.03";
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/518ecac1-00ea-4ef0-9418-9eca6ce6d918"; # TODO(q3k): changeme
      fsType = "ext4";
    };
  });
}
