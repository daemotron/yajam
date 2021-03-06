#!/bin/sh
#
# Copyright (c) 2015 daemotron
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This file defines non-configurable defaults, that are used by
# yajam internally.

# Name of the FreeBSD src.conf file
YJ_SYS_SRCCONF=/etc/src.conf

# Tmp location
YJ_SYS_TMP=/tmp

# Name of the yajam etc directory
YJ_ETC=etc

# Name of the yajam configuration directory
YJ_YAJAMD=yajam.d

# Name of the yajam configuration file
YJ_CONF=yajam.conf

# Name of the yajam src configuration file
YJ_SRCCONF=src.conf

# ZFS dataset for working files and templates
YJ_WRK=wrk

# ZFS dataset for system specific jails
YJ_SYS=sys

# ZFS dataset for general service jails
YJ_SRV=srv

# ZFS dataset for temporary operations
YJ_TMP=tmp

# ZFS dataset within a version for the source tree
YJ_SRC=src

# ZFS dataset within a version for the object files
YJ_OBJ=obj

# ZFS dataset within a version for the templates
YJ_TPL=tpl

# ZFS dataset for the mroot template (read-only part of a jail)
YJ_MROOT=mroot

# ZFS dataset for the skel template (writable part of a jail)
YJ_SKEL=skel

# Release base url within the subversion repository
YJ_SVN_RELEASE=base/release

# Releng base url within the subversion repository
YJ_SVN_RELENG=base/releng

# Stable base url within the subversion repository
YJ_SVN_STABLE=base/stable

# Current base url within the subversion repository
YJ_SVN_CURRENT=base/head

# Current version number
YJ_FBSD_CURRENT=11
