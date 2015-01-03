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
}

log_debug() {
    COLOR_ARROW="${COLOR_DEBUG}${COLOR_BOLD}" \
    log "${COLOR_DEBUG}${COLOR_BOLD}Debug:${COLOR_RESET}${COLOR_IGNORE} $@" >&2
}


die() {
    if [ $# -ne 2 ]; then
        die 1 "die() expects 2 arguments: exit_number \"message\""
    fi
    log_error "${2}" || :
    exit $1
}

b_realpath=$(detect_binary "realpath")

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