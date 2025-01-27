Run the emulation with:

  qemu-system-x86_64 -M pc -bios ${O:-output}/images/OVMF.fd -drive file=${O:-output}/images/disk.img,if=virtio,format=raw -net nic,model=virtio -net user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 # qemu_x86_64_efi_defconfig

Optionally add -smp N to emulate a SMP system with N CPUs.

The login prompt will appear in the graphical window.
