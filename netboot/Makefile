# -*- tab-width: 8 -*- ;; Emacs
# vi: set noautoindent :: Vi/ViM
############################################################ IDENT(1)
#
# $Title: netboot makefile $
# $Copyright: 2006-2017 Devin Teske. All rights reserved. $
# $Header: /cvsroot/druidbsd/pxe-config/netboot/Makefile,v 1.12 2017/02/06 19:28:37 devinteske Exp $
# $FrauBSD: pxe-config/netboot/Makefile 2018-11-28 13:27:41 -0800 freebsdfrau $
#
############################################################ CONFIGURATION

SR		= sudo
MNT		= mnt
CONF		= etc/static.conf
MFSSIZE		= 16384
MFSINODE	= 8192
ARCHIVE		= netboot

NETBOOT_ETC = \
	devfs.conf \
	group \
	master.passwd \
	netconfig \
	services
	

PROGRAM_DIRS = bin sbin usr/bin usr/sbin
LIBRARY_DIRS = lib usr/lib
NETBOOT_PROGS = \
	arp \
	awk \
	cat \
	chmod \
	chown \
	chroot \
	cmp \
	cp \
	devfs \
	dhclient \
	dhclient-script \
	fetch \
	find \
	halt \
	hostname \
	ifconfig \
	init \
	kenv \
	kldstat \
	mdconfig \
	mkdir \
	mount \
	mount_nfs \
	mount_smbfs \
	newfs \
	printf \
	reboot \
	resolvconf \
	rm \
	route \
	sed \
	sh \
	sleep \
	stat \
	tail \
	tar \
	umount \
	xargs

############################################################ FUNCTIONS

_READCONF = . "$(CONF)" || exit

