#!/bin/bash
scriptname=${0##*/}
########################################################################
# copyrightyear         : (C) 2022
# copyrightowncer       : Robert E. Novak
# rightsgranted         : All Rights Reserved
# location              : Modesto, CA 95356
########################################################################
#
# differ - compare a list of files in the local directory with their`
#          counterparts in a differen repo directory
#
# author                : Robert E. Novak
# authorinitials        : REN
# email                 : sailnfool@gmail.com
# license               : License CC
# licensor              : Sea2cloud Storage, Inc.
# licensurl     : https://creativecommons.org/licenses/by/4.0/legalcode
# licensename           : Creative Commons Attribution license
#_____________________________________________________________________
# Rev.|Aut| Date     | Notes
#_____________________________________________________________________
# 1.0 |REN|08/03/2022| Initial Release
#_____________________________________________________________________

declare -a list
declare -u response

source func.debug
source func.errecho
source func.insufficient
source func.regex

NUMARGS=1
verbosemode="FALSE"
verboseflag=""
FUNC_DEBUG=${DEBUGOFF}
repodir=""
declare -a filelist

USAGE="\n${0##*/} [-hv] [-d <#>] [-r <dir>] <file> [...]\n
\t\tFor each of the specified files, diff against the copy in\n
\t\trepo <dir> (mandatory), give a choice to Copy, Move, Delete\n
\t\tor Skip.  Select the files by a displayed number, enter 0\n
\t\tor Q to terminate\n
\t-d\t<#>\tSet the diagnostic levels.\n
\t\t\tUse -vh to see debug modes/levels\n
\t-h\t\tPrint this message\n
\t-v\t\tTurn on verbose mode\n
"
optionargs="d:hr:v"
while getopts ${optionargs} name
do
	case ${name} in
		d)
			if [[ ! "${OPTARG}" =~ $re_digit ]] ; then
				errecho "-d requires a decimal digit"
				errecho -e "${USAGE}"
				errecho -e "${DEBUG_USAGE}"
				exit 1
			fi
			FUNC_DEBUG="${OPTARG}"
			export FUNC_DEBUG
			if [[ $FUNC_DEBUG -ge ${DEBUGSETX} ]] ; then
				set -x
			fi
			;;
		h)
			errecho -e "${USAGE}"
			if [[ "${verbosemode}" == "TRUE" ]] ; then
				errecho -e "${DEBUG_USAGE}"
			fi
			exit 0
			;;
		r)
			if [[ ! -d "${OPTARG}" ]] ; then
				errecho "Not a directory ${OPTARG}"
				errecho -e "${USAGE}"
				exit 1
			fi
			repodir="${OPTARG}"
			;;
		v)
			verbosemode="TRUE"
			verboseflag="-v"
			;;
		\?)
			errecho "-e" "invalid option: -${OPTARG}"
			errecho "-e" "${USAGE}"
			exit 1
			;;
	esac
done

shift $((OPTIND-1))

if [[ -z "${repodir}" ]] ; then
	errecho "Mandatory -r not specified"
	errecho -e "${USAGE}"
	exit 1
fi

if [[ ! $# -ge "${NUMARGS}" ]] ; then
	errecho "At least one file must be specified"
	errecho -e "${USAGE}"
fi
while [[ $# -gt 0 ]]
do
	filelist+=("${1}")
	shift 1
done

echo "Enter 0 to exit"
select fname in "${filelist[@]}"
do
	echo "Enter 0 to exit"
	if [[ "${REPLY}" -eq 0 ]] ; then break; fi
	echo "You selected $fname (${REPLY})"
	echo diff $fname ${repodir}
	diff $fname ${repodir}
	read -p "Delete ${fname}, Skip, Copy, or Move (D/d|s|c|m) \$ " \
		response
	case ${response} in
		DELETE|D)
			rm ${fname}
			;;
		SKIP|S)
			echo "skipping ${fname}"
			;;
		COPY|C)
			cp ${fname} ${repodir}
			;;
		MOVE|M)
			mv ${fname} ${repodir}
			;;
		QUIT|Q)
			break
			;;
		\?)
			echo "Invalid response ${response}"
			break
			;;
	esac
done

