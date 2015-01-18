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

b_awk=$(detect_binary "awk")
b_cap_mkdb=$(detect_binary "cap_mkdb")
b_cat=$(detect_binary "cat")
b_chflags=$(detect_binary "chflags")
b_cp=$(detect_binary "cp")
b_grep=$(detect_binary "grep")
b_ln=$(detect_binary "ln")
b_ls=$(detect_binary "ls")
b_make=$(detect_binary "make")
b_mergemaster=$(detect_binary "mergemaster")
b_mkdir=$(detect_binary "mkdir")
b_more=$(detect_binary "more")
b_mount=$(detect_binary "mount")
b_mv=$(detect_binary "mv")
b_pw=$(detect_binary "pw")
b_realpath=$(detect_binary "realpath")
b_rm=$(detect_binary "rm")
b_sed=$(detect_binary "sed")
b_svn=$(detect_binary "svn")
[ -z "${b_svn}" ] && b_svn=$(detect_binary "svnlite")
b_sysctl=$(detect_binary "sysctl")
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

log_info() {
    COLOR_ARROW="${COLOR_INFO}${COLOR_BOLD}" \
        log "${COLOR_INFO}${COLOR_BOLD}Info:${COLOR_RESET}${COLOR_IGNORE} $@" >&2
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

versions_detect() {
    { local ver=$($b_ls "${ZMOUNT}/${YJ_WRK}/"); }> /dev/null 2>&1
    echo ${ver}
}

version_exists() {
    [ -d "${ZMOUNT}/${YJ_WRK}/${1}" ] && return 0
    return 1
}

version_detailed() {
    # get the detailed version string for the currently checked out sources
    if [ $# -ne 1 ]; then
        die 1 "version_detailed() expects 1 argument: \"version\""
    fi
    local revision=$(${b_grep} '^REVISION=' ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC}/sys/conf/newvers.sh |  ${b_sed} 's/.*="//g' | ${b_sed} 's/"//g')
    local branch=$(${b_grep} '^BRANCH=' ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC}/sys/conf/newvers.sh |  ${b_sed} 's/.*="//g' | ${b_sed} 's/"//g')
    local version="${revision}-${branch}"
    [ -z "${version}" ] && return 1
    echo "${version}" && return 0
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
        local rval=$(${b_zfs} list -H -t all -o name ${1} | ${b_wc} -l)
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

svn_checkout() {
    # check out a specified version from subversion.
    if [ $# -ne 2 ]; then
        die 1 "svn_checkout() expects 2 arguments: \"version\" and \"path\""
    fi
    local uri="$(get_branch ${1})"
    uri="https://${SVNMIRROR}/${uri}"
    { ${b_svn} checkout ${uri} ${2}; }> /dev/null 2>&1
    return $?
}

svn_update() {
    # check out a specified version from subversion.
    if [ $# -ne 1 ]; then
        die 1 "svn_update() expects 1 argument: \"path\""
    fi
    { $b_svn update ${1}; }> /dev/null 2>&1
    return $?
}

clean_obj() {
    # cleans the obj directory belonging to a specific version
    if [ $# -ne 1 ]; then
        die 1 "clean_obj() expects 1 argument: \"version\""
    fi
    ${b_chflags} -R noschg ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_OBJ}/*
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_OBJ}/*
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_OBJ}/.??*
    [ "$?" -ne "0" ] && return 1
    return 0
}

make_buildworld() {
    # make buildworld for a specific version
    if [ $# -ne 1 ]; then
        die 1 "make_buildworld() expects 1 argument: \"version\""
    fi
    {
        ${b_make} -j${MAX_JOBS} -C ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC} \
            buildworld;
    }> /dev/null 2>&1
    return $?
}

local_dirs() {
    # create `local` directory structure needed for updates
    if [ $# -ne 1 ]; then
        die 1 "local_dirs() expects 1 argument: \"version\""
    fi
    for i in local local/etc local/home local/root local/tmp local/var; do
        ${b_mkdir} -p ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/${i}
        [ "$?" -ne "0" ] && return 1
    done
    return 0
}

install_mroot() {
    # install mroot template for a specific version
    if [ $# -ne 1 ]; then
        die 1 "install_mroot() expects 1 argument: \"version\""
    fi
    # ensure /tmp is mounted without `noexec` option
    tmp_noexec_off
    [ "$?" -ne "0" ] && return 1
    {
        ${b_make} -C ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC} installworld \
            DESTDIR=${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT};
    }> /dev/null 2>&1
    [ "$?" -ne "0" ] && return 1
    {
        ${b_make} -C ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC} delete-old \
            -DBATCH_DELETE_OLD_FILES \
            DESTDIR=${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT};
        [ "$?" -ne "0" ] && return 1;
        ${b_make} -C ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC} delete-old-libs \
            -DBATCH_DELETE_OLD_FILES \
            DESTDIR=${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT};
        [ "$?" -ne "0" ] && return 1;
    }> /dev/null 2>&1
    tmp_noexec_on
    [ "$?" -ne "0" ] && return 1
    return 0
}

init_skel() {
    # initially populate the skel template for a specific version
    if [ $# -ne 1 ]; then
        die 1 "init_skel() expects 1 argument: \"version\""
    fi

    # Fail if symlinks have been created before
    [ -L "${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/etc" ] && return 1

    # create missing directories
    ${b_mkdir} ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/home
    [ "$?" -ne "0" ] && return 1
    ${b_mkdir} ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/usr-X11R6
    [ "$?" -ne "0" ] && return 1

    # move writable folders from mroot to skel template
    ${b_mv} ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/etc \
        ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/
    [ "$?" -ne "0" ] && return 1
    ${b_mv} ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/usr/local \
        ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/usr-local
    [ "$?" -ne "0" ] && return 1
    ${b_mv} ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/tmp \
        ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/
    [ "$?" -ne "0" ] && return 1
    ${b_mv} ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/var \
        ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/
    [ "$?" -ne "0" ] && return 1
    ${b_mv} ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/root \
        ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/
    [ "$?" -ne "0" ] && return 1

    # create symbolic links within the mroot template
    ${ln} -s "local/etc" ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/etc
    [ "$?" -ne "0" ] && return 1
    ${ln} -s "local/home" ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/home
    [ "$?" -ne "0" ] && return 1
    ${ln} -s "local/root" ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/root
    [ "$?" -ne "0" ] && return 1
    ${ln} -s "local/tmp" ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/tmp
    [ "$?" -ne "0" ] && return 1
    ${ln} -s "local/var" ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/var
    [ "$?" -ne "0" ] && return 1
    ${ln} -s "../local/usr-local" \
        ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/usr/local
    [ "$?" -ne "0" ] && return 1
    ${ln} -s "../local/usr-X11R6" \
        ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/usr/X11R6
    [ "$?" -ne "0" ] && return 1

    # Create symlinks for perl interpreter
    if [ "${LINKPERL}" = "on" ]; then
        ${b_ln} -s "../local/bin/perl" \
            ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/usr/bin/perl
        [ "$?" -ne "0" ] && return 1
        ${b_ln} -s "../local/bin/perl5" \
            ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/usr/bin/perl5
        [ "$?" -ne "0" ] && return 1
    fi
    return 0
}

merge_template() {
    # update templates with mergemaster and delete spare files
    if [ $# -ne 1 ]; then
        die 1 "merge_template() expects 1 argument: \"version\""
    fi
    # ensure /tmp is mounted without `noexec` option
    tmp_noexec_off
    [ "$?" -ne "0" ] && return 1
    {
        PAGER=${b_more} ${b_mergemaster} --run-updates=always \
        -m ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC} \
        -t ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/var/tmp/temproot \
        -D ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL} \
        -a;
    }> /dev/null 2>&1
    [ "$?" -ne "0" ] && return 1
    tmp_noexec_on
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/bin
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/boot
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/lib
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/libexec
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/mnt
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/proc
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/rescue
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/sbin
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/sys
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/usr
    [ "$?" -ne "0" ] && return 1
    ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}/dev
    [ "$?" -ne "0" ] && return 1
    if [ -d "${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/local" ]; then
        ${b_rm} -Rf ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/local
        [ "$?" -ne "0" ] && return 1
    fi
    return 0
}

config_template() {
    # create or update template configuration for a specific version
    if [ $# -ne 1 ]; then
        die 1 "config_template() expects 1 argument: \"version\""
    fi
    local skel_dir="${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_SKEL}"
    local mroot_dir="${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}"

    # provide resolv.conf (if not already existing)
    if [ ! -e "${skel_dir}/etc/resolv.conf" ]; then
        if [ -r ${YAJAMD}/${1}/resolv.conf ]; then
            ${b_cp} ${YAJAMD}/${1}/resolv.conf ${skel_dir}/etc/resolv.conf
            [ "$?" -ne "0" ] && return 1
        elif [ -r ${YAJAMD}/resolv.conf ]; then
            ${b_cp} ${YAJAMD}/resolv.conf ${skel_dir}/etc/resolv.conf
            [ "$?" -ne "0" ] && return 1
        elif [ -r /etc/resolv.conf ]; then
            ${b_cp} /etc/resolv.conf ${skel_dir}/etc/resolv.conf
            [ "$?" -ne "0" ] && return 1
        fi
    fi

    # provide rc.conf (if not already existing)
    if [ ! -e "${skel_dir}/etc/rc.conf" ]; then
        if [ -r ${YAJAMD}/${1}/rc.conf ]; then
            ${b_cp} ${YAJAMD}/${1}/rc.conf ${skel_dir}/etc/rc.conf
            [ "$?" -ne "0" ] && return 1
        elif [ -r ${YAJAMD}/rc.conf ]; then
            ${b_cp} ${YAJAMD}/rc.conf ${skel_dir}/etc/rc.conf
            [ "$?" -ne "0" ] && return 1
        fi
    fi

    # provide motd (if specific file has been provided)
    if [ -r ${YAJAMD}/${1}/motd ]; then
        ${b_cp} ${YAJAMD}/${1}/motd ${skel_dir}/etc/motd
        [ "$?" -ne "0" ] && return 1
    elif [ -r ${YAJAMD}/motd ]; then
        ${b_cp} ${YAJAMD}/motd ${skel_dir}/etc/motd
        [ "$?" -ne "0" ] && return 1
    fi

    # provide login.conf (if specific file has been provided)
    if [ -r ${YAJAMD}/${1}/login.conf ]; then
        ${b_cp} ${YAJAMD}/${1}/login.conf ${skel_dir}/etc/login.conf
        [ "$?" -ne "0" ] && return 1
        ${b_cap_mkdb} ${skel_dir}/etc/login.conf
        [ "$?" -ne "0" ] && return 1
    elif [ -r ${YAJAMD}/login.conf ]; then
        ${b_cp} ${YAJAMD}/login.conf ${skel_dir}/etc/login.conf
        [ "$?" -ne "0" ] && return 1
        ${b_cap_mkdb} ${skel_dir}/etc/login.conf
        [ "$?" -ne "0" ] && return 1
    fi

    # provide csh.cshrc (if specific file has been provided)
    if [ -r ${YAJAMD}/${1}/csh.cshrc ]; then
        ${b_cp} ${YAJAMD}/${1}/csh.cshrc ${skel_dir}/etc/csh.cshrc
        [ "$?" -ne "0" ] && return 1
    elif [ -r ${YAJAMD}/csh.cshrc ]; then
        ${b_cp} ${YAJAMD}/csh.cshrc ${skel_dir}/etc/csh.cshrc
        [ "$?" -ne "0" ] && return 1
    fi

    # provide root.cshrc (if specific file has been provided)
    if [ -r ${YAJAMD}/${1}/root.cshrc ]; then
        ${b_cp} ${YAJAMD}/${1}/root.cshrc ${skel_dir}/root/.cshrc
        [ "$?" -ne "0" ] && return 1
    elif [ -r ${YAJAMD}/root.cshrc ]; then
        ${b_cp} ${YAJAMD}/root.cshrc ${skel_dir}/root/.cshrc
        [ "$?" -ne "0" ] && return 1
    fi

    # (re-)install time zone
    [ -f "/etc/wall_cmos_clock" ] || ${b_rm} -f ${skel_dir}/etc/wall_cmos_clock
    [ -f "/etc/wall_cmos_clock" ] && \
        ${b_cp} /etc/wall_cmos_clock ${skel_dir}/etc/wall_cmos_clock
    local zoneinfo=""
    [ -r "${skel_dir}/var/db/zoneinfo" ] && \
        zoneinfo=$(${b_cat} ${skel_dir}/var/db/zoneinfo)
    [ -z "${zoneinfo}" ] && zoneinfo=${TIMEZONE}
    ${b_cp} ${mroot_dir}/usr/share/zoneinfo/${zoneinfo} \
        ${skel_dir}/etc/localtime
    [ "$?" -ne "0" ] && return 1
    echo "${zoneinfo}" > ${skel_dir}/var/db/zoneinfo
    [ "$?" -ne "0" ] && return 1

    # disable crontab timezone and entropy jobs (don't work in a jail anyway)
    ${b_sed} -i "" 's/\*\/11/#\*\/11/g' ${skel_dir}/etc/crontab
    [ "$?" -ne "0" ] && return 1
    ${b_sed} -i "" 's/1,31/#1,31/g' ${skel_dir}/etc/crontab
    [ "$?" -ne "0" ] && return 1

    # if configured, disable FreeBSD pkg repository
    if [ "${FREEBSD_PKG}" = "off" ]; then
        ${b_mkdir} -p ${skel_dir}/usr-local/etc/pkg/repos
        [ "$?" -ne "0" ] && return 1
        echo "FreeBSD: { enabled: no }" \
            > ${skel_dir}/usr-local/etc/pkg/repos/FreeBSD.conf
        [ "$?" -ne "0" ] && return 1
    fi

    # set root login class (if configured)
    if [ "${ROOTCLASS}" != "none" ]; then
        ${b_pw} -V ${skel_dir}/etc/ usermod root -L ${ROOTCLASS}
        [ "$?" -ne "0" ] && return 1
    fi

    return 0
}

snap_template() {
    # Create snapshots of the template set for a specific version
    if [ $# -ne 1 ]; then
        die 1 "snap_template() expects 1 argument: \"version\""
    fi
    local version=$(version_detailed ${1})
    local tpl_path=${ZPOOL}/${ZROOTFS}/${YJ_WRK}/${1}/${YJ_TPL}
    [ "$?" -ne "0" ] && return 1
    zfs_exists ${tpl_path}/${YJ_MROOT}@${version}
    [ "$?" -eq "0" ] && version="${version}.1"
    zfs_exists ${tpl_path}/${YJ_SKEL}@${version}
    [ "$?" -eq "0" ] && version="${version}.1"
    ${b_zfs} snapshot ${tpl_path}/${YJ_MROOT}@${version}
    [ "$?" -ne "0" ] && return 1
    ${b_zfs} snapshot ${tpl_path}/${YJ_SKEL}@${version}
    [ "$?" -ne "0" ] && return 1
    return 0
}

make_template() {
    # create or update templates for a specific version
    if [ $# -ne 1 ]; then
        die 1 "make_template() expects 1 argument: \"version\""
    fi

    # Check if the version has previously populated templates
    local is_update="no"
    if [ -L "${ZMOUNT}/${YJ_WRK}/${1}/${YJ_TPL}/${YJ_MROOT}/etc" ]; then
        is_update="yes"
        local_dirs ${1}
        [ "$?" -ne "0" ] && return 1
    fi

    # Install the mroot template. This step is always required.
    install_mroot ${1}
    [ "$?" -ne "0" ] && return 1

    # If this is the first time the templates are populated, initialise
    # the writable skeleton template.
    if [ "${is_update}" = "no" ]; then
        init_skel ${1}
        [ "$?" -ne "0" ] && return 1
    fi

    # Merge the skel configuration and clean up spare directories.
    # This step has to be performed for both, new creation and updates.
    merge_template ${1}
    [ "$?" -ne "0" ] && return 1

    # Configure the template.
    # This step has to be performed for both, new creation and updates.
    config_template ${1}
    [ "$?" -ne "0" ] && return 1

    # Create new snapshots for the template set.
    # This step has to be performed for both, new creation and updates.
    snap_template ${1}
    [ "$?" -ne "0" ] && return 1

    # Finally done :-)
    return 0
}

insert_src_conf() {
    # insert configuration for a version into src.conf
    if [ $# -ne 1 ]; then
        die 1 "insert_src_conf() expects 1 argument: \"version\""
    fi
    [ ! -w ${YJ_SYS_SRCCONF} ] && return 1
    echo ".if \${.CURDIR:M${ZMOUNT}/${YJ_WRK}/${1}/${YJ_SRC}} && !make(dummy)" \
        >> ${YJ_SYS_SRCCONF}
    echo "MAKEOBJDIRPREFIX?=   ${ZMOUNT}/${YJ_WRK}/${1}/${YJ_OBJ}" \
        >> ${YJ_SYS_SRCCONF}
    [ -r "${YAJAMD}/${YJ_SRCCONF}" ] && ${b_cat} ${YAJAMD}/${YJ_SRCCONF} \
        >> ${YJ_SYS_SRCCONF}
    echo ".endif" >> ${YJ_SYS_SRCCONF}
    return 0
}

detect_fs() {
    # detect the file system of a specific mount point.
    if [ $# -ne 1 ]; then
        die 1 "detect_fs() expects 1 argument: \"moint point\""
    fi
    local fs=$(${b_mount} | ${b_grep} "on ${1}" | ${b_awk} '{print $4}' | ${b_sed} 's/[^[:alnum:]]//g')
    [ -z "${fs}" ] && return 1
    echo "${fs}" && return 0
}

tmp_is_noexec() {
    # detect if /tmp is mounted with the noexec option
    local tmp=$(${b_mount} | ${b_grep} "on ${YJ_SYS_TMP}" | ${b_grep} 'noexec')
    [ -z "${tmp}" ] && return 1
    return 0
}

tmp_device() {
    # returns the device /tmp is mounted from
    local device=$(${b_mount} | ${b_grep} "on ${YJ_SYS_TMP}" | ${b_awk} '{print $1}')
    [ -z "${device}" ] && return 1
    echo "${device}" && return 0
}

get_tmp_flags() {
    # get the flags needed to mount /tmp (apart from exec/noexec)
    local noatime=$(${b_mount} | ${b_grep} "on ${YJ_SYS_TMP}" | ${b_grep} 'noatime')
    local nosuid=$(${b_mount} | ${b_grep} "on ${YJ_SYS_TMP}" | ${b_grep} 'nosuid')
    local acls=$(${b_mount} | ${b_grep} "on ${YJ_SYS_TMP}" | ${b_grep} 'acls')
    rval=""
    [ -n "${noatime}" ] && rval="-o noatime"
    if [ -n "${nosuid}" ]; then
        [ -z "${rval}" ] && rval="-o nosuid"
        [ -n "${rval}" ] && rval="${rval} -o nosuid"
    fi
    if [ -n "${acls}" ]; then
        [ -z "${rval}" ] && rval="-o acls"
        [ -n "${rval}" ] && rval="${rval} -o acls"
    fi
    echo "${rval}"
}

tmp_noexec_off() {
    # switch noexec option off for /tmp
    tmp_is_noexec
    [ "$?" -ne "0" ] && return 0
    local device=$(tmp_device)
    [ "$?" -ne "0" ] && return 1
    rval=0
    case "$(detect_fs ${YJ_SYS_TMP})" in
        zfs)
            ${b_zfs} set exec=on $device
            rval=$?
            ;;
        *)
            ${b_mount} -u -o "exec" $(get_tmp_flags) ${device}
            rval=$?
            ;;
    esac
    return ${rval}
}

tmp_noexec_on() {
    # switch noexec option on for /tmp
    [ "${TMP_NOEXEC}" = "off" ] && return 0
    tmp_is_noexec
    [ "$?" -eq "0" ] && return 0
    local device=$(tmp_device)
    [ "$?" -ne "0" ] && return 1
    rval=0
    case "$(detect_fs ${YJ_SYS_TMP})" in
        zfs)
            ${b_zfs} set exec=off $device
            rval=$?
            ;;
        *)
            ${b_mount} -u -o noexec $(get_tmp_flags) ${device}
            rval=$?
            ;;
    esac
    return ${rval}
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
    YAJAM_ETC=$(${b_realpath} ${SCRIPTPREFIX}/../../${YJ_ETC})
# If this is a relative path, add in ${PWD} as a cd / is done.
[ "${YAJAM_ETC#/}" = "${YAJAM_ETC}" ] && \
    YAJAM_ETC="${SAVED_PWD}/${YAJAM_ETC}"
YAJAMD="${YAJAM_ETC}/${YJ_YAJAMD}"
if [ -r "${YAJAM_ETC}/${YJ_CONF}" ]; then
    . "${YAJAM_ETC}/${YJ_CONF}"
elif [ -r "${YAJAMD}/${YJ_CONF}" ]; then
    . "${YAJAMD}/${YJ_CONF}"
else
    die 1 "Unable to find a readable ${YJ_CONF} in ${YAJAM_ETC} or ${YAJAMD}"
fi

# check if /tmp is noexec by default or not
tmp_is_noexec
if [ "$?" -eq "0" ]; then
    TMP_NOEXEC="on"
else
    TMP_NOEXEC="off"
fi

. ${SCRIPTPREFIX}/include/config.sh

# Limit the maximum number of build jobs to the number of CPUs available
cpus=$(${b_sysctl} -n hw.ncpu)
if [ "${cpus}" -ge "${MAXBUILD}" ]; then
    MAX_JOBS=${MAXBUILD}
else
    MAX_JOBS=${cpus}
fi

[ ! -f "/usr/share/zoneinfo/${TIMEZONE}" ] && \
    TIMEZONE=$(${b_cat} /var/db/zoneinfo)
