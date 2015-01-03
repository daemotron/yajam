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

if ! [ -t 1 ] || ! [ -t 2 ]; then
    USE_COLORS="no"
fi

if [ ${USE_COLORS} = "yes" ]; then
    COLOR_RESET="\033[0;0m"
    COLOR_RESET_REAL="${COLOR_RESET}"
    COLOR_BOLD="\033[1m"
    COLOR_UNDER="\033[4m"
    COLOR_BLINK="\033[5m"
    COLOR_BLACK="\033[0;30m"
    COLOR_RED="\033[0;31m"
    COLOR_GREEN="\033[0;32m"
    COLOR_AMBER="\033[0;33m"
    COLOR_BLUE="\033[0;34m"
    COLOR_MAGENTA="\033[0;35m"
    COLOR_CYAN="\033[0;36m"
    COLOR_LIGHT_GRAY="\033[0;37m"
    COLOR_DARK_GRAY="\033[1;30m"
    COLOR_LIGHT_RED="\033[1;31m"
    COLOR_LIGHT_GREEN="\033[1;32m"
    COLOR_YELLOW="\033[1;33m"
    COLOR_LIGHT_BLUE="\033[1;34m"
    COLOR_LIGHT_MAGENTA="\033[1;35m"
    COLOR_LIGHT_CYAN="\033[1;36m"
    COLOR_WHITE="\033[1;37m"
fi

: ${COLOR_WARN:=${COLOR_YELLOW}}
: ${COLOR_DEBUG:=${COLOR_CYAN}}
: ${COLOR_ERROR:=${COLOR_RED}}
: ${COLOR_INFO:=${COLOR_LIGHT_GRAY}}
: ${COLOR_SUCCESS:=${COLOR_GREEN}}
: ${COLOR_IGNORE:=${COLOR_DARK_GRAY}}
: ${COLOR_SKIP:=${COLOR_AMBER}}
: ${COLOR_FAIL:=${COLOR_RED}}
