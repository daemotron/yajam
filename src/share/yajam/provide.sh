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

b_ls=$(detect_binary "ls")

usage() {
    umsg="${COLOR_BOLD}usage: ${COLOR_RED}${COLOR_BOLD}yajam provide"
    umsg="${umsg} ${COLOR_WHITE}[${COLOR_RED}${COLOR_BOLD}-f${COLOR_WHITE}]"
    umsg="${umsg} [${COLOR_RED}${COLOR_BOLD}-s${COLOR_WHITE}]"
    umsg="${umsg} [${COLOR_GREEN}${COLOR_BOLD}version${COLOR_WHITE}]"

    echo -e "${umsg}

${COLOR_RED}${COLOR_BOLD}Options:
${COLOR_RED}${COLOR_BOLD}    -f${COLOR_RESET}          -- Force re-creation; i. e. delete any pre-
                   existing datasets for the specified version
${COLOR_RED}${COLOR_BOLD}    -s${COLOR_RESET}          -- Simulation mode. Do not apply any change,
                   just print out the to be performed operations

If ${COLOR_GREEN}${COLOR_BOLD}version${COLOR_RESET} is not specified, all existing version sets
are updated. The ${COLOR_RED}${COLOR_BOLD}-f${COLOR_RESET} option will then be ignored.

If ${COLOR_GREEN}${COLOR_BOLD}version${COLOR_RESET} is specified as ${COLOR_CYAN}major.minor${COLOR_RESET}, it is taken as RELENG version.
If ${COLOR_GREEN}${COLOR_BOLD}version${COLOR_RESET} is specified as ${COLOR_CYAN}major${COLOR_RESET}, it is taken as STABLE version.
"
}

# setup internal flags
PROVIDE_FORCE="no"
SIMULATE="no"

detect_versions() {
    { local ver=$($b_ls "${ZMOUNT}/${YJ_WRK}/"); }> /dev/null 2>&1
    echo ${ver}
}

version_exists() {
    [ -d "${ZMOUNT}/${YJ_WRK}/${1}" ] && return 0
    return 1
}

delete_version() {
    zfs_destroy "${ZMOUNT}/${YJ_WRK}/${1}" "-r -f" "${SIMULATE}"
    return $?
}

# evaluate command line options
while getopts "fs" FLAG; do
    case "${FLAG}" in
        f)
            PROVIDE_FORCE="yes"
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

shift $((OPTIND-1))
[ $# -ge 1 ] && VERSIONS=$@
[ $# -lt 1 ] && VERSIONS=$(detect_versions)
[ -z "${VERSIONS}" ] && die 1 "No versions found to be updated."

delete_version
exit 0
