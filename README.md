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
  
  
  

