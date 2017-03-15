#!/bin/sh
#
# Copyright (C) 2012-2013 Chris McClelland
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
usage() {
	echo "Synopsis: $0 <user>/<repo>[/<branch>]" 1>&2
	echo "  <user>   - the github.com user (required)" 1>&2
	echo "  <repo>   - the github.com repository (required)" 1>&2
	echo "  <branch> - the git branch to fetch (default: dev)" 1>&2
	exit 1
}

if [ $# -ne 1 ]; then
	usage
fi

OLDIFS=${IFS}
IFS='/'
set -- $1
IFS=${OLDIFS}
if [ "$#" -eq "2" ]; then
	USER=$1
	REPO=$2
	BRANCH=dev
elif [ "$#" -eq "3" ]; then
	USER=$1
	REPO=$2
	BRANCH=$3
else
	usage
fi

if [ -e ${REPO} ]; then
	echo "Repository \"${REPO}\" already exists" 1>&2
	exit 1
fi

git clone -b ${BRANCH} git@github.com:${USER}/${REPO}.git ${REPO}
