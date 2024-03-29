#!/bin/bash
scriptname=${0##*/}
########################################################################
# copyrightyear         : (C) 2023
# copyrightowncer       : Robert E. Novak dba Sea2cloud
# rightsgranted         : All Rights Reserved
# location              : Cebu, Philippines 6000
########################################################################
#
# countfiles - Count the number of files underneath the directory 
#              passed as a parameter.
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
# 3.1 |REN|08/05/2023| Output of hostname changed, added verbose code
#                    | removed errecho
# 3.0 |REN|08/03/2022| New headers
# 2.2 |REN|03/15/2021| Fixed the column command invocation.
# 2.1 |REN|06/27/2020| brought up to date with getopts
# 2.0 |REN|12/03/2019| Modified to use more source'd functions
# 1.1 |REN|07/29/2010| Installed new prolog, cleaned up the
#                    | temporary files on exit and added a 
#                    | correct exit code
# 1.0 |REN|07/22/2010| Initial Release
#_____________________________________________________________________
#
source func.debug
source func.insufficient
source func.regex

####################
# set up local variables for debugging
####################
FUNC_DEBUG=${DEBUGOFF}
verbosemode="FALSE"
pingertmp=/tmp/${scriptname}_dir.$$
mkdir -p $pingertmp

####################
# USAGE
#
# pinger 	-h # Show Usage
#		-v # Verbose Mode
#		-p <IP Prefix>
#		-n <netmask for IPrefix>
#		-g <gateway for addr>
#		-I <Low PING port>
#		-O <High Ping port>
####################
subnet=$(hostname -I | sed -e 's/\.[^\.]* .*$//')
netdevice=$(ip route list default | cut -f 5 -d ' ')
netmask=$(ifconfig "$netdevice" | awk '/netmask/{ print $4;}')
gateway=$(ip r | grep default | awk -F " " '{print $3}')

USAGE="${0##*/} [-hv] [-p <IP Prefix] [-n IP netmask] [-g <gateway>]\n
\t\t[-I <low ping>] [-O <high ping>]\n\n
\t-h\t\t\tDisplay this message\n
\t-d\t<#>\tUse -vh to see debug levels\n
\t-v\t\t\tVerbose Mode\n
\t-p\t<IP Prefix>\tDefault on this machine is $subnet\n
\t-n\t<netmask>\tDefault on network on this device is $netdevice\n
\t\t\t\tDefault netmask on this machine is $netmask\n
\t-g\t<gateway>\tDefault on this machine is $gateway\n
\t-I\t<low ping port>\tDefault is ${subnet}.1\n
\t-O\t<high ping port\tDefault is ${subnet}.255\n
\t-X\t<excluded tests>\tlist of colon separated queries to exclude\n
\t\t\tarp:nslookup:arpscan:nmap:etchost\n
\t\t\tE.G., -X arp:nslookup\n
\t\t\twould exclude the arp and nslookup reports\n
"

verbosemode="FALSE"
configure_IPrefix="FALSE"
configure_IPnetmask="FALSE"
configure_gateway="FALSE"

####################
# Set the subnet and Mask Parameters
#
# This is the subnet 
####################
configure_IPrefix="TRUE"
subnet=$(hostname -I | sed -e 's/\.[^\.]* .*$//')
configure_IPnetmask="TRUE"

####################
# gateway Addresses
####################
gateway=$(ip route list default | cut -d ' ' -f 3)

####################
# Set the subnet port numbers for devices
#
# Low Port Number on Mergepoint for PING diagnostic
# High Port Number on Mergepoint for PING diagnostic
####################
Low_PING_Port=1
High_PING_Port=255

####################
# USAGE
#
# pinger 	-h # Show Usage
#		-v # Verbose Mode
#		-p <IP Prefix>
#		-n <netmask for IPrefix>
#		-g <gateway for addr>
#		-I <Low PING Address>
#		-O <High Ping Address>
####################
optionargs="hd:I:g:n:O:p:vX:"
NUMARGS=0
do_arp=1
do_nslookup=1
do_arpscan=1
do_etchosts=1
included="arp nslookup arpscan nmap etchosts"
excluded="nmap"
if [[ "${FUNC_DEBUG}" -gt "${DEBUGOFF}" ]] ; then
	echo "${scriptname}: Parameters are $*" >&2
fi
while getopts ${optionargs} name
do
	case ${name} in
		h)
			echo -e "${scriptname}:\n${USAGE}" >&2
			if [[ "${verbosemode}" == "TRUE" ]] ; then
				echo -e "${scriptname}:\n${DEBUG_USAGE}" >&2
			fi
			exit 0
			;;
		d)	
			if [[ "${OPTARG}" =~ ${re_digit} ]] ; then
				echo "${scriptname}:-d must be  digit ${OPTARG}" >&2
				exit 1
			fi
			FUNC_DEBUG="${OPTARG}"
			if [[ "${FUNC_DEBUG}" -ge \
				"${DEBUGSETX}" ]]; then
				set -x
			fi
			;;
		v)
			verbosemode="TRUE"
			verboseflag="-v"
			;;
		p)
			subnet=${OPTARG}
			configure_IPrefix="TRUE"
			;;
		n)
			netmask=${OPTARG}
			configure_IPnetmaks="TRUE"
			;;
		g)
			gateway=${OPTARG}
			configure_gateway="TRUE"
			;;
		I)
			Low_PING_Port=${OPTARG}
			configure_LowPING="TRUE"
			;;
		O)
			High_PING_Port=${OPTARG}
			configure_HighPING="TRUE"
			;;
		X)	excluded="${excluded} " \
				"$(echo ${OPTARG}|tr ':' ' ')"
			;;
		\?)	echo "${scriptname}:invalid option -${OPTARG}" >&2
			echo -e "${scriptname}:\n${USAGE}" >&2
			exit 1
			;;
	esac
