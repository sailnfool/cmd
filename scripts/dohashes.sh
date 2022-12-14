#!/bin/bash
scriptname=${0##*/}
########################################################################
# Copyright (C) 2022 Robert E. Novak  All Rights Reserved
# Modesto, CA 95356
########################################################################
#
# dohashes - Intended to create hash files for each file in a
#            directory.  Work suspended when I conceived canonical
#            cryptographic hash representation.  Needs to be resumed
#            after that is stable.
#
# From the root directory passed as a parameter,
#
# Author: Robert E. Novak aka REN
# email: sailnfool@gmail.com
# License CC by Sea2Cloud Storage, Inc.
# see https://creativecommons.org/licenses/by/4.0/legalcode
# for a complete copy of the Creative Commons Attribution license
#_____________________________________________________________________
# Rev.|Aut| Date     | Notes
#_____________________________________________________________________
# 1.3 |REN|07/01/2022| work suspended awaiting completion of canonical
#                    | cryptographic hash representation
# 1.2 |REN|05/16/2022| Added parameter override for the cryptographic
#                    | program to be executed.  Also created a
#                    | directory tree for all of the hash names of
#                    | both the files and the directories.
#                    | TBD: Break the files into chunks and compute
#                    | the hashes for the chunks to add them to the
#                    | dirtree to get a feel for the size of the
#                    | hashspace.
#                    | added -t to make the dirtree somewhere other
#                    | then /tmp
# 1.1 |REN|05/11/2022| Improved initial checking parameters
#                    | Added commentary outline for efficiently
#                    | Improving the count calculation and bypassing
#                    | using awk and bc to avoid overflow and for
#                    | improving efficiency.
# 1.0 |REN|03/26/2020| Initial Release
#_____________________________________________________________________
#
source func.debug
source func.errecho
source func.insufficient

########################################################################
# The following are hard coded for now.  Ideally they should be looked
# up in a global table.
########################################################################
chshhnum="1"
chshh="b2sum -a blake2bp"
chshhhexlen="128"
chshhfilenameoffset=$((chshhhexlen+2))
dirtree="/${HOME}/github/func/etc/dirtree"
NUMARGS=1
TMPFILE=/tmp/bins.$$
shortlen=4

USAGE="\r\n${0##*/} [-[hv]] [-d #] <dir> [<dir> ...]\r\n
\t\tSummarize the count of the number of files in this tree sorted by\r\n
\t\tthe size of the files.  This application is single threaded and\r\n
\t\tused the 'find' command.  The output is saved in the /tmp\r\n
\t\tdirectory.\r\n
\t-h\t\tPrint this message\r\n
\t-v\t\tProvide verbose help\r\n
\t-c\t<crypto>\tUse <crypto> instead of ${chshh} for computing\r\n
\t\t\tthe hash of the file and of the filename/path\r\n
\t-d\t#\tEnable diagnostics\r\n
\t-s\t#\tspecify the length of the short hash used.\r\n
\t-t\t<dir>\tSpecify the name of the hash directory tree \r\n
\t\t\tdefault: ${dirtree}\r\n
"
VERBOSE="Outputs the file bin sizes in human readable form:\r\n
B = Bytes\r\n
K = Kilobytes\t(kiB = 1024)\r\n
M = Megabytes\t(MiB)\r\n
G = Gigabytes\t(GiB)\r\n
T = Terabytes\t(TiB)\r\n
E = Exabytes\t(EiB)\r\n
P = Petabytes\t(PiB)\r\n
Y = Yettabytes\t(YiB)\r\n
Z = Zettabytes\t(ZiB)\r\n
"
optionargs="hvc:d:s:t:"
if [[ $# -lt "${NUMARGS}" ]]
then
	errecho "No directory specified"
  exit -1
fi

while getopts ${optionargs} name
do
  case ${name} in
  h)
    errecho -e ${USAGE}
    exit 0
    ;;
  v)
    errecho -e ${USAGE}
    errecho -e ${VERBOSE}
    exit 0
    ;;
  c)
    chshh="${OPTARG}"
    ;;
  d)
    FUNC_DEBUG="${OPTARG}"
    export FUNC_DEBUG
    ;;
  s)
    if [[ "${OPTARG}" =~ $re_integer ]]
    then
      errecho -e "-s ${OPTARG}\tis not an integer"
      errecho -e ${USAGE}
      exit 2
    fi
    shortlen="${OPTARG}"
    ;;
  t)
    if [[ ! -d "${OPTARG}" ]]
    then
      errecho -e "-t ${OPTARG}\tis not a directory"
      errecho -e ${USAGE}
      exit 3
    fi
    dirtree="${OPTARG}"
    ;;
  \?)
    errecho "-e" "invalid option: -${OPTARG}"
    errecho "-e" ${USAGE}
    exit 1
    ;;
  esac
