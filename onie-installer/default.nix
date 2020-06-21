/* Nix derivations to allow building ONIE compatible installers.
 *
 * The ONIE installer image is a stub shell script concatenated to a tarball.
 * The schell scripts unpack the tarball (which is expected to contain a nix
 * store), sets up a /nix bindmount pointing to the extracted tarball, and
 * runs some sort of internal script (entrypoint) in the tarball.
 *
 * The generated tarball, as mentioned, contains a Nix store. This store is
 * not strictly necessary (as it's not the target store), but useful to have
 * some sort of strict environment. The entrypoint (not stub) of the tarball
 * will then perform a kexec into the target NixOS.
 *
 * Currently we support one kind of kexec image: an initrd containing an
 * entire NixOS. In the future, more kexec kinds will probably be implemented,
 * for instance ones that run off an NFS/9p root.
 */

{ lib, pkgs, system, ... }:

let 
  /* Make a stub script for the ONIE installer, that extract the tarball that's
   * concatenated to it, end runs 'entrypoint' in it, with the first argument
   * set to the path of the original installer.
   */
  makeStub = entrypoint: let
    target = lib.removePrefix "/" entrypoint;
  in pkgs.writeTextFile {
    name = "stub";
    text = ''
      #!/bin/sh
      set -e
      
      echo "Installer: Stub: Checking installer..."

      if [ "$(id -u)" != "0" ]; then
        echo 'Installer: Stub: Not running as root - aborting.'
        exit 1
      fi
      
      got_sha1=$(sed -e '1,/^___split$/d' "$0" | sha1sum | awk '{ print $1 }')
      want_sha1=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      
      if [ "$want_sha1" != "$got_sha1" ]; then
          echo "Installer: SHA1 mismatch - aborting."
          echo "Wanted: $want_sha1"
          echo "   Got: $got_sha1"
          exit 1
      fi
      
      echo "Installer: Stub: Checkum okay, extracting payload..."

      installer_path=$(realpath "$0")
      tmp_dir="$(mktemp -d)"
      echo "Installer: Stub: Payload path: $tmp_dir"

      cd $tmp_dir
      sed -e '1,/^___split$/d' $installer_path | tar zxf -

      if [ ! -d $tmp_dir/nix/store ]; then
          echo "Installer: No nix store found - aborting."
          exit 1
      fi

      echo "Installer: Stub: Bindmounting $tmp_dir/nix to /nix..."
      if [ ! -d /nix ]; then
          mkdir /nix
      fi
      mount -o bind $tmp_dir/nix /nix

      if [ ! -f ${target} ]; then
          echo "Installer: Kexec stub script ${target} not found in extracted nix store - aborting."
          exit 1
      fi

      echo "Installer: Stub: Going into kexec script..."
      exec ./${target} $installer_path
      ___split
    '';
  };

  /* Make a tarball that contains an entrypoint script, which starts a given
   * initrd/kernel/cmdline.
   * 
   * The output of this is a set of 'tarball' file path, and 'entrypoint'
   * script name (to be called by the installer stub).
   */
  makeKexecTarball = { kernel, initrd, cmdline }: let
    makeSystemTarball = import "${pkgs.path}/nixos/lib/make-system-tarball.nix";
    kexecPath = "/kexec_nixos";
    kexecScript = pkgs.writeTextFile {
      executable = true;
      name = "kexec-nixos-installer";
      text = ''
        #!${pkgs.stdenv.shell}
        set -e

        echo "Installer: Kexec script: Starting..."

        export PATH=${pkgs.kexectools}/bin:${pkgs.cpio}/bin:${pkgs.busybox}/bin:$PATH
        cd $(mktemp -d)

        if [ ! -z "$1" ]; then
          echo "Installer: Kexec script: Removing $1..."
          rm -f "$1"
        fi

        kexec \
          -l ${kernel} \
          --initrd ${initrd} \
          --append="${cmdline}"
        echo "Installer: Kexec script: See you, space cowboy"
        kexec -e
      '';
    };
    tarball = pkgs.callPackage makeSystemTarball {
      storeContents = [
        { object = kexecScript; symlink = kexecPath; }
      ];
      contents = [];
      compressCommand = "gzip";
      compressionExtension = ".gz";
    };
  in {
    tarball = "${tarball}/tarball/nixos-system-${system}.tar.gz";
    entrypoint = kexecPath;
  };

  /* Make an installer image that extracts a given tarball and jumps to the
   * entrypoint path in it.
   */
  makeImage = { tarball, entrypoint }: let
    stub = makeStub entrypoint;
  in pkgs.runCommand "image" {} ''
    set -e
    cp ${stub} onie-installer
    sha1=$(sha1sum ${tarball} | awk '{ print $1 }')
    sed -i onie-installer -e "s/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/$sha1/"
    chmod +w onie-installer
    cat ${tarball} >> onie-installer

    mkdir $out
    mv onie-installer $out/onie-installer
    chmod +x $out/onie-installer
  '';

in {
  /* Make an ONIE installer image that starts a nixos configuration. The NixOS
   * configuration will be stored in an initrd, and it will be started
   * alongside the configuration's kernel by kexecing into it.
   */
  makeNixOSInitrdImage = { imports }: let
    modules = [
      "${pkgs.path}/nixos/modules/installer/netboot/netboot.nix"
      "${pkgs.path}/nixos/modules/profiles/minimal.nix"
    ];
    nixos = pkgs.nixos ({ config, pkgs, ...}: {
      imports = modules ++ imports;
    });
  in makeImage (makeKexecTarball {
    kernel = "${nixos.config.system.build.kernel}/bzImage";
    initrd = "${nixos.config.system.build.netbootRamdisk}/initrd";
    cmdline = "init=${builtins.unsafeDiscardStringContext nixos.config.system.build.toplevel}/init ${toString nixos.config.boot.kernelParams}";
  });

  makeTest = (pkgs.callPackage ./test.nix {}).makeTest;
}