done

shift "$((${OPTIND} - 1 ))"
subnet=$(hostname -I | sed -e 's/\.[^\.]* .*$//')
netdevice=$(ip route list default | cut -f 5 -d ' ')
netmask=$(ifconfig "$netdevice" | awk '/netmask/{ print $4;}')
gateway=$(ip r | grep default | awk -F " " '{print $3}')

if [[ "${verbosemode}" == "TRUE" ]] ; then
  echo "${scriptname}: subnet=${subnet}" >&2
  echo "${scriptname}: netdevice=${netdevice}" >&2
  echo "${scriptname}: netmask=${netmask}" >&2
  echo "${scriptname}: gateway=${gateway}" >&2
fi

####################
# Remove the excluded tests from the included list
####################
newincluded=""
for query in ${included}
do
	isexcluded=$(echo ${excluded}|grep '\w*'$query'\w*')

	if [[ -z "${isexcluded}" ]] ; then
		newincluded="${newincluded} ${query}"
	fi
done

if [[ $# -lt ${NUMARGS} ]] ; then
	insufficient ${NUMARGS} $@
	echo -e "${scriptname}:\n${USAGE}" >&2
	exit 2
fi
for query in ${newincluded}
do
	case $query in
		arp)
			if [[ $(which $query|wc -l) -ne 1 ]] ; then
				sudo apt-get update && \
					sudo apt-get install -y \
					net-tools
			fi
			;;
		arpscan)
			if [[ $(which arp-scan|wc -l) -ne 1 ]] ; then
				sudo apt-get update && \
					sudo apt-get install -y \
					arp-scan
			fi
			;;
		nslookup)
			if [[ $(which $query|wc -l) -ne 1 ]] ; then
				sudo apt-get update && \
					sudo apt-get install -y \
					dnsutils
			fi
			;;
		nmap)
			if [[ $(which $query|wc -l) -ne 1 ]] ; then
				sudo apt-get update && \
					sudo apt-get install -y \
					nmap
			fi
			;;
		etchosts)
			;;
	esac
done

if [[ "${FUNC_DEBUG}" -gt "${DEBUGOFF}" ]] ; then
	echo "${scriptname}: verbosemode=${verbosemode}" >&2
	echo "${scriptname}: subnet=${subnet}" >&2
	echo "${scriptname}: netmask=${netmask}" >&2
	echo "${scriptname}: gateway=${gateway}" >&2
	echo "${scriptname}: Low_PING_Port=${Low_PING_Port}" >&2
	echo "${scriptname}: High_PING_Port=${High_PING_Port}" >&2
fi

####################
# Set the names of various temporary files.
#
# Set the file name for the PING logging
####################
filepinglog="pingit"
grepall="grepall"
greplog="greplog"
arpscanlog="arpscanlog"
columnslog="col_log"

####################
# Set the full pathnames for the various files.
#
# Set the ping logging path and file
####################
pinglog=${pingertmp}/${filepinglog}
grepallfile=${pingertmp}/${grepall}
greplogfile=${pingertmp}/${greplog}
arpscanlogfile=${pingertmp}/${arpscanlog}
colfile=${pingertmp}/${columnslog}

####################
# Set various sleep timers
#
# Sleeptime after Ping
####################
pingsleep=1
####################
# provision BMCs
####################
rm -f ${pinglog}
for ((i=${Low_PING_Port}; i<=${High_PING_Port};i++))
do
	ipaddr="${subnet}.${i}"
	####################
        # 1 Ping to each node
	#  This was sped up a great deal by making the ping process
	#  a background process that sends the output to a unique file
	#  in /tmp and then scanning all of the addresses that worked.
	####################
        ping -w 1 -c 1 ${ipaddr} >> ${pinglog}-${i} 2>&1 &
done

if [[ "${FUNC_DEBUG}" -ge "${DEBUGSETX}" ]] ; then
	set -x
fi

