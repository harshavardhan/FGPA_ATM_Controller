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
	echo "Synopsis: $0 [-d <depend-branch>] <user>/<repo>[/<branch>]" 1>&2
	echo "  <user>   - the github.com user (required)" 1>&2
	echo "  <repo>   - the github.com repository (required)" 1>&2
	echo "  <branch> - the git branch to fetch (default: master/common)" 1>&2
	exit 1
}

unset DEPEND_BRANCH
while getopts d: OPT; do
	case "$OPT" in
		d)
			DEPEND_BRANCH=$OPTARG
			;;
	esac
done
shift $(($OPTIND - 1))

if [ $# -ne 1 ]; then
	usage
fi

TOPDIR=$(dirname $(dirname $0))
if [ -e ${TOPDIR}/common ]; then
	if [ -e ${TOPDIR}/common/.branch ]; then
		# The common dir has a .branch - use it as default
		DEFAULT_BRANCH=$(cat ${TOPDIR}/common/.branch)
	else
		# The common dir has no branch; it's probably a local .git repo, so default to dev
		DEFAULT_BRANCH=dev
	fi
else
	# There is no common dir yet, so we're just getting started - default to master
	DEFAULT_BRANCH=master
fi
COMMON_USER=makestuff
OLDIFS=${IFS}
IFS='/'
set -- $1
IFS=${OLDIFS}
if [ "$#" -eq "2" ]; then
	USER=$1
	REPO=$2
	BRANCH=${DEFAULT_BRANCH}
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

echo "Fetching \"${USER}/${REPO}/${BRANCH}\"..."
wget --no-check-certificate -q -O ${USER}-${REPO}-${BRANCH}.tgz https://github.com/${USER}/${REPO}/archive/${BRANCH}.tar.gz
if [ "$?" != 0 ]; then
	echo "Fetch of \"${USER}/${REPO}/${BRANCH}\" failed. Are you sure it exists on GitHub?" 1>&2
	rm -f ${USER}-${REPO}-${BRANCH}.tgz
	exit 1
fi

echo "Uncompressing \"${USER}/${REPO}/${BRANCH}\" into \"${REPO}\" directory..."
tar zxf ${USER}-${REPO}-${BRANCH}.tgz
mv ${REPO}-${BRANCH} ${REPO}
rm -f ${USER}-${REPO}-${BRANCH}.tgz

if [ -n "${DEPEND_BRANCH}" ]; then
	BRANCH=${DEPEND_BRANCH}
fi
echo ${BRANCH} > ${REPO}/.branch

if [ "${USER}" != "${COMMON_USER}" -o "${REPO}" != "common" ]; then
	if [ -e ${TOPDIR}/common ]; then
		if [ "${DEFAULT_BRANCH}" != "${BRANCH}" ]; then
			echo
			echo "ERROR: A \"${TOPDIR}/common\" directory exists, but it's on the ${DEFAULT_BRANCH} branch. You" 2>&1
			echo "       should not try to mix different versions together; they must be" 2>&1
			echo "       consistent!" 2>&1
			exit 1
		fi
	else
		echo "Fetching \"${COMMON_USER}/common/${BRANCH}\"..."
		wget --no-check-certificate -q -O ${COMMON_USER}-common-${BRANCH}.tgz https://github.com/${COMMON_USER}/common/archive/${BRANCH}.tar.gz
		if [ "$?" != 0 ]; then
			echo "Fetch of \"${COMMON_USER}/common/${BRANCH}\" failed. Are you sure it exists?" 1>&2
			rm -f ${COMMON_USER}-common-${BRANCH}.tgz
			exit 1
		fi
		echo "Uncompressing \"${COMMON_USER}/common/${BRANCH}\" into \"${TOPDIR}/common\" directory..."
		tar zxf ${COMMON_USER}-common-${BRANCH}.tgz
		echo ${BRANCH} > common-${BRANCH}/.branch
		mv common-${BRANCH} ${TOPDIR}/common
		rm -f ${COMMON_USER}-common-${BRANCH}.tgz
	fi
fi
