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

# set up the yajam environment
SCRIPTPATH=$(/bin/realpath $0)
SCRIPTPREFIX=${SCRIPTPATH%/*}
. ${SCRIPTPREFIX}/common.sh

# detect required binaries
b_wc=$(detect_binary "wc")
b_zfs=$(detect_binary "zfs")

[ -z "${b_zfs}" ] && die 1 "Unable to detect the zfs binary"

usage() {
    umsg="${COLOR_BOLD}usage: ${COLOR_RED}${COLOR_BOLD}yajam init"
    umsg="${umsg} ${COLOR_WHITE}[${COLOR_RED}${COLOR_BOLD}-f${COLOR_WHITE}]"
    umsg="${umsg} [${COLOR_RED}${COLOR_BOLD}-s${COLOR_WHITE}]"

    echo -e "${umsg}

${COLOR_RED}${COLOR_BOLD}Options:
${COLOR_RED}${COLOR_BOLD}    -f${COLOR_RESET}          -- Force initialisation; i. e. delete any pre-
                   existing datasets at the specified location
${COLOR_RED}${COLOR_BOLD}    -s${COLOR_RESET}          -- Simulation mode. Do not apply any change,
                   just print out the to be performed operations
"
}

# setup internal flags
INIT_FORCE="no"
SIMULATE="no"

# evaluate command line options
while getopts "fs" FLAG; do
    case "${FLAG}" in
        f)
            INIT_FORCE="yes"
            ;;
        s)
            SIMULATE="yes"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# If the root data set already exists, destroy it if the -f option
# was used. Otherwise fail and inform the user.
zfs_exists "${ZPOOL}/${ZROOTFS}"
if [ "$?" -eq "0" ]; then
    if [ "${INIT_FORCE}" = "yes" ]; then
        zfs_destroy "${ZPOOL}/${ZROOTFS}" "-r -f" "${SIMULATE}" "no"
        [ "$?" -gt "0" ] && die 1 "Failed to delete zfs dataset ${ZPOOL}/${ZROOTFS}"
    else
        die 1 "zfs dataset ${ZPOOL}/${ZROOTFS} already exists"
    fi
fi

# Create the basic ZFS dataset structure
FAIL_FLAG=0
ZFS_FLAGS="-o atime=off -o exec=off -o setuid=off"
ZFS_LIST="${ZPOOL}/${ZROOTFS}/${YJ_SRV} ${ZPOOL}/${ZROOTFS}/${YJ_SYS}"
ZFS_LIST="${ZFS_LIST} ${ZPOOL}/${ZROOTFS}/${YJ_WRK} ${ZPOOL}/${ZROOTFS}/${YJ_TMP}"

# The root must be created separately (specification of mount point)
zfs_create "${ZPOOL}/${ZROOTFS}" "${ZFS_FLAGS} -o mountpoint=${ZMOUNT}" "${SIMULATE}" "no"
FAIL_FLAG=$((${FAIL_FLAG}+${?}))

for i in ${ZFS_LIST}; do
    zfs_create "$i" "${ZFS_FLAGS}" "${SIMULATE}" "no"
    FAIL_FLAG=$((${FAIL_FLAG}+${?}))
done

[ "${FAIL_FLAG}" -gt "0" ] && exit 1
exit 0