CHECKCONF_FUNC = \
	checkconf_err="!!! %s not defined in $(CONF)";		\
	checkconf()						\
	{							\
		local var retval=0;				\
		for var in $$*; do				\
			eval [ \"\$$$$var\" ] && continue;	\
			printf "$$checkconf_err" $$var >&2;	\
			retval=1;				\
		done;						\
		return $$retval;				\
	}

DIE_FUNC = \
	die() { [ "$$*" ] && echo "$$*" >&2; exit 1; }

DYNLIBS_FUNC = \
	dynlibs()							\
	{								\
		local OPTIND=1 OPTARG flag;				\
		local searchdirs=;					\
		local prog dir path;					\
		while getopts s: flag; do				\
			case "$$flag" in				\
			s) searchdirs="$$OPTARG" ;;			\
			esac;						\
		done;							\
		shift $$(( $$OPTIND - 1 ));				\
		for prog in $$*; do					\
			for dir in $${searchdirs:-""}; do		\
				path="$$STATIC_BASE/$$dir/$$prog";	\
				if [ -f "$$path" ]; then		\
					readelf -d "$$path" || :;	\
					break;				\
				fi;					\
			done;						\
		done 2> /dev/null | awk '				\
			$$2 == "(NEEDED)" && /Shared library/ {		\
				print substr($$NF, 2, length($$NF) - 2)	\
			}' | sort -u;					\
	}

EVAL2_FUNC = \
	exec 3<&1; eval2() { echo "$$@" >&3; eval "$$@"; }

MDEVS_FUNC = \
	mdevs()								\
	{								\
		local file="$$1";					\
		case "$$file" in					\
		/*) : fall through ;;					\
		 *) PWD=$$( readlink -f "$$PWD" );			\
		    file="$$PWD/$$file";				\
		esac;							\
		[ -e "$$file" ] && file=$$( readlink -f "$$file" );	\
		$(SR) mdconfig -lf "$$file";				\
	}

MOUNTED_FUNC = \
	mounted()						\
	{							\
		local dir="$$1";				\
		dir=$$( readlink -f "$$dir" ) || return;	\
		mount | awk -v dir="$$dir" '			\
			$$0 ~ " on " dir { exit found=1 }	\
			END { exit !found }			\
		';						\
	}

STAGE_FUNC = \
	stage()								\
	{								\
		local srcfile="$$STATIC_BASE/$${1\#/}";			\
		local destdir="$${2:-$${1%/*}}";			\
		destdir="static/$${destdir\#/}";			\
		$(SR) cp -f "$$srcfile" "$${destdir%/}/" || return;	\
		echo "/$${1\#/} -> $${destdir%/}/$${srcfile\#\#*/}";	\
	}

############################################################ MAIN TARGETS

all: remake

usage:
	@$(CHECKCONF_FUNC);						\
	 exec >&2;							\
	 if ! [ -f "$(CONF)" ] || ! . "$(CONF)"; then			\
	 	echo "WARNING: could not open $(CONF)";			\
	 else								\
	 	checkconf STATIC_BASE OUTPUT;				\
	 fi;								\
	 OUTPUT="$${OUTPUT:-OUTPUT}";					\
	 STATIC_BASE="$${STATIC_BASE:-STATIC_BASE}";			\
	 echo "Targets:";						\
	 echo "	all/default:	same as \`remake'";			\
	 echo "	almostclean:	Delete only files in static/";		\
	 echo "	archive:	Make \`distclean' archive in \`../'";	\
	 echo "	clean:		Delete $$OUTPUT and static/";		\
	 echo "	close:		Close $$OUTPUT";			\
	 echo "	copy:		Copy src into opened image";		\
	 echo "	distclean:	Delete $$OUTPUT, static/, and configs";	\
	 echo "	from_dep:	Re-make from stored dependencies";	\
	 echo "	help/usage:	Print this text and exit";		\
	 echo "	install:	Copy $$OUTPUT to $$STATIC_BASE/boot";	\
	 echo "	open:		Open $$OUTPUT";				\
	 echo "	remake:		Open, re-copy src, and close";		\
	 echo "	update_mtree:	Update mtree of clean static/";		\
	 echo "	update_static:	Update static/ binaries";		\
	 echo "	mtree:		Create basic static directories";	\
	 echo

help: usage

update_mtree:
	[ -d static ] || $(SR) mkdir -p static
	@$(DIE_FUNC); [ "$$( find static -type f )" ] || \
	 	die "ERROR: run \`$(MAKE) clean' first"
	@echo '# $$Header: /cvsroot/druidbsd/pxe-config/netboot/Makefile,v 1.12 2017/02/06 19:28:37 devinteske Exp $$' > etc/static.mtree
	cd static && $(SR) mtree -c -i -p . \
		gname,mode,uname,link,type >> ../etc/static.mtree

mtree:
	[ -d static ] || mkdir -p static
	$(SR) mtree -eU -f etc/static.mtree -p static

stage0:
	@$(_READCONF);							\
	 $(CHECKCONF_FUNC);						\
	 $(DIE_FUNC);							\
	 $(DYNLIBS_FUNC);						\
	 $(EVAL2_FUNC);							\
	 $(STAGE_FUNC);							\
	 [ -d static ] || eval2 $(MAKE) mtree || die;			\
	 checkconf STATIC_BASE || die;					\
	 echo ">>> Updating static/ with $$STATIC_BASE/:";		\
	 stage /libexec/ld-elf.so.1 || die;				\
	 for file in $(NETBOOT_PROGS); do				\
	 	found=;							\
	 	for dir in bin sbin usr/bin usr/sbin; do		\
	 		[ -f "$$STATIC_BASE/$$dir/$$file" ] && found=1;	\
	 		[ "$$found" ] || continue;			\
	 		stage /$$dir/$$file /stand/ || die;		\
	 		break;						\
	 	done;							\
	 	[ "$$found" ] ||					\
	 		die "$$file: No such file or directory";	\
	 done;								\
	 libs=$$( dynlibs -s "$(PROGRAM_DIRS)" $(NETBOOT_PROGS) );	\
	 liblibs="$$libs";						\
	 while [ "$$liblibs" ]; do					\
	 	liblibs=$$( dynlibs -s "$(LIBRARY_DIRS)" $$liblibs );	\
	 	libs=$$( echo "$$libs"; echo "$$liblibs" );		\
	 done;								\
	 libs=$$( echo "$$libs" | sort -u );				\
	 for lib in $$libs; do						\
	 	found=;							\
	 	for dir in $(LIBRARY_DIRS); do				\
	 		[ -f "$$STATIC_BASE/$$dir/$$lib" ] && found=1;	\
	 		[ "$$found" ] || continue;			\
	 		stage /$$dir/$$lib /lib/ || die;		\
	 		break;						\
	 	done;							\
	 	[ "$$found" ] ||					\
	 		die "$$lib: No such file or directory";		\
	 done;								\
	 for file in $(NETBOOT_ETC); do stage /etc/$$file || die; done

stage1: dep/mfsroot.gz
	@$(_READCONF);					\
	 $(CHECKCONF_FUNC);				\
	 $(DIE_FUNC);					\
	 $(EVAL2_FUNC);					\
	 checkconf OUTPUT || die;			\
	 case "$$OUTPUT" in				\
	 *.[Gg][Zz]) eval2 cp -i $(?) \"$$OUTPUT\" ;;	\
	 *) eval2 gunzip -c $(?) \> "$$OUTPUT";		\
	 esac

