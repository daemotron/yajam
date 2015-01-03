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

# Check if the selected root data set already exists
{
    ZROOT_EXISTS=$(${b_zfs} list -H -o name ${ZPOOL}/${ZROOTFS} | $b_wc -l)
}> /dev/null 2>&1

# If the root data set already exists, destroy it if the -f option
# was used. Otherwise fail and inform the user.
if [ "${ZROOT_EXISTS}" -ge "1" ]; then
    if [ "${INIT_FORCE}" = "yes" ]; then
        prog_msg "Deleting zfs dataset ${ZPOOL}/${ZROOTFS}"
        RUNFLAG="-f"
        [ "${SIMULATE}" = "yes" ] && RUNFLAG="-n"
        {
            ${b_zfs} destroy -r ${RUNFLAG} ${ZPOOL}/${ZROOTFS}
        }> /dev/null 2>&1
        if [ "$?" -ne "0" ]; then
            prog_fail
            die 1 "Failed to delete zfs dataset ${ZPOOL}/${ZROOTFS}"
        else
            prog_success
        fi
    else
        die 1 "zfs dataset ${ZPOOL}/${ZROOTFS} already exists"
    fi
fi

# Create the basic ZFS dataset structure
FAIL_FLAG=0
prog_msg "Creating zfs dataset ${ZPOOL}/${ZROOTFS}"
if [ "${SIMULATE}" = "yes" ]; then
    rval=0
else
    {
        ${b_zfs} create -o atime=off -o exec=off -o setuid=off \
            -o mountpoint=${ZMOUNT} ${ZPOOL}/${ZROOTFS};
    }> /dev/null 2>&1
    rval=$?
fi
[ "${rval}" -ne "0" ] && prog_fail
[ "${rval}" -eq "0" ] && prog_success
FAIL_FLAG=${rval}

prog_msg "Creating zfs dataset ${ZPOOL}/${ZROOTFS}/srv"
if [ "${SIMULATE}" = "yes" ]; then
    rval=0
else
    {
        ${b_zfs} create -o atime=off -o exec=off -o setuid=off \
            ${ZPOOL}/${ZROOTFS}/srv;
    }> /dev/null 2>&1
    rval=$?
fi
[ "${rval}" -ne "0" ] && prog_fail
[ "${rval}" -eq "0" ] && prog_success
FAIL_FLAG=$((${FAIL_FLAG}+${rval}))

prog_msg "Creating zfs dataset ${ZPOOL}/${ZROOTFS}/sys"
if [ "${SIMULATE}" = "yes" ]; then
    rval=0
else
    {
        ${b_zfs} create -o atime=off -o exec=off -o setuid=off \
            ${ZPOOL}/${ZROOTFS}/sys;
    }> /dev/null 2>&1
    rval=$?
fi
[ "${rval}" -ne "0" ] && prog_fail
[ "${rval}" -eq "0" ] && prog_success
FAIL_FLAG=$((${FAIL_FLAG}+${rval}))

prog_msg "Creating zfs dataset ${ZPOOL}/${ZROOTFS}/wrk"
if [ "${SIMULATE}" = "yes" ]; then
    rval=0
else
    {
        ${b_zfs} create -o atime=off -o exec=off -o setuid=off \
            ${ZPOOL}/${ZROOTFS}/wrk;
    }> /dev/null 2>&1
    rval=$?
fi
[ "${rval}" -ne "0" ] && prog_fail
[ "${rval}" -eq "0" ] && prog_success
FAIL_FLAG=$((${FAIL_FLAG}+${rval}))

prog_msg "Creating zfs dataset ${ZPOOL}/${ZROOTFS}/tmp"
if [ "${SIMULATE}" = "yes" ]; then
    rval=0
else
    {
        ${b_zfs} create -o atime=off -o exec=off -o setuid=off \
            ${ZPOOL}/${ZROOTFS}/tmp;
    }> /dev/null 2>&1
    rval=$?
fi
[ "${rval}" -ne "0" ] && prog_fail
[ "${rval}" -eq "0" ] && prog_success
FAIL_FLAG=$((${FAIL_FLAG}+${rval}))

[ "${FAIL_FLAG}" -gt "0" ] && exit 1
exit 0
