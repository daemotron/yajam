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

# This file defines configurable defaults, which can be overridden
# by the yajam configuration file.

# ZFS zpool on which the jail infrastructure resides
: ${ZPOOL:=tank}

# root of the yajam zfs file system
: ${ZROOTFS:=jails}

# mount point for the yajam zfs file system
: ${ZMOUNT:=/jails}

# Subversion mirror server
: ${SVNMIRROR:=svn0.eu.freebsd.org}

# Maximum number of build processes
: ${MAXBUILD:=4}

# Link to Perl interpreter
: ${LINKPERL:=off}

# Root login class
: ${ROOTCLASS:=none}

# Disable FreeBSD pkg Repository
: ${FREEBSD_PKG:=off}

# Time Zone
: ${TIMEZONE:=none}