stage2:
	@$(_READCONF);							\
	 $(CHECKCONF_FUNC);						\
	 $(DIE_FUNC);							\
	 $(EVAL2_FUNC);							\
	 checkconf OUTPUT || die;					\
	 [ -f static/libexec/ld-elf.so.1 ] ||				\
	 	eval2 $(MAKE) update_static || die;			\
	 [ -f "$$OUTPUT" ] || eval2 $(MAKE) stage1 || die;		\
	 case "$$OUTPUT" in						\
	 *.[Gg][Zz]) eval2 gunzip -f \"$$OUTPUT\" || die ;;		\
	 esac;								\
	 eval2 mkdir -p \"$(MNT)\" || die;				\
	 md=$$( eval2 $(SR) mdconfig -f \"$${OUTPUT%.gz}\" ) || die;	\
	 echo "$$md";							\
	 trap "$(SR) mdconfig -d -u $${md#md}" EXIT;			\
	 eval2 $(SR) mount /dev/$$md \"$(MNT)\" || die;			\
	 trap - EXIT


stage3:
	mkdir -p src/netroot
	$(SR) cp -f version.inf $(MNT)/version.inf
	@$(DIE_FUNC);							\
	 $(EVAL2_FUNC);							\
	 set -e;							\
	 for dir in static src; do					\
	 	eval2 cd $$dir;						\
	 	eval2 find . -type d -mindepth 1			\
	 		-not -name CVS					\
	 		-exec $(SR) mkdir -pv '../$(MNT)/{}' '\;' ;	\
	 	eval2 find . -type f					\
	 		-not -path '\*/CVS/\*'				\
	 		-not -name .keep				\
	 		-exec $(SR) cp -fv '{}' '../$(MNT)/{}' '\;' ;	\
	 	eval2 find . -type l -exec sh -c \'			\
	 		$(SR) ln -nsfv "\$$( readlink {} )" "../mnt/{}"	\
	 	\' '\;' ;						\
	 	eval2 cd -;						\
	 	pwd;							\
	 done;								\
	 eval2 cd $(MNT);						\
	 eval2 $(SR) rm -f etc/pwd.db etc/spwd.db;			\
	 eval2 $(SR) pwd_mkdb -i -d etc etc/master.passwd

stage4:
	-[ ! -d "$(MNT)" ] || $(SR) umount $(MNT)
	[ ! -d "$(MNT)" ] || rmdir $(MNT)
	@$(_READCONF);						\
	 $(CHECKCONF_FUNC);					\
	 $(DIE_FUNC);						\
	 $(EVAL2_FUNC);						\
	 checkconf OUTPUT || die;				\
	 mfsroot="$${OUTPUT%.gz}";				\
	 for md in $$( $(SR) mdconfig -lv |			\
	 	awk -v pwd="$$( pwd )" -v mfsroot="$$mfsroot"	\
	 	'$$2 == "vnode" { md = $$1;			\
	 		sub("^[^[:space:]]+[[:space:]]+", "");	\
	 		sub("^[^[:space:]]+[[:space:]]+", "");	\
	 		sub("^[^[:space:]]+[[:space:]]+", "");	\
	 		if ($$0 == pwd "/" mfsroot) print md	\
	 	}' );						\
	 do							\
	 	eval2 $(SR) mdconfig -d -u $$md || die;		\
	 done;							\
	 case "$$OUTPUT" in					\
	 *.[Gg][Zz]) eval2 gzip \"$$mfsroot\" ;;		\
	 esac

update_static: stage0

from_dep: stage1 stage2 stage3 stage4

remake: stage2 stage3 stage4

open: stage2

copy: stage3

close: stage4

