#!/bin/sh
# This is developed by laojifuli to config QNAP system

CONFIG_FILE="./initrd/etc/model.conf"

# Define general functions
Calc_Dev_bus() {
    MYBUS=`echo $1 | cut -d':' -f1`
    DEV_BUS=`echo $1 | cut -d':' -f2`
    MYDEV=`echo $DEV_BUS | cut -d'.' -f1`
    MYFUNC=`echo $1 | cut -d'.' -f2`
    DEV_BUS=`printf "B%02d:D%02d:F%0d" "0x$MYBUS" "0x$MYDEV" "0x$MYFUNC"`
}

Usb_Config() {
    echo "Start to config the USB device..."
    USBDATA=`lspci | grep "USB controller" | cut -d' ' -f1`
    Calc_Dev_bus $USBDATA
    for i in 1 2 3 4 5 6 7 8 9
    do
        setcfg "Usb Port $i" "DEV_BUS" "$DEV_BUS" -f "$CONFIG_FILE"
        [ "$?" -ne 0 ] && return 1
    done 
    echo `lspci | grep "USB controller" | cut -d':' -f3` "config successful."
    return 0
}

Boot_Config() {
    echo "Start to config the BOOT device..."
    BOOT_BUS=`lspci | grep -m1 "SATA AHCI Controller" | cut -d' ' -f1`
    Calc_Dev_bus $BOOT_BUS
    setcfg "Boot Disk 1" "DEV_BUS" "$DEV_BUS" -f "$CONFIG_FILE"
    [ "$?" -ne 0 ] && return 1
    setcfg "Boot Disk 1" "DISK_DRV_TYPE" "ATA" -f "$CONFIG_FILE"
    [ "$?" -ne 0 ] && return 1
    echo `lspci | grep "SATA AHCI Controller" | cut -d':' -f3` "config successful."
    return 0
}

Network_Config() {
    echo "Start to config the NETWORK device..."
    NETWORK=`lspci -PP | grep "Ethernet controller:" | cut -d'/' -f1`
    Calc_Dev_bus `echo $NETWORK | cut -d' ' -f1`
    FIRTS=$DEV_BUS
    setcfg "System Network 1" "DEV_BUS" "$DEV_BUS" -f "$CONFIG_FILE"
    [ "$?" -ne 0 ] && return 1
    echo `lspci | grep "Ethernet controller:" | cut -d':' -f3` "config cuccessful."
    Calc_Dev_bus `echo $NETWORK | cut -d' ' -f2`
    setcfg "System Network 2" "DEV_BUS" "$DEV_BUS" -f "$CONFIG_FILE"
    [ "$?" -ne 0 ] && return 1
    [ "x$FIRTS" != "x$DEV_BUS" ] && echo "$INFO Config Successful."
    return 0
}

Disk_Config() {
    echo "Start to config the DISK POOL device..."
    SATA_BUS=`lspci -PP | grep "Marvell" | cut -d' ' -f1 | cut -d'/' -f1 | tr "\n" " "`
    INFO=`lspci -PP | grep -B0 "Marvell" | tr "\n" "@"`
    SATAINFO[0]=`echo $SATA_BUS | cut -d' ' -f1`
    SATAINFO[1]=`echo $SATA_BUS | cut -d' ' -f2`

    if [ "${SATAINFO[0]}" != "${SATAINFO[1]}" ]; then
        echo "There are more than one SATA devives was found:"
        SATANAME[0]=`echo $INFO | cut -d'@' -f1`
        SATANAME[1]=`echo $INFO | cut -d'@' -f2`
        i=0
        for x in $SATA_BUS; do
            Calc_Dev_bus $x
            echo "[$((i+1))]=>[$DEV_BUS]=>[${SATANAME[$i]}]"
            i=$((i+1))
        done
        echo "Please select the following [number] for the disl pool device:"
        read i
        [ "x$i" == "x" ] && return 1
        TARGET=`echo $SATA_BUS | cut -d' ' -f $i`
        [ "x$TARGET" == "x" ] && return 1
        echo "[$TARGET]"
    else
        TARGET=$SATA_BUS
    fi

    Calc_Dev_bus $TARGET
    for i in 1 2 3 4
    do
        setcfg "System Disk $i" "DEV_BUS" "$DEV_BUS" -f "$CONFIG_FILE"
        [ "$?" -ne 0 ] && return 1
    done
    echo `lspci | grep "Marvell" | cut -d':' -f3` "as disk pool config cuccessful."

    return 0
}

# Check CPU model
CPUINFO=`cat /proc/cpuinfo | grep -m1 "model name" | grep -q "J1900"`
[ "$?" -ne 0 ] && echo "This is not J1900 CPU machine. The tool will corrupted QNAP systemi!!!" && exit 1

# Do mount development partition
if [ ! -f ./initrd.boot ]; then
    mount /dev/sda2 /new_root
    [ "$?" -ne 0 ] && echo "Mount QNAP system failure." && exit 1
    cp /new_root/boot/initrd.boot ./
    umount /new_root
fi
mv ./initrd.boot ./initrd.boot.gz
[ "$?" -ne 0 ] && echo "Could not get the QNAP ramdisk file." && exit 1

if [ ! -d ./initrd ]; then
    echo "Start to un-pact the QNAP ramdisk..."
    ./unpacking initrd.boot.gz
    [ "$?" -ne 0 ] && echo "Unpacking QNAP system failure." && exit 1
fi
[ ! -f "$CONFIG_FILE" ] && "Could not find the model.conf file." $$ exit 1

# Do Boot device config
Boot_Config
[ "$?" -ne 0 ] && echo "Config Boot Disk failure." && exit 1
# Do USB device config
Usb_Config
[ "$?" -ne 0 ] && echo "Config USB Port failure." && exit 1
# Do Network device config
Network_Config
[ "$?" -ne 0 ] && echo "Config Network Port failure." && exit 1
# Do Disk device config
Disk_Config
[ "$?" -ne 0 ] && echo "Config Disks pool failure." && exit 1

# Rebuild the QNAP system
echo "Start to re-pact QNAP ramdisk..."
./repacking initrd.boot.gz
[ "$?" -ne 0 ] && echo "Rebuild the QNAP system failure." && exit 1
mv ./initrd.boot.gz ./initrd.boot
cksum ./initrd.boot > ./initrd.boot.cksum

# Put back the ramdisk back to QNAP system
mount /dev/sda2 /new_root
[ "$?" -ne 0 ] && echo "Mount QNAP system failure." && exit 1
cp ./initrd.boot /new_root/boot/initrd.boot
cp ./initrd.boot.cksum /new_root/boot/initrd.boot.cksum
umount /new_root

echo 
echo "All Configs Successful!"
echo "Please restart the QNAP System now. To take the new config active."
echo
exit 0
