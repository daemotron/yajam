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
If ${COLOR_GREEN}${COLOR_BOLD}version${COLOR_RESET} is specified as ${COLOR_CYAN}CURRENT${COLOR_RESET}, it is taken as CURRENT version.
"
}

# setup internal flags
PROVIDE_FORCE="no"
SIMULATE="no"

delete_version() {
    zfs_destroy "${ZPOOL}/${ZROOTFS}/${YJ_WRK}/${1}" "-r -f" "${SIMULATE}" "yes"
    return $?
}

build_version() {
    if [ $# -ne 1 ]; then
        die 1 "build_version() expects 1 argument: version"
    fi
    prog_msg "Cleansing obj directory for version ${1}"
    clean_obj ${1}
    [ "$?" -ne "0" ] && prog_fail && return 1
    prog_success
    prog_msg "Building userland for version ${1}"
    make_buildworld ${1}
    [ "$?" -ne "0" ] && prog_fail && return 1
    prog_success
    prog_msg "Preparing templates for version ${1}"
    make_template ${1}
    [ "$?" -ne "0" ] && prog_fail && return 1
    prog_success
    log_info "Version ${1} updated to $(version_detailed ${1})"
    return 0
}

create_version() {
    if [ $# -ne 1 ]; then
        die 1 "create_version() expects 1 argument: version"
    fi
    prog_msg "Creating structure for new FreeBSD version ${1}"
    local branch=$(get_branch $1)
    [ "$?" -ne "0" ] && prog_fail && return 1
    zfs_exists "${ZPOOL}/${ZROOTFS}/${YJ_WRK}/${1}"
    if [ "$?" -eq "0" ]; then
        if [ "${PROVIDE_FORCE}" = "yes" ]; then
            zfs_destroy "${ZPOOL}/${ZROOTFS}/${YJ_WRK}/${1}" "-r -f" \
                "${SIMULATE}" "yes"
            [ "$?" -ne "0" ] && prog_fail && return 1
        else
            prog_fail && return 1
        fi
    fi
    local flags="-o atime=off -o exec=off -o setuid=off"
    local zfs_list_parts="${YJ_SRC} ${YJ_TPL} ${YJ_TPL}/${YJ_MROOT}"
    zfs_list_parts="${zfs_list_parts} ${YJ_TPL}/${YJ_SKEL}"
    local zfs_list="${ZPOOL}/${ZROOTFS}/${YJ_WRK}/${1}"
    for i in ${zfs_list_parts}; do
        zfs_list="${zfs_list} ${ZPOOL}/${ZROOTFS}/${YJ_WRK}/${1}/${i}"
    done
    for i in ${zfs_list}; do
        zfs_create "$i" "${flags}" "${SIMULATE}" "yes"
        [ "$?" -ne "0" ] && prog_fail && return 1
    done
    flags="-o atime=off -o setuid=off"
    zfs_create" ${ZPOOL}/${ZROOTFS}/${YJ_WRK}/${1}/${YJ_OBJ}" "${flags}" \
        "${SIMULATE}" "yes"
    [ "$?" -ne "0" ] && prog_fail && return 1
    prog_success
    prog_msg "Checking out sources for version ${1}"
    svn_checkout "${1}" "${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC}"
    [ "$?" -ne "0" ] && prog_fail && return 1
    prog_success
    prog_msg "Adding ${1} version entries to ${YJ_SYS_SRCCONF}"
    insert_src_conf
    [ "$?" -ne "0" ] && prog_fail && return 1
    prog_success
    build_version ${1}
    return $?
}

update_version() {
    if [ $# -ne 1 ]; then
        die 1 "update_version() expects 1 argument: version"
    fi
    prog_msg "Updating source tree for FreeBSD version ${1}"
    svn_update "${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC}"
    [ "$?" -ne "0" ] && prog_fail && return 1
    prog_success
    build_version ${1}
    return $?
}

# evaluate command line options
while getopts "fsh" FLAG; do
    case "${FLAG}" in
        f)
            PROVIDE_FORCE="yes"
            ;;
        s)
            SIMULATE="yes"
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))
[ $# -ge 1 ] && VERSIONS=$@
[ $# -lt 1 ] && VERSIONS=$(versions_detect)
[ -z "${VERSIONS}" ] && VERSIONS=$(version_sys)
[ -z "${VERSIONS}" ] && die 1 "No versions found to be updated."

FAIL_FLAG=0
for version in "${VERSIONS}"; do
    version_exists ${version}
    if [ "$?" -eq "0" ]; then
        if [ "${PROVIDE_FORCE}" = "yes" ]; then
            delete_version ${version} && create_version ${version}
            FAIL_FLAG=$((${FAIL_FLAG}+${?}))
        else
            update_version ${version}
            FAIL_FLAG=$((${FAIL_FLAG}+${?}))
        fi
    else
        create_version ${version}
        FAIL_FLAG=$((${FAIL_FLAG}+${?}))
    fi
done

# try ensuring tmp is mounted noexec even if some operations failed
tmp_noexec_on

[ "${FAIL_FLAG}" -gt "0" ] && exit 1
exit 0
