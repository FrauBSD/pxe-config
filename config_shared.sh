#!/bin/sh
# -*- tab-width: 8 -*- ;; Emacs
# vi: set noautoindent :: Vi/ViM
############################################################ IDENT(1)
#
# $Title: Script to re-generate shared netboot images $
# $Copyright: 2017-2018 Devin Teske. All rights reserved. $
# $Header: /cvsroot/druidbsd/pxe-config/config_shared.sh,v 1.1 2017/02/06 19:28:37 devinteske Exp $
# $FrauBSD: pxe-config/config_shared.sh 2018-11-28 13:27:41 -0800 freebsdfrau $
#
############################################################ CONFIGURATION

# Releases to generate
RELS="10.3-RELEASE 11.0-RELEASE"

# What to generate (format is `flags:prefix'; flags are for pxe-config.sh)
SETUP="-nuk: -nukz:flat -nu:mini -nuz:mini-flat"

# Types of compression to use (optional; format is `tool:suffix')
COMPRESSION="gzip:gz bzip2:bz2 xz:xz"

# Directory to copy shared bits to
SHARE_DIR="/vm/fraubsd/usr/local/www/apache22/data/dl/freebsd"

############################################################ FUNCTIONS

config()
{
	local options="$1" rel="$2" prefix="$3"
	local output="FreeBSD-$rel-amd64-disc1.netboot.iso"
	local shared="FreeBSD-$rel-amd64-disc1.${prefix:+$prefix-}netboot.iso"
	local compression tool suffix

	$PXE_CONFIG $options /images/FreeBSD-$rel-amd64-disc1.iso
	echo

	echo "Archiving to: $PWD"
	cp -f "/pxe/$output" "$shared"
	ls -li "$shared"
	for compression in $COMPRESSION; do
		tool=${compression%%:*} suffix=${compression#*:}
		echo "$tool $shared"
		$tool -c "$shared" > "$shared.$suffix"
		sync
		ls -li "$shared.$suffix"
	done
	echo
}

############################################################ MAIN

case "$0" in
 /*) PXE_CONFIG="${0%/*}/pxe-config.sh" ;;
*/*) PXE_CONFIG="$PWD/${0%/*}/pxe-config.sh" ;;
  *) PXE_CONFIG="$PWD/pxe-config.sh"
esac
[ -e "$PXE_CONFIG" ] && PXE_CONFIG=$(
	exec 2>&-
	readlink -f "$PXE_CONFIG" ||
	realpath "$PXE_CONFIG" ||
	echo "$PXE_CONFIG"
)

cd "$SHARE_DIR" || exit
for rel in $RELS; do
	echo $rel | awk '{ printf "\x1b[1m==> %s\x1b[0m\n\n", $0 }'
	for setup in $SETUP; do
		flags=${setup%%:*} prefix=${setup#*:}
		config $flags $rel $prefix
	done
done

################################################################################
# END
################################################################################
