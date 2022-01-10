WORKSTATION_IMAGE := Fedora-Workstation-Live-x86_64-35-1.2.iso
VM_IMAGE := build/vm.qcow2
PXELINUX_CONF := build/conf/tftp/pxelinux.cfg/default
PXELINUX.0 := build/conf/tftp/pxelinux.0
VMLINUZ := build/conf/tftp/fedora35/images/pxeboot/vmlinuz
MOUNT_TARGET := build/conf/tftp/fedora35

$(WORKSTATION_IMAGE):
	curl -O https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/35/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-35-1.2.iso

$(VMLINUZ): $(WORKSTATION_IMAGE)
	mkdir -p $(MOUNT_TARGET)
	sudo mount -o loop $< $(MOUNT_TARGET)

$(PXELINUX_CONF): conf/default
	mkdir -p $(dir $@)
	cp $< $@

$(VM_IMAGE):
	mkdir -p $(dir $@)
	qemu-img create -f qcow2 $@ 20G

$(PXELINUX.0): /usr/share/syslinux/pxelinux.0
	mkdir -p $(dir $@)
	cp $< $@
	cp $(dir $<)*.c32 $(dir $@)

.httpserver.pid: $(VMLINUZ)
	python3 -m http.server --directory $(MOUNT_TARGET)/LiveOS & echo "$$!" > $@

.PHONY: run
run: $(VM_IMAGE) $(PXELINUX_CONF) $(PXELINUX.0) $(VMLINUZ) .httpserver.pid
	-qemu-kvm -cpu host -accel kvm \
		-netdev user,id=net0,net=192.168.88.0/24,tftp=$(CURDIR)/build/conf/tftp/,bootfile=pxelinux.0 \
		-smp 2 \
		-device virtio-net-pci,netdev=net0 \
		-object rng-random,id=virtio-rng0,filename=/dev/urandom \
		-device virtio-rng-pci,rng=virtio-rng0,id=rng0,bus=pci.0,addr=0x9 \
		-serial stdio -boot n -m 4096 -hda $<
	-sudo umount $(MOUNT_TARGET)
	-kill $(shell cat .httpserver.pid)
	rm .httpserver.pid

.PHONY: clean
clean:
	rm -rf build/