done
shift $((OPTIND-1))

if [ $# -lt ${NUMARGS} ]
then
	errecho "-e" ${USAGE}
	insufficient ${NUMARGS} $@
  errecho -e ${USAGE}
	exit -2
fi

########################################################################
# Run through the remaining parameters and make sure they are all
# directories.  Quit if they are not.
########################################################################
for rootdir in $*
do
  if [[ ! -d ${rootdir} ]]
  then
    errecho "Not a directory: ${rootdir}"
    errecho -e ${USAGE}
    exit -1
  fi
done
suffixes="BKMGTEPYZ"

########################################################################
# Now that we have a list of directories, run through the list.  Find
# all of the files and compute both the hash of the file and the name
# of the file.
########################################################################
topdir=$(pwd)
for rootdir in $*
do

  ######################################################################
  # skip over any special root file system directories
  ######################################################################
  case $(realpath ${rootdir}) in
    /proc)
      continue
      ;;
    /lost+found)
      continue
      ;;
    /swapfile)
      continue
      ;;
    /dev)
      continue
      ;;
    /snap)
      continue
      ;;
  esac

  basedirname=${rootdir##*/}
  nodotbasedirname=$(echo ${basedirname} | tr "." "_")
  countprefix=/tmp/file.hashes.$$
  countprefix2=/tmp/file.hashes2.$$
  countname=${countprefix}.${nodotbasedirname}.txt

  ######################################################################
  # This code is not part of the main path.  May need to resurrect it
  # later.
  ######################################################################
#   echo "*** Start ***" > ${countname}
#   echo "*** Path = $(realpath ${rootdir})" >> ${countname}
#   echo "**** Dir = ${basedirname}" >> ${countname}
#   echo "***** Size $(du -s -h ${rootdir} 2> /dev/null )" >> ${countname}

  rm -f ${countprefix} ${countprefix2} ${countname}
  echo $(realpath ${rootdir})
  if [[ -d ${rootdir} ]]
  then
	  if [[ ! -r ${rootdir} ]]
	  then
	    echo skipping ${rootdir} not readable
	    continue
	  fi
  else
    continue
  fi
  filecount=$(countfiles ${rootdir})
  if [[ "${filecount}" -ge 2000 ]]
  then
    echo "$(realpath ${rootdir}) has ${filecount} files"
    goback=$(pwd)
    cd "${rootdir}"
    dohashes $(find . -maxdepth 1 -type d -print 2> /dev/null | sed 's/^\.$//')
    find .  -maxdepth 0 -type f -print 2>/dev/null \
      | parallel ${chshh} {} >> ${countname}
  else
	  ####################################################################
	  # search through the rootdir tree.  Compute the hash of each file
	  # found by "find" and save those hashes & filenames in countname.txt
	  ####################################################################
	  cd ${rootdir}
	  OLDIFS=$IFS
	  IFS=" "
	  find . -type f -print 2> /dev/null                                    \
	    | parallel ${chshh} {} 2> /dev/null >> ${countname}
  fi
  ######################################################################
  # For each of the hashcodes that we created, take the short prefix
  # and create a directory of the short prefix and touch a zero length
  # placeholder for the filename manifest.  Then compute the hash
  # of the filename and create the entries for that as well.
  ######################################################################
  while read -r full
  do
     short=${full:0:${shortlen}}
     long=${full:0:${chshhhexlen}}
     filename=${full:${chshhfilenameoffset}}
     filenamefull="$(echo "${filename}" | ${chshh} 2>/dev/null)"
     shortfilename=${filenamefull:0:${shortlen}}
     filenamelong=${filenamefull:0:${chshhhexlen}}
     filenamefullname=${filenamefull:${chshhfilenameoffset}}
     mkdir -p ${dirtree}/${short} ${dirtree}/${shortfilename}
     touch ${dirtree}/${short}/${chshhnum}:${long}
#     echo "${dirtree}/${shortfilename}/${chshhnum}:${filenamelong}"
     echo "${filename}" > ${dirtree}/${shortfilename}/${chshhnum}:${filenamelong}
  done < ${countname}
  cd ${goback}
done
