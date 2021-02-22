# QNAP-PVE-J1900
QNAP install shell to J1900 or VM

源自老骥伏枥的脚本
修改了hal_app1-mod,代替hal_app,将hal_app的三个boot参数使用原来的hal_app1,其它参数使用系统的hal_app.

        case $1 in
	    --get_boot_pd ) 
            _pd="boot"
	    _arg=$1
            ;;
            --get_boot_pd_part ) 
	    _pd="part"
	    _arg=$1
	    ;;
	    --boot )
	    _pd="rootfs2"
	    ;;
            *)
	    /sbin/hal_app-orig $*
	    exit
	esac
  其它未变，这样就不用对/etc/init.d打补丁了。
  
  PVE intel GPU直通  GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on iommu=pt video=efifb:off,vesafb:off vfio-pci.ids=8086:0412"

  
     root@pve4670:/etc/pve/qemu-server# cat 101.conf
     args: -device vfio-pci,host=00:02.0,addr=0x18,x-vga=on,x-igd-opregion=on
     boot: order=sata0
     cores: 2
     efidisk0: local-lvm:vm-101-disk-1,size=4M
     ide2: local:iso/Windows20H2.iso,media=cdrom,size=4819136K
     machine: q35
     memory: 4096
     name: win10
     net0: e1000=D6:11:65:1A:B9:40,bridge=vmbr1,firewall=1
     numa: 0
     ostype: win10
     sata0: local-lvm:vm-101-disk-0,size=64G
     smbios1: uuid=47349b71-0e70-4a2f-b9d5-b549eefd9f79
     sockets: 1
     usb0: host=2-1,usb3=1
     usb1: host=2-2,usb3=1
     vga: none
     vmgenid: b1ae84f1-5df5-4765-8464-4163370038b1
     echo "nameserver 8.8.8.8" >> /etc/resolv.conf && rm /etc/apt/sources.list.d/pve-enterprise.list 
     export LC_ALL=en_US.UTF-8 && apt update && apt -y install git 
     git clone https://github.com/ivanhao/pvetools.git && cd pvetools && ./pvetools.sh


