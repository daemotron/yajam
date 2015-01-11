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

detect_binary() {
    local BINDIRS="/bin /usr/bin /sbin /usr/sbin /usr/local/bin /usr/local/sbin"
    local rval=""
    for i in ${BINDIRS}; do
        if [ -x "${i}/${1}" ]; then
            rval="${i}/${1}"
            break
        fi
    done
    echo $rval
}

b_grep=$(detect_binary "grep")
b_realpath=$(detect_binary "realpath")
b_wc=$(detect_binary "wc")
b_zfs=$(detect_binary "zfs")

log() {
    if [ -n "${COLOR_ARROW}" ] || [ -z "${1##*\033[*}" ]; then
        printf "${COLOR_ARROW}>>>${COLOR_RESET} ${1}${COLOR_RESET_REAL}\n"
    else
        printf ">>> ${1}\n"
    fi
}

log_error() {
    COLOR_ARROW="${COLOR_ERROR}${COLOR_BOLD}" \
        log "${COLOR_ERROR}${COLOR_BOLD}Error:${COLOR_RESET} $1" >&2
    return 0
}

log_warn() {
    COLOR_ARROW="${COLOR_WARN}${COLOR_BOLD}" \
        log "${COLOR_WARN}${COLOR_BOLD}Warning:${COLOR_RESET} $@" >&2
    return 0
}

log_debug() {
    COLOR_ARROW="${COLOR_DEBUG}${COLOR_BOLD}" \
        log "${COLOR_DEBUG}${COLOR_BOLD}Debug:${COLOR_RESET}${COLOR_IGNORE} $@" >&2
    return 0
}

prog_msg() {
    COLOR_ARROW="${COLOR_INFO}${COLOR_BOLD}"
    printf "${COLOR_ARROW}>>>${COLOR_RESET} ${COLOR_INFO}${1}"
    printf "${COLOR_BOLD} ... ${COLOR_RESET_REAL}"
}

prog_success() {
    printf "${COLOR_SUCCESS}${COLOR_BOLD}success${COLOR_RESET_REAL}\n"
}

prog_fail() {
    printf "${COLOR_FAIL}${COLOR_BOLD}fail${COLOR_RESET_REAL}\n"
}

die() {
    if [ $# -ne 2 ]; then
        die 1 "die() expects 2 arguments: exit_number \"message\""
    fi
    log_error "${2}" || :
    exit $1
}

zfs_create() {
    if [ $# -ne 4 ]; then
        die 1 "zfs_create() expects 4 arguments: \"dataset\", \"flags\", \"simulate\" and \"quiet\""
    fi
    [ "${4}" != "yes" ] && prog_msg "Creating zfs dataset ${1}"
    if [ "${3}" = "yes" ]; then
        rval=0
    else
        {
            ${b_zfs} create ${2} ${1}
        }> /dev/null 2>&1
        rval=$?
    fi
    [ "${rval}" -ne "0" ] && [ "${4}" != "yes" ] && prog_fail
    [ "${rval}" -eq "0" ] && [ "${4}" != "yes" ] && prog_success
    return ${rval}
}

zfs_destroy() {
    if [ $# -ne 4 ]; then
        die 1 "zfs_destroy() expects 4 arguments: \"dataset\", \"flags\", \"simulate\" and \"quiet\""
    fi
    local flags="${2}"
    [ "${3}" = "yes" ] && flags="${flags} -n"
    [ "${4}" != "yes" ] && prog_msg "Deleting zfs dataset ${1}"
    {
        ${b_zfs} destroy ${flags} ${1};
    }> /dev/null 2>&1
    rval=$?
    [ "${rval}" -ne "0" ] && [ "${4}" != "yes" ] && prog_fail
    [ "${rval}" -eq "0" ] && [ "${4}" != "yes" ] && prog_success
    return ${rval}
}

zfs_exists() {
    # Check if a ZFS dataset already exists. If true, return 0.
    # Otherwise, return an exit status of 1.
    if [ $# -ne 1 ]; then
        die 1 "zfs_exists() expects 1 argument: \"dataset\""
    fi
    {
        local rval=$(${b_zfs} list -H -o name ${1} | ${b_wc} -l)
    }> /dev/null 2>&1
    [ ${rval} -eq "1" ] && return 0
    return 1
}

get_branch() {
    # return the correct branch path (i. e. "base/stable" or "base/releng") for
    # a given version number. Versions with major AND minor component
    # (e. g. "10.1") will point to the "RELENG" branch, whereas major only
    # versions (e. g. "10") will point to the "STABLE" branch.
    if [ $# -ne 1 ]; then
        die 1 "get_branch() expects 1 argument: version"
    fi
    local release=$(echo ${1} | $b_grep -E '^[[:digit:]]{1,2}\.[[:digit:]]{1,2}\.[[:digit:]]{1,2}\.{0,1}[[:digit:]]{0,1}$' | $b_wc -l)
    local releng=$(echo ${1} | $b_grep -E '^[[:digit:]]{1,2}\.[[:digit:]]{1,2}$' | $b_wc -l)
    local stable=$(echo ${1} | $b_grep -E '^[[:digit:]]{1,2}$' | $b_wc -l)
    local current=$(echo ${1} | $b_grep -E '^(cur|Cur|CUR|current|Current|CURRENT|head|Head|HEAD)$' | $b_wc -l)
    if [ "${stable}"  -eq "1" ]; then
        if [ "${1}" -eq "${YJ_FBSD_CURRENT}" ]; then
            stable=0
            current=1
        elif [ "${1}"  -gt "${YJ_FBSD_CURRENT}" ]; then
            stable=0
        fi
    fi
    [ "${release}" -eq "1" ] && echo "${YJ_SVN_RELEASE}/${1}" && return 0
    [ "${releng}" -eq "1" ] && echo "${YJ_SVN_RELENG}/${1}" && return 0
    [ "${stable}" -eq "1" ] && echo "${YJ_SVN_STABLE}/${1}" && return 0
    [ "${current}" -eq "1" ] && echo "${YJ_SVN_CURRENT}" && return 0
    return 1
}

# cd into / to avoid foot-shooting if running from deleted dirs or
# NFS dir which root has no access to.
SAVED_PWD="${PWD}"
cd /

# Pre-set information from calling binary
: ${YAJAM_STATUS:=0}
: ${USE_COLORS:=yes}

# include non-configurable defaults
. ${SCRIPTPREFIX}/include/defaults.sh

# include output coloring helpers
. ${SCRIPTPREFIX}/include/color.sh

# look for the yajam configuration file
[ -z "${YAJAM_ETC}" ] &&
    YAJAM_ETC=$(${b_realpath} ${SCRIPTPREFIX}/../../etc)
# If this is a relative path, add in ${PWD} as a cd / is done.
[ "${YAJAM_ETC#/}" = "${YAJAM_ETC}" ] && \
    YAJAM_ETC="${SAVED_PWD}/${YAJAM_ETC}"
if [ -r "${YAJAM_ETC}/${YJ_CONF}" ]; then
    . "${YAJAM_ETC}/${YJ_CONF}"
else
    die 1 "Unable to find a readable ${YJ_CONF} in ${YAJAM_ETC}"
fi

. ${SCRIPTPREFIX}/include/config.sh
