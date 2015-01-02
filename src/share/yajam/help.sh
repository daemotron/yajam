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

umsg="${COLOR_BOLD}usage: ${COLOR_RED}${COLOR_BOLD}yajam ${COLOR_WHITE}["
umsg="${umsg}${COLOR_RED}${COLOR_BOLD}-e ${COLOR_GREEN}${COLOR_BOLD}etcdir"
umsg="${umsg}${COLOR_WHITE}] [${COLOR_RED}${COLOR_BOLD}-N${COLOR_WHITE}]"
umsg="${umsg} ${COLOR_RED}${COLOR_BOLD}command ${COLOR_WHITE}[${COLOR_GREEN}"
umsg="${umsg}${COLOR_BOLD}options${COLOR_WHITE}]"

echo -e "$umsg

${COLOR_RED}${COLOR_BOLD}Options:
    -e ${COLOR_GREEN}${COLOR_BOLD}etcdir${COLOR_RESET}   -- Specify an alternate etc/ dir where poudriere configuration
                   resides.
${COLOR_RED}${COLOR_BOLD}    -N${COLOR_RESET}          -- Disable colors

${COLOR_RED}${COLOR_BOLD}Commands:
${COLOR_GREEN}${COLOR_BOLD}    help${COLOR_RESET}        -- Show usage
${COLOR_GREEN}${COLOR_BOLD}    version${COLOR_RESET}     -- Show the version of yajam
"

exit ${YAJAM_STATUS}
