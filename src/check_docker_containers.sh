#!/bin/bash
#
# -------------------------------------- Description ---------------------------------------------------
#
# Monitoring Docker Running Containers
# Usage example :
# ./check_docker_containers.sh -f /var/lib/file
#
# Adapted from a sysC0D file. https://github.com/sysC0D/nagios-plugin
#
#
# ------------------------------------- Requirements --------------------------------------------------
#
# Please add nagios user in group Docker
#
#         usermod -aG docker ${USER}
#
# If nagios have shell "/bin/false" -> chsh -s /bin/bash ${USER}
# Minimum Docker version -> 1.10.0
#
# define command on server, e.g. in  /etc/nagios/nrpe.d/FILE :
#    command[check_docker_containers]=/usr/local/bin/check_docker_containers.sh -f /usr/local/lib/check_docker_containers.txt
#
# /usr/local/lib/check_docker_containers.txt should contain a list of services to check. Alpha order.
#
#
# test from your nagios host:
#
#     /usr/lib/nagios/plugins/check_nrpe -H 1.2.3.4 -c check_docker_containers
#
#
# ---------------------------------------- License -----------------------------------------------------
#
# This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#----------------------------------------------------------------------------------------------------------

VERSION="Version 1.0"
AUTHOR="edguy3"
STATE_OK=0
STATE_WARN=1
STATE_CRIT=2
STATE_UNKN=3

#
## HELP ##
#

function print_help {
        echo "Usage: ./check_docker_containers.sh [-v] [-h] -f file
        -h, --help
        print this help message
        -v, --version
	print version program
	-f FILE
	-s, --status
	check if docker is alive"
}

#
## PRINT VERSION #
#

function print_version {
	echo "$VERSION $AUTHOR"
}

#
## MAIN
#
arg_namefile=""
arg_checkstatus="false"

while test -n "$1"; do
    case "$1" in
	-h|--help)
	    print_help
	    exit "$STATE_OK"
            ;;
	-v|--version)
            print_version
	    exit "$STATE_OK"
	    ;;
	-f|--file)
	    arg_namefile=$2
	    shift
	    ;;
	-s|--status)
	    arg_checkstatus="true"
	    ;;
	*)
	    echo "Unknown argument: $1"
	    print_help
	    exit $STATE_UNKN
	    ;;
     esac
     shift
done


#
## Exist Docker ##
#

function ifexist () {
        local namedocker="$1"
        checkdocker=`/usr/bin/docker ps --filter "name=^/$namedocker\$" | grep $namedocker`

        if [ ! -z "$checkdocker" ]
        then
                echo "true"
	fi
}



#Check version docker
valid_version=0
version_docker=`docker --version | awk '{split($0,a,","); print a[1]}' | sed "s/Docker version //g"`
major_param=`echo "$version_docker" | awk '{split($0,a,"."); print a[1]}'`
minor_param=`echo "$version_docker" | awk '{split($0,a,"."); print a[2]}'`
if [ "$major_param" -ge "1" ] && [ "$minor_param" -ge "13" ]
then
	valid_version=1
elif [ "$major_param" -ge "1" ] && [ "$minor_param" -ge "10" ]
then
	valid_version=0
elif [ "$major_param" -ge "1" ]
then
        valid_version=1
else
	echo "Docker version must be higher 1.10.0 for use this plugin"
	exit $STATE_UNKN
fi

if [ ! -z $arg_namefile ]
then
	results="";
	readarray -t master < $arg_namefile
	running=($(/usr/bin/docker ps | awk '{print $2}'| sort -u))
	/usr/bin/docker ps  --services --filter "status=running" 2> /tmp/dddd3


	for i in "${running[@]}"
	do
		if [[ ! " ${master[@]} " =~ " ${i} " ]]; then
			results="Extra $i ; $results"
			valcheck=WARNING
		fi
	done

	for i in "${master[@]}"
	do
		if [[ ! " ${running[@]} " =~ " ${i} " ]]; then
			results="Missing $i ; $results"
			valcheck=CRITICAL
		fi
	done

        if [[ $valcheck == *"CRITICAL"* ]]
	then
        	echo "$results ${valcheck}"
                exit $STATE_CRIT
        elif [[ $valcheck == *"WARNING"* ]]
	then
        	echo "$results ${valcheck}"
		exit $STATE_WARN
	elif [[ $valcheck == *"--help"* ]]
	then
		echo "$arg_namedocke UNKNOW - Please show --help"
    		exit $STATE_UNKN
	else
		echo "$arg_namedocker OK ${valstatus}${valcheck}"
		exit $STATE_OK
	fi
else
	echo "Docker file required, please show --help"
	exit $STATE_UNKN
fi
