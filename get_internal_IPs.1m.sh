#!/bin/bash

# <bitbar.title>show_IP_info</bitbar.title>
# <bitbar.author>Neil Brown</bitbar.author>
# <bitbar.author.github>neilzone</bitbar.author.github>
# <bitbar.desc>Shows current internal IP address(es).</bitbar.desc>


# Andrews & Arnold (aaisp) quota collector
# If you are an A&A customer and want to show your broadband quota on a single service, complete the lines below and remove the leading # from each
# You can get your Andrews & Arnold service ID from by using: https://chaos2.aa.net.uk/broadband/services?control_login={username}&control_password={password}
# You do not need to do anything if you are not an A&A customer; this script will still run, but will omit anything to do with A&A quota

#LOGIN=
#PASSWORD=
#SERVICE=

# By default, this script checks for addresses assigned to the en0 (Wi-Fi) interface and the ipsec0 (IPSec) interface. If you want to monitor other interfaces, change en0 to the appropriate interface name or add other interfaces


WiFi_status=$(ifconfig en0 | grep "status: " | awk '{print $2}')
IPv4_internal=$(ifconfig en0 | grep "inet " | awk '{print $2}')
IPv6_internal=$(ifconfig en0 | grep "autoconf secured " | awk '{print $2}')


# check if there is an IPSec interface and, if so, set variables
IPSec_status=$(ifconfig | grep "ipsec0")
if [ ! -z "$IPSec_status" ]; then
	IPSec_IPv4=$(ifconfig ipsec0 | grep "inet " | awk '{print $2}')
	IPSec_IPv6=$(ifconfig ipsec0 | grep "inet6" | awk '!/fe80/' | awk '{print $2}')
fi

# get external IP addresses by pinging external server
if ping -c 1 ipv4check.neilzone.co.uk &> /dev/null; then
	IPv4_external=$(curl -s ipv4check.neilzone.co.uk)
fi

if ping6 -c 1 ipv6check.neilzone.co.uk &> /dev/null; then
	IPv6_external=$(curl -s ipv6check.neilzone.co.uk)
fi


# get A&A quota remaining if a login has been specified and if CHAOS2 is reachable
if [ ! -z "$LOGIN" ]; then
	if ping -c 1 chaos2.aa.net.uk &> /dev/null; then
		AA_quota=$(echo "scale=2; $(curl -s --data "control_login=$LOGIN&control_password=$PASSWORD&service=$SERVICE" "https://chaos2.aa.net.uk/broadband/quota/xml" | grep -Eo 'quota-remaining.{0,14}' | awk '{print $2}' FS='"') / 1000^3" | bc)
	fi
fi

# function for adding IP address to clipboard

if [ "$1" = "copyIP" ]; then
  # Copy the IP to clipboard
  echo -n "$2" | pbcopy
fi

# Menubar title
echo "IP"
echo "---"

echo "Wi-Fi"

if [ $WiFi_status == "active" ]; then

	#check if IPv4 address exists

	if [ ! -z "$IPv4_internal" ]; then
		echo "$IPv4_internal | terminal=false bash='$0' param1=copyIP param2=$IPv4_internal"
	else
		echo "No IPv4 address | color=black"
	fi

	#check if IPv6 address exists

	if [ ! -z "$IPv6_internal" ]; then
		echo "$IPv6_internal | terminal=false bash='$0' param1=copyIP param2=$IPv6_internal"
	else
		echo "No IPv6 address | color=black"
	fi
	
else
	echo "Wi-Fi inactive | color=black"
fi	

# IPSec stuff

echo "---"
echo "IPSec"

if [ ! -z "$IPSec_status" ]; then

		if  [ ! -z "$IPSec_IPv4" ]; then
			echo "$IPSec_IPv4 | terminal=false bash='$0' param1=copyIP param2=$IPSec_IPv4"
		else
			echo "No IPv4 address | color=black"
		fi
		if  [ ! -z "$IPSec_IPv6" ]; then
			echo "$IPSec_IPv6 | terminal=false bash='$0' param1=copyIP param2=$IPSec_IPv6"
		else
			echo "No IPv4 address | color=black"
		fi	
else
	echo "IPSec inactive | color=black"
fi

echo "---"

echo "External"

#check if external IPv4 address exists

if [ ! -z "$IPv4_external" ]; then
	echo "$IPv4_external | terminal=false bash='$0' param1=copyIP param2=$IPv4_external"
else
	echo "No IPv4 address  | color=black"
fi

#check if external IPv6 address exists


if [ ! -z "$IPv6_external" ]; then
	echo "$IPv6_external | terminal=false bash='$0' param1=copyIP param2=$IPv6_external"
else
	echo "No IPv6 address  | color=black"
fi


if [ ! -z "$LOGIN" ]; then
	echo "---"
	echo "A&A quota"
	if [ ! -z "$AA_quota" ]; then
		echo ""$AA_quota" GB | href=https://control.aa.net.uk"
	else
		echo "Unable to get quota  | color=black"
	fi
fi