dep/mfsroot.gz:
	mkdir -p dep
	@$(_READCONF);							\
	 $(CHECKCONF_FUNC);						\
	 $(DIE_FUNC);							\
	 $(EVAL2_FUNC);							\
	 checkconf STATIC_BASE || die;					\
	 if [ -f "$$STATIC_BASE/boot/boot" ]; then			\
	 	BOOT="-B -b $$STATIC_BASE/boot/boot";			\
	 else								\
	 	BOOT="-r";						\
	 fi;								\
	 cleanup=;							\
	 eval2 dd if=/dev/zero of=dep/mfsroot count=$(MFSSIZE) bs=1k ||	\
	 	die;							\
	 cleanup="rm -f dep/mfsroot; $$cleanup";			\
	 trap "$$cleanup" EXIT;						\
	 md=$$( eval2 $(SR) mdconfig -at vnode -f dep/mfsroot ) || die;	\
	 cleanup="$(SR) mdconfig -d -u $${md#md}; $$cleanup";		\
	 trap "$$cleanup" EXIT;						\
	 if type bsdlabel > /dev/null 2>&1; then			\
	 	disklabel="bsdlabel";					\
	 else								\
	 	disklabel="disklabel";					\
	 fi;								\
	 eval2 $(SR) $$disklabel -w $$BOOT $$md auto || die;		\
	 eval2 $(SR) newfs -n -O1 -b 4096 -f 512			\
	 	-i $(MFSINODE) -o space -m 0 /dev/$$md || die;		\
	 trap - EXIT;							\
	 eval2 $(SR) mdconfig -d -u "$${md#md}" || die;			\
	 eval2 gzip -9 --no-name -fv dep/mfsroot

almostclean:
	$(SR) find static -type f -delete

clean:
	-$(SR) rm -f dep/mfsroot.gz
	-[ ! -d dep ] || rmdir dep
	-[ ! -d src/netroot ] || rmdir src/netroot
	-[ ! -d static ] || $(SR) rm -Rf static
	@$(_READCONF);						\
	 $(DIE_FUNC);						\
	 $(EVAL2_FUNC);						\
	 $(MDEVS_FUNC);						\
	 $(MOUNTED_FUNC);					\
	 [ ! -f "$(CONF)" ] || . "$(CONF)" || die;		\
	 while mounted mnt; do					\
	 	eval2 $(SR) umount mnt || die;			\
	 done;							\
	 [ -d mnt ] && eval2 rmdir mnt;				\
	 for md in $$( mdevs "$${OUTPUT%.*}" ); do		\
	 	eval2 $(SR) mdconfig -d -u "$${md#md}" || die;	\
	 done;							\
	 case "$$OUTPUT" in					\
	  "") : fall through ;;					\
	 *.*) eval2 rm -f "$$OUTPUT" "$${OUTPUT%.*}" ;;		\
	   *) eval2 rm -f "$$OUTPUT" "$$OUTPUT.gz";		\
	 esac

distclean: clean
	rm -f "$(CONF)"

install:
	@$(_READCONF);					\
	 $(CHECKCONF_FUNC);				\
	 $(DIE_FUNC);					\
	 $(EVAL2_FUNC);					\
	 checkconf DESTDIR OUTPUT || die;		\
	 [ -f "$$OUTPUT" ] || eval2 $(MAKE) all || die;	\
	 echo "OUTPUT=[$$OUTPUT]"; \
	 eval2 $(SR) cp -f "$$OUTPUT" "$${DESTDIR%/}/"

archive: distclean
	@$(DIE_FUNC);							\
	 $(EVAL2_FUNC);							\
	 version=$$( awk '						\
	 	function found(item) { print item; exit n++ }		\
	 	$$1 == "VERSION" && $$2 == "=" { found($$3) }		\
	 	$$1 == "VERSION=" { found($$2) }			\
	 	$$1 ~ /VERSION=.+/ { sub(/[^=]*=/, ""); found($$1) }	\
	 	END { exit !n }						\
	 ' version.inf ) ||						\
	 	die "!!! Unable to get VERSION from version.inf";	\
	 eval2 tar -c --exclude '*/CVS/*' --exclude 'CVS/*' -f - . |	\
	 	xz -9 - > ../$(ARCHIVE)-$$version.txz

################################################################################
# END
################################################################################
