/* Derivations for testing ONIE-installer-like scenarios.
 *
 * See makeTest.
 */

{ pkgs, system, ... }:

let
  testingPython = pkgs.callPackage (import "${pkgs.path}/nixos/lib/testing-python.nix") {};
in

{
  /* Make a VM-based test that runs a given ONIE install image.
   * 
   * The VM will boot, start the installer, then do some, uh, string parsing
   * magic to determine success or not. We can't really use the default harness
   * here as it expect a command to return... while a kexec doesn't.
   *
   * Then, the provided testScript is run in the newly kexec'd NixOS.
   */
  makeTest = { testScript, image }: testingPython.makeTest {
    name = "image-dev-test";
    machine = { config, pkgs, ... }: {
      virtualisation.memorySize = 4096;
      virtualisation.diskSize = 4096;
    };
    testScript = ''
      machine.wait_for_unit("default.target")
      machine.shell.send(
          "\n${image}/onie-installer\n".encode()
      )
      data = ""

      while True:
          chunk = machine.shell.recv(4096).decode(errors="ignore")
          data += chunk
          lines = data.split("\n")
          lines, data = lines[:-1], lines[-1]
          done = False
          for line in lines:
              print("ONIE: " + line)
              if "abort" in line:
                  raise Exception(line)
              if "See you" in line:
                  done = True
                  break
          if done:
              break
      print("Sleeping for a bit waiting for kexec...")
      time.sleep(5)
      print("Assuming machine kexeced.")
      machine.connected = False
      ${testScript}'';
  };
}
