NixOS ONIE Experiments
======================

This is a in progress experiment to see how far we can get with running NixOS
on ONIE-enabled whitebox switches.

Currently, we're targeting the Celestica D4040 (Trident 2, 32xQSFP+,
Intel C2538) and other Trident2 switches.

For more information, contact the author (who also hangs out on
`#nixos-on-your-router` on Freenode).

Status
------

We have a working interactive NixOS installer built as an ONIE image. To build:

    nix build default.nix devImage

Then, use `result/onie-installer` as an ONIE installer image on your switch.
You should get an interactive NixOS installer shell on ttyS0/tty0. You can then
install NixOS in the standard way (currently there's no provision to install
a target configuration directly, this will be automated at a later point).

After installing, you can build updates for the D4040 NixOS configuration by
building the 'target' attr instead.

    nix build default.nix target

You can then nix-copy-closure the resulting closure onto the target over SSH
and call bin/switch-to-configuration there as usual.

TODO
----

Here are what seem like good next steps:

 - Port [Celestica D4040-specific kernel module patches](https://github.com/opencomputeproject/onie/tree/master/machine/celestica/cel_smallstone_xp/kernel)
 - Port [OpenNSL](https://github.com/Broadcom-Switch/OpenNSL), run an example application.

License
-------

The contents of this repository are licensed under the MIT license (see COPYING.md).

The resulting NixOS builds will contain code and binaries license under multiple open source licenses. We're currently not redistributing those ourselves, so figre this out yourself. This will likely get even more fun when we start pulling in code under various vendor licenses.