####################
# Wait for the background processes to finish.
####################
if [[ $# -lt 1 ]] ; then
  sleeptime=5
else
  sleeptime=$1
fi
# echo "${0##*/} ${LINENO} sleeping for $sleeptime seconds"
# sleep $sleeptime
wait

####################
# get the list of files that had 100% loss
####################
grep -l "100% packet loss" ${pinglog}-* | sort -u > ${greplogfile}

####################
# Now get the list of all files
####################
sudo ls ${pinglog}-* > ${grepallfile}

####################
# take the difference between the two sets and generate a list of ports
# that answered, then echo the full IP address of those machines.
####################
declare -A ip_response ip_ping
echo -en "IP Address\tping?" | tee ${colfile}
for query in ${newincluded}
do
	case ${query} in
	arp) echo -en "\tarp" | tee -a ${colfile}; ;;
	nslookup) echo -en "\tnslookup" | tee -a ${colfile}; ;;
	arpscan)
		sudo arp-scan --localnet --retry 5 |grep -v DUP > ${arpscanlogfile}
		echo -en "\tarpscan" | tee -a ${colfile}
		;;
	etchosts) echo -en "\t/etc/hosts" | tee -a ${colfile}; ;;
	esac
done
echo "" | tee -a ${colfile}

for i in $(diff ${grepallfile} ${greplogfile} | sed -n -e "s/^<.*-\(.*\)$/\1/p")
do
	ipaddr="${subnet}.${i}"
	ip_response[${i}]=1
	ip_ping[${i}]=1
done
responders=0
#for i in { ${Low_PING_Port} ${High_PING_Port} }
for ((i=${Low_PING_Port};i<=${High_PING_Port};i++))
do
	thisline=""
	ipaddr="${subnet}.${i}"
	for query in ${newincluded}
	do
		case ${query} in
		arp)
			arp_response=$(arp ${ipaddr} | tail -1)
			arp_name=$(echo ${arp_response} | cut -d ' ' -f 1)
			if [[ "${arp_name}" == "${ipaddr}" ]] ; then
				no_entry="$(echo ${arp_response} | awk '{print $4}')"
				if [[ "${no_entry}" == "no" ]] ; then
					arp_name="no entry"
				else
					incomplete="$(echo ${arp_response} | awk '{print $2}')"
					if [[ "${incomplete}" == "(incomplete)" ]] ; then
						arp_name="incomplete"
					else
						arp_name=${incomplete}
						ip_response[${i}]=1
					fi
				fi
			fi
			thisline="${thisline}\t${arp_name}"
			;;
		nslookup)
			nslookup_name=$(nslookup ${ipaddr} | head -1 | cut -d ' ' -f 3)
      # nslookup=$(dig +noall +answer -x ${ipaddr} | head -1 | cut -d ' ' -f 2 | awk '{print $4}')
			if [[ "${nslookup_name}" == "can't" ]] ; then
				nslookup_name="not found"
			else
				nslookup_name=$(echo ${nslookup_name}|sed -e 's/\.$//')
				ip_response[${i}]=1
			fi
			thisline="${thisline}\t${nslookupname}"
			;;
		arpscan)
			arpscan_name=$(awk -F '\t' "/^${ipaddr}\\t/{print \$3}" < ${arpscanlogfile})
			if [[ -z "${arpscan_name}" ]] ; then
				arpscan_name="not found"
			else
				ip_response[${i}]=1
			fi
			thisline="${thisline}\t${arpscan_name}"
			;;
		etchosts) 
			hostdata=$(egrep '^'${ipaddr}'[^0-9]' /etc/hosts|sed  's/^.*\t//')

			if [[ ! -z "${hostdata}" ]] ; then
				thisline="${thisline}\t${hostdata}"
			fi
			;;
		esac
	done
	if [[ ! -z "${ip_response[${i}]}" ]] ; then
		if [[ ! -z "${ip_ping[${i}]}" ]] ; then
			pinged="yes"
		else
			pinged="no"
		fi
		echo -e "${ipaddr}\t${pinged}${thisline}" | tee -a ${colfile}
		((responders++))
	fi
done
if [[ "${FUNC_DEBUG}" == "${DEBUGOFF}"  ]] ; then
	clear
fi
####################
# Unless we are debugging, clean up all of the temporary files
####################
if [[ -r "${colfile}" ]] ; then
  cat ${colfile} | tr '\t' ';' | column -s ';' -t | more
else
  echo "${scriptname}:${FUNCNAME} ${LINENO} colfile not found = ${colfile}" >&2
  exit -1
fi

####################
# tell how many systems answered the queries (including pings)
####################
echo "${scriptname}: ${responders} out of $(wc -l ${colfile}) answered"
####################
# Unless we are debugging, clean up all of the temporary files
####################
if [[ "${FUNC_DEBUG}" -eq "${DEBUGOFF}" ]] ; then
	rm -rf "${grepallfile}" "${greplogfile}" "${pinglog}-*" \
    "${colfile}" "${pingertmp}"
fi

####################
# if there were no responses then exit with an error
####################
if [[ ${responders} -gt 0 ]] ; then
	exit 0
	rm -rf ${pingertmp}
else
	exit 257	# Since it is impossible for 257 nodes on a subnet
fi
