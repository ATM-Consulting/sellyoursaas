#!/bin/bash
#
# To use this script with remote ssh (not required when using the remote agent):
# Create a symbolic link to this file .../create_deploy_undeploy.sh into /usr/bin
# Grant adequate permissions (550 mean root and group www-data can read and execute, nobody can write)
# sudo chown root:www-data /usr/bin/create_deploy_undeploy.sh
# sudo chmod 550 /usr/bin/create_deploy_undeploy.sh
# And allow apache to sudo on this script by doing visudo to add line:
#www-data        ALL=(ALL) NOPASSWD: /usr/bin/create_deploy_undeploy.sh
#
# deployall   create user and instance
# deploy      create only instance
# undeployall remove user and instance
# undeploy    remove only instance (must be easy to restore) - rest can be done later with clean.sh


export now=`date +%Y%m%d%H%M%S`

echo
echo
echo "####################################### ${0} ${1}"
echo "${0} ${@}"
echo "# user id --------> $(id -u)"
echo "# now ------------> $now"
echo "# PID ------------> ${$}"
echo "# PWD ------------> $PWD" 
echo "# arguments ------> ${@}"
echo "# path to me -----> ${0}"
echo "# parent path ----> ${0%/*}"
echo "# my name --------> ${0##*/}"
echo "# realname -------> $(realpath ${0})"
echo "# realname name --> $(basename $(realpath ${0}))"
echo "# realname dir ---> $(dirname $(realpath ${0}))"

export PID=${$}
export scriptdir=$(dirname $(realpath ${0}))
export vhostfile="$scriptdir/templates/vhostHttps-sellyoursaas.template"


if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

if [ "x$1" == "x" ]; then
	echo "Missing parameter 1 - mode (deploy|deployall|undeploy|undeployall)" 1>&2
	exit 1
fi
if [ "x$2" == "x" ]; then
	echo "Missing parameter 2 - osusername" 1>&2
	exit 1
fi
if [ "x$3" == "x" ]; then
	echo "Missing parameter 3 - ospassword" 1>&2
	exit 1
fi
if [ "x$4" == "x" ]; then
	echo "Missing parameter 4 - instancename" 1>&2
	exit 1
fi
if [ "x$5" == "x" ]; then
	echo "Missing parameter 5 - domainname" 1>&2
	exit 1
fi
if [ "x$6" == "x" ]; then
	echo "Missing parameter 6 - dbname" 1>&2
	exit 1
fi
if [ "x$7" == "x" ]; then
	echo "Missing parameter 7 - dbport" 1>&2
	exit 1
fi
if [ "x$8" == "x" ]; then
	echo "Missing parameter 8 - dbusername" 1>&2
	exit 1
fi
if [ "x$9" == "x" ]; then
	echo "Missing parameter 9 - dbpassword" 1>&2
	exit 1
fi
if [ "x${22}" == "x" ]; then
	echo "Missing parameter 22 - EMAILFROM" 1>&2
	exit 1
fi
if [ "x${23}" == "x" ]; then
	echo "Missing parameter 23 - REMOTEIP" 1>&2
	exit 1
fi


export mode=$1
export osusername=$2
export ospassword=$3
export instancename=$4
export domainname=$5

export dbname=$6
export dbport=$7
export dbusername=$8
export dbpassword=$9

export fileforconfig1=${10//£/ }
export targetfileforconfig1=${11//£/ }
export dirwithdumpfile=${12//£/ }
export dirwithsources1=${13}
export targetdirwithsources1=${14}
export dirwithsources2=${15}
export targetdirwithsources2=${16}
export dirwithsources3=${17}
export targetdirwithsources3=${18}
export cronfile=${19}
export cliafter=${20}
export targetdir=${21}
export EMAILTO=${22}
export REMOTEIP=${23}
export SELLYOURSAAS_ACCOUNT_URL=${24}
export instancenameold=${25}
export domainnameold=${26}
export customurl=${27}
if [ "x$customurl" == "x-" ]; then
	customurl=""
fi
export contractlineid=${28}
export EMAILFROM=${29}
export CERTIFFORCUSTOMDOMAIN=${30}
export archivedir=${31}
export SSLON=${32}
export apachereload=${33}
export ALLOWOVERRIDE=${34//£/ }
if [ "x$ALLOWOVERRIDE" == "x-" ]; then
	ALLOWOVERRIDE=""
fi
export VIRTUALHOSTHEAD=${35//£/ }
if [ "x$VIRTUALHOSTHEAD" == "x-" ]; then
	VIRTUALHOSTHEAD=""
fi
export ispaidinstance=${36}

export instancedir=$targetdir/$osusername/$dbname
export fqn=$instancename.$domainname
export fqnold=$instancenameold.$domainnameold
export CRONHEAD=${VIRTUALHOSTHEAD/php_value date.timezone /TZ=}

export webSSLCertificateCRT=with.sellyoursaas.com.crt
export webSSLCertificateKEY=with.sellyoursaas.com.key
export webSSLCertificateIntermediate=with.sellyoursaas.com-intermediate.crt


# For debug
echo `date +%Y%m%d%H%M%S`" input params for $0:"
echo "mode = $mode"
echo "osusername = $osusername"
echo "ospassword = XXXXXX"
echo "instancename = $instancename"
echo "domainname = $domainname"
echo "dbname = $dbname"
echo "dbport = $dbport"
echo "dbusername = $dbusername"
echo "dbpassword = $dbpassword"
echo "fileforconfig1 = $fileforconfig1"
echo "targetfileforconfig1 = $targetfileforconfig1"
echo "dirwithdumpfile = $dirwithdumpfile"
echo "dirwithsources1 = $dirwithsources1"
echo "targetdirwithsources1 = $targetdirwithsources1"
echo "dirwithsources2 = $dirwithsources2"
echo "targetdirwithsources2 = $targetdirwithsources2"
echo "dirwithsources3 = $dirwithsources3"
echo "targetdirwithsources3 = $targetdirwithsources3"
echo "cronfile = $cronfile"
echo "cliafter = $cliafter"
echo "targetdir = $targetdir"
echo "EMAILTO = $EMAILTO"
echo "REMOTEIP = $REMOTEIP"
echo "SELLYOURSAAS_ACCOUNT_URL = $SELLYOURSAAS_ACCOUNT_URL" 
echo "instancenameold = $instancenameold" 
echo "domainnameold = $domainnameold" 
echo "customurl = $customurl" 
echo "contractlineid = $contractlineid" 
echo "EMAILFROM = $EMAILFROM"
echo "CERTIFFORCUSTOMDOMAIN = $CERTIFFORCUSTOMDOMAIN"
echo "archivedir = $archivedir"
echo "SSLON = $SSLON"
echo "apachereload = $apachereload"
echo "ALLOWOVERRIDE = $ALLOWOVERRIDE"
echo "VIRTUALHOSTHEAD = $VIRTUALHOSTHEAD"
echo "ispaidinstance = $ispaidinstance"

echo `date +%Y%m%d%H%M%S`" calculated params:"
echo "vhostfile = $vhostfile"
echo "instancedir = $instancedir"
echo "fqn = $fqn"
echo "fqnold = $fqnold"
echo "CRONHEAD = $CRONHEAD"


MYSQL=`which mysql`
MYSQLDUMP=`which mysqldump`

echo "Search sellyoursaas database credential in /etc/sellyoursaas.conf"
passsellyoursaas=`grep 'databasepass=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
if [[ "x$passsellyoursaas" == "x" ]]; then
	echo Failed to get password for mysql user sellyoursaas 
	exit 1
fi 

if [[ ! -d $archivedir ]]; then
	echo Failed to find archive directory $archivedir
	echo "Failed to $mode instance $instancename.$domainname with: Failed to find archive directory $archivedir" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deploy/undeploy" $EMAILTO
	exit 1
fi

archivetestinstances=`grep 'archivetestinstances=' /etc/sellyoursaas.conf | cut -d '=' -f 2`

testorconfirm="confirm"



# Create user and directory

if [[ "$mode" == "deployall" ]]; then

	echo `date +%Y%m%d%H%M%S`" ***** Create user $osusername with home into /home/jail/home/$osusername"
	
	id -u $osusername
	notfound=$?
	echo notfound=$notfound
	
	if [[ $notfound == 0 ]]
	then
		echo "$osusername seems to already exists"
	else
		echo "perl -e'print crypt(\"'XXXXXX'\", "saltsalt")'"
		export passcrypted=`perl -e'print crypt("'$ospassword'", "saltsalt")'`
		echo "useradd -m -d /home/jail/home/$osusername -p 'YYYYYY' -s '/bin/secureBash' $osusername"
		useradd -m -d $targetdir/$osusername -p "$passcrypted" -s '/bin/secureBash' $osusername 
		if [[ "$?x" != "0x" ]]; then
			echo Error failed to create user $osusername 
			echo "Failed to deployall instance $instancename.$domainname with: useradd -m -d $targetdir/$osusername -p $ospassword -s '/bin/secureBash' $osusername" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deployment" $EMAILTO
			exit 1
		fi
		chmod -R go-rwx /home/jail/home/$osusername
	fi

	if [[ -d /home/jail/home/$osusername ]]
	then
		echo "/home/jail/home/$osusername exists. good."
	else
		mkdir /home/jail/home/$osusername
		chmod -R go-rwx /home/jail/home/$osusername
	fi
fi

if [[ "$mode" == "undeploy" || "$mode" == "undeployall" ]]; then

	echo rm -f /home/jail/home/$osusername/$dbname/*.log
	rm -f /home/jail/home/$osusername/$dbname/*.log >/dev/null 2>&1 
	echo rm -f /home/jail/home/$osusername/$dbname/*.log.*
	rm -f /home/jail/home/$osusername/$dbname/*.log.* >/dev/null 2>&1 

fi



# Create/Remove DNS entry

if [[ "$mode" == "deploy" || "$mode" == "deployall" ]]; then

	export ZONE="$domainname.hosts" 
	
	#$ttl 1d
	#$ORIGIN with.dolicloud.com.
	#@               IN     SOA   ns1with.dolicloud.com. admin.dolicloud.com. (
	#                2017051526       ; serial number
	#                600              ; refresh = 10 minutes
	#                300              ; update retry = 5 minutes
	#                604800           ; expiry = 3 weeks + 12 hours
	#                660              ; negative ttl
	#                )
	#                NS              ns1with.dolicloud.com.
	#                NS              ns2with.dolicloud.com.
	#                IN      TXT     "v=spf1 mx ~all".
	#
	#@               IN      A       79.137.96.15
	#
	#
	#$ORIGIN with.dolicloud.com.
	#
	#; other sub-domain records

	echo `date +%Y%m%d%H%M%S`" ***** Add DNS entry for $instancename in $domainname - Test with cat /etc/bind/${ZONE} | grep '^$instancename ' 2>&1"

	cat /etc/bind/${ZONE} | grep "^$instancename " 2>&1
	notfound=$?
	echo notfound=$notfound

	if [[ $notfound == 0 ]]; then
		echo "entry $instancename already found into host /etc/bind/${ZONE}"
	else
		echo "cat /etc/bind/${ZONE} | grep -v '^$instancename ' > /tmp/${ZONE}.$PID"
		cat /etc/bind/${ZONE} | grep -v "^$instancename " > /tmp/${ZONE}.$PID

		echo `date +%Y%m%d%H%M%S`" ***** Add $instancename A $REMOTEIP into tmp host file"
		echo $instancename A $REMOTEIP >> /tmp/${ZONE}.$PID  

		# we're looking line containing this comment
		export DATE=`date +%y%m%d%H`
		export NEEDLE="serial"
		curr=$(/bin/grep -e "${NEEDLE}$" /tmp/${ZONE}.$PID | /bin/sed -n "s/^\s*\([0-9]*\)\s*;\s*${NEEDLE}\s*/\1/p")
		# replace if current date is shorter (possibly using different format)
		echo "/bin/grep -e \"${NEEDLE}$\" /tmp/${ZONE}.$PID | /bin/sed -n \"s/^\s*\([0-9]*\)\s*;\s*${NEEDLE}\s*/\1/p\""
		echo "Current bind counter during $mode is $curr"
		if [ "x$curr" == "x" ]; then
			echo Error when editing the DNS file during a deployment. Failed to find bind counter in file /tmp/${ZONE}.$PID. Sending email to $EMAILTO
			echo "Failed to deployall instance $instancename.$domainname with: Error when editing the DNS file. Failed to find bind counter in file /tmp/${ZONE}.$PID" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deployment" $EMAILTO
			exit 1
		fi
		if [ ${#curr} -lt ${#DATE} ]; then
		  serial="${DATE}00"
		else
		  prefix=${curr::-2}
		  if [ "$DATE" -eq "$prefix" ]; then # same day
		    num=${curr: -2} # last two digits from serial number
		    num=$((10#$num + 1)) # force decimal representation, increment
		    serial="${DATE}$(printf '%02d' $num )" # format for 2 digits
		  else
		    serial="${DATE}00" # just update date
		  fi
		fi
		echo Replace serial in /tmp/${ZONE}.$PID with ${serial}
		/bin/sed -i -e "s/^\(\s*\)[0-9]\{0,\}\(\s*;\s*${NEEDLE}\)$/\1${serial}\2/" /tmp/${ZONE}.$PID
		
		echo Test temporary file with named-checkzone $domainname /tmp/${ZONE}.$PID
		named-checkzone $domainname /tmp/${ZONE}.$PID
		if [[ "$?x" != "0x" ]]; then
			echo Error when editing the DNS file during a deployment. File /tmp/${ZONE}.$PID is not valid. Sending email to $EMAILFROM
			echo "Failed to deployall instance $instancename.$domainname with: Error when editing the DNS file. File /tmp/${ZONE}.$PID is not valid" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deployment" $EMAILTO 
			exit 1
		fi
		
		echo `date +%Y%m%d%H%M%S`" **** Archive file with cp /etc/bind/${ZONE} /etc/bind/archives/${ZONE}-$now"
		cp /etc/bind/${ZONE} /etc/bind/archives/${ZONE}-$now
		
		echo `date +%Y%m%d%H%M%S`" **** Move new host file"
		mv -fu /tmp/${ZONE}.$PID /etc/bind/${ZONE}
		
		echo `date +%Y%m%d%H%M%S`" **** Reload dns with rndc reload $domainname"
		rndc reload $domainname
		#/etc/init.d/bind9 reload
		
		echo `date +%Y%m%d%H%M%S`" **** nslookup $fqn 127.0.0.1"
		nslookup $fqn 127.0.0.1
		if [[ "$?x" != "0x" ]]; then
			echo Error after reloading DNS. nslookup of $fqn fails on first try. We wait a little bit to make another try.
			sleep 3
			nslookup $fqn 127.0.0.1
			if [[ "$?x" != "0x" ]]; then
				echo Error after reloading DNS. nslookup of $fqn fails on second try too.
				echo "Failed to deployall instance $instancename.$domainname with: Error after reloading DNS. nslookup of $fqn fails of 2 tries." | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deployment" $EMAILTO 
				exit 1
			fi
		fi 
	fi
fi

if [[ "$mode" == "undeploy" || "$mode" == "undeployall" ]]; then

	export ZONE="$domainname.hosts" 

	echo `date +%Y%m%d%H%M%S`" ***** Remove DNS entry for $instancename in $domainname - Test with cat /etc/bind/${ZONE} | grep '^$instancename '"

	cat /etc/bind/${ZONE} | grep "^$instancename " 2>&1
	notfound=$?
	echo notfound=$notfound

	if [[ $notfound == 1 ]]; then
		echo `date +%Y%m%d%H%M%S`" entry $instancename already not found into host /etc/bind/${ZONE}"
	else
		echo "cat /etc/bind/${ZONE} | grep -v '^$instancename ' > /tmp/${ZONE}.$PID"
		cat /etc/bind/${ZONE} | grep -v "^$instancename " > /tmp/${ZONE}.$PID

		#echo `date +%Y%m%d%H%M%S`" ***** Add $instancename A $REMOTEIP into tmp host file"
		#echo $instancename A $REMOTEIP >> /tmp/${ZONE}.$PID  

		# we're looking line containing this comment
		export DATE=`date +%y%m%d%H`
		export NEEDLE="serial"
		curr=$(/bin/grep -e "${NEEDLE}$" /tmp/${ZONE}.$PID | /bin/sed -n "s/^\s*\([0-9]*\)\s*;\s*${NEEDLE}\s*/\1/p")
		# replace if current date is shorter (possibly using different format)
		echo "/bin/grep -e \"${NEEDLE}$\" /tmp/${ZONE}.$PID | /bin/sed -n \"s/^\s*\([0-9]*\)\s*;\s*${NEEDLE}\s*/\1/p\""
		echo "Current bind counter during $mode is $curr"
		if [ ${#curr} -lt ${#DATE} ]; then
		  serial="${DATE}00"
		else
		  prefix=${curr::-2}
		  if [ "$DATE" -eq "$prefix" ]; then # same day
		    num=${curr: -2} # last two digits from serial number
		    num=$((10#$num + 1)) # force decimal representation, increment
		    serial="${DATE}$(printf '%02d' $num )" # format for 2 digits
		  else
		    serial="${DATE}00" # just update date
		  fi
		fi
		echo Replace serial in /tmp/${ZONE}.$PID with ${serial}
		/bin/sed -i -e "s/^\(\s*\)[0-9]\{0,\}\(\s*;\s*${NEEDLE}\)$/\1${serial}\2/" /tmp/${ZONE}.$PID
		
		echo `date +%Y%m%d%H%M%S`" Test temporary file /tmp/${ZONE}.$PID"
		
		named-checkzone $domainname /tmp/${ZONE}.$PID
		if [[ "$?x" != "0x" ]]; then
			echo Error when editing the DNS file un undeployment. File /tmp/${ZONE}.$PID is not valid 
			echo "Failed to deployall instance $instancename.$domainname with: Error when editing the DNS file. File /tmp/${ZONE}.$PID is not valid" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deployment" $EMAILTO
			exit 1
		fi
		
		echo `date +%Y%m%d%H%M%S`" **** Archive file with cp /etc/bind/${ZONE} /etc/bind/archives/${ZONE}-$now"
		cp /etc/bind/${ZONE} /etc/bind/archives/${ZONE}-$now
		
		echo `date +%Y%m%d%H%M%S`" **** Move new host file with mv -fu /tmp/${ZONE}.$PID /etc/bind/${ZONE}"
		mv -fu /tmp/${ZONE}.$PID /etc/bind/${ZONE}
		
		echo `date +%Y%m%d%H%M%S`" **** Reload dns with rndc reload $domainname"
		rndc reload $domainname
		#/etc/init.d/bind9 reload
		
		#echo `date +%Y%m%d%H%M%S`" **** nslookup $fqn 127.0.0.1"
		#nslookup $fqn 127.0.0.1
		#if [[ "$?x" != "0x" ]]; then
		#	echo Error after reloading DNS. nslookup of $fqn fails. 
		#	echo "Failed to deployall instance $instancename.$domainname with: Error after reloading DNS. nslookup of $fqn fails. " | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deployment" $EMAILTO
		#	exit 1
		#fi 
	fi

fi



# Deploy files

if [[ "$mode" == "deploy" || "$mode" == "deployall" ]]; then

	echo `date +%Y%m%d%H%M%S`" ***** Deploy files"
	
	echo "Create dir for instance = /home/jail/home/$osusername/$dbname"
	mkdir -p /home/jail/home/$osusername/$dbname
	
	echo "Check dirwithsources1=$dirwithsources1 targetdirwithsources1=$targetdirwithsources1"
	if [ -d $dirwithsources1 ]; then
		if [[ "x$targetdirwithsources1" != "x" ]]; then
			mkdir -p $targetdirwithsources1
			if [ -f $dirwithsources1.tgz ]; then
				echo "tar -xzf $dirwithsources1.tgz --directory $targetdirwithsources1/"
				tar -xzf $dirwithsources1.tgz --directory $targetdirwithsources1/
			else
				echo "cp -pr  $dirwithsources1/ $targetdirwithsources1"
				cp -pr  $dirwithsources1/. $targetdirwithsources1
			fi
		fi
	fi
	echo "Check dirwithsources2=$dirwithsources2 targetdirwithsources2=$targetdirwithsources2"
	if [ -d $dirwithsources2 ]; then
		if [[ "x$targetdirwithsources2" != "x" ]]; then
			mkdir -p $targetdirwithsources2
			if [ -f $dirwithsources2.tgz ]; then
				echo "tar -xzf $dirwithsources2.tgz --directory $targetdirwithsources2/"
				tar -xzf $dirwithsources2.tgz --directory $targetdirwithsources2/
			else
				echo "cp -pr  $dirwithsources2/ $targetdirwithsources2"
				cp -pr  $dirwithsources2/. $targetdirwithsources2
			fi
		fi
	fi
	echo "Check dirwithsources3=$dirwithsources3 targetdirwithsources3=$targetdirwithsources3"
	if [ -d $dirwithsources3 ]; then
		if [[ "x$targetdirwithsources3" != "x" ]]; then
			mkdir -p $targetdirwithsources3
			if [ -f $dirwithsources3.tgz ]; then
				echo "tar -xzf $dirwithsources3.tgz --directory $targetdirwithsources3/"
				tar -xzf $dirwithsources3.tgz --directory $targetdirwithsources3/
			else
				echo "cp -pr  $dirwithsources3/ $targetdirwithsources3"
				cp -pr  $dirwithsources3/. $targetdirwithsources3
			fi
		fi
	fi

	echo "Force permissions and owner on /home/jail/home/$osusername/$dbname"
	chown -R $osusername.$osusername /home/jail/home/$osusername/$dbname
	chmod -R go-rwx /home/jail/home/$osusername/$dbname
fi


# Undeploy config file

if [[ "$mode" == "undeploy" || "$mode" == "undeployall" ]]; then

	echo `date +%Y%m%d%H%M%S`" ***** Undeploy config file $targetfileforconfig1"

	if [[ -s $targetfileforconfig1 ]]; then
		echo rm -f $targetfileforconfig1.undeployed 2>/dev/null
		echo mv $targetfileforconfig1 $targetfileforconfig1.undeployed
		if [[ $testorconfirm == "confirm" ]]
		then
			rm -f $targetfileforconfig1.undeployed 2>/dev/null
			mv $targetfileforconfig1 $targetfileforconfig1.undeployed
		fi
	else
		echo File $targetfileforconfig1 was already removed/archived
	fi		
fi


# Undeploy/Archive files

if [[ "$mode" == "undeploy" || "$mode" == "undeployall" ]]; then

	echo `date +%Y%m%d%H%M%S`" ***** Undeploy files that are into $targetdir/$osusername/$dbname ispaidinstance = $ispaidinstance archivedir = $archivedir"
			
	# If the dir where instance was deployed still exists, we move it manually
	if [ -d $targetdir/$osusername/$dbname ]; then
		echo The dir $targetdir/$osusername/$dbname still exists, we archive it
		if [ -d $archivedir/$osusername/$dbname ]; then				# Should not happen
			echo The dir $archivedir/$osusername/$dbname already exists, so we overwrite files into existing archive
			echo cp -pr $targetdir/$osusername/$dbname $archivedir/$osusername
			cp -pr $targetdir/$osusername/$dbname $archivedir/$osusername
			if [[ $testorconfirm == "confirm" ]]
			then
				rm -fr $targetdir/$osusername/$dbname
			fi
		else														# This is the common case of archiving after an undeploy
			#echo mv -f $targetdir/$osusername/$dbname $archivedir/$osusername/$dbname
			echo `date +%Y%m%d%H%M%S`
			if [[ $testorconfirm == "confirm" ]]
			then
				mkdir $archivedir/$osusername
				mkdir $archivedir/$osusername/$dbname
				if [[ "x$ispaidinstance" == "x1" ]]; then
					echo tar cz --exclude-vcs -f $archivedir/$osusername/$dbname/$osusername.tar.gz $targetdir/$osusername/$dbname
					tar cz --exclude-vcs -f $archivedir/$osusername/$dbname/$osusername.tar.gz $targetdir/$osusername/$dbname
					echo `date +%Y%m%d%H%M%S`
					echo rm -fr $targetdir/$osusername/$dbname
					rm -fr $targetdir/$osusername/$dbname
					echo `date +%Y%m%d%H%M%S`
					echo chown -R root $archivedir/$osusername/$dbname
					chown -R root $archivedir/$osusername/$dbname
				else
					if [[ "x$archivetestinstances" == "x0" ]]; then
						echo "Archive of test instances are disabled. We discard the tar cz --exclude-vcs -f $archivedir/$osusername/$dbname/$osusername.tar.gz $targetdir/$osusername/$dbname"
					else
						echo tar cz --exclude-vcs -f $archivedir/$osusername/$dbname/$osusername.tar.gz $targetdir/$osusername/$dbname
						tar cz --exclude-vcs -f $archivedir/$osusername/$dbname/$osusername.tar.gz $targetdir/$osusername/$dbname
					fi
					echo `date +%Y%m%d%H%M%S`
					echo rm -fr $targetdir/$osusername/$dbname
					rm -fr $targetdir/$osusername/$dbname
					echo `date +%Y%m%d%H%M%S`
					echo chown -R root $archivedir/$osusername/$dbname
					chown -R root $archivedir/$osusername/$dbname
				fi
			fi
		fi
	else
		echo The dir $targetdir/$osusername/$dbname seems already removed/archived
	fi

	# Note, we archive the dir for instance but the dir for user and the user is still here. Will be removed by clean.sh or at end if mode = undeployall
fi


# Deploy config file

if [[ "$mode" == "deploy" || "$mode" == "deployall" ]]; then
	
	echo `date +%Y%m%d%H%M%S`" ***** Deploy config file"
	
	if [[ $targetfileforconfig1 == "-" ]]
	then
		echo No config file to deploy for this service
	else
		mkdir -p `dirname $targetfileforconfig1`
		
		if [[ -s $targetfileforconfig1 ]]; then
			cat $targetfileforconfig1 | grep "$dbname" 2>&1
			notfound=$?
			echo notfound=$notfound
			if [[ $notfound == 1 ]]; then
				echo File $targetfileforconfig1 already exists but content does not include database param. We recreate file.
				echo "rm $targetfileforconfig1"
				if [[ $testorconfirm == "confirm" ]]
				then
					rm -f $targetfileforconfig1
				fi
				echo "cp $fileforconfig1 $targetfileforconfig1"
				if [[ $testorconfirm == "confirm" ]]
				then
					cp $fileforconfig1 $targetfileforconfig1
				fi
			else
				echo File $targetfileforconfig1 already exists and content includes database parameters. We change nothing.
			fi
		else
			echo "cp $fileforconfig1 $targetfileforconfig1"
			if [[ $testorconfirm == "confirm" ]]
			then
				cp $fileforconfig1 $targetfileforconfig1
			fi
		fi
		chown -R $osusername.$osusername $targetfileforconfig1
		chmod -R go-rwx $targetfileforconfig1
		chmod -R g-s $targetfileforconfig1
		chmod -R a-wx $targetfileforconfig1
	fi
fi



# Create/Disable Apache virtual host

if [[ "$mode" == "deploy" || "$mode" == "deployall" ]]; then

	export apacheconf="/etc/apache2/sellyoursaas-available/$fqn.conf"
	echo `date +%Y%m%d%H%M%S`" ***** Create apache conf $apacheconf from $vhostfile"
	if [[ -s $apacheconf ]]
	then
		echo "Apache conf $apacheconf already exists, we delete it since it may be a file from an old instance with same name"
		rm -f $apacheconf
	fi

	echo "cat $vhostfile | sed -e 's/__webAppDomain__/$instancename.$domainname/g' | \
			  sed -e 's/__webAppAliases__/$instancename.$domainname/g' | \
			  sed -e 's/__webAppLogName__/$instancename/g' | \
              sed -e 's/__webSSLCertificateCRT__/$webSSLCertificateCRT/g' | \
              sed -e 's/__webSSLCertificateKEY__/$webSSLCertificateKEY/g' | \
              sed -e 's/__webSSLCertificateIntermediate__/$webSSLCertificateIntermediate/g' | \
			  sed -e 's/__webAdminEmail__/$EMAILFROM/g' | \
			  sed -e 's/__osUsername__/$osusername/g' | \
			  sed -e 's/__osGroupname__/$osusername/g' | \
			  sed -e 's;__osUserPath__;/home/jail/home/$osusername/$dbname;g' | \
			  sed -e 's;__VirtualHostHead__;$VIRTUALHOSTHEAD;g' | \
			  sed -e 's;__AllowOverride__;$ALLOWOVERRIDE;g' | \
			  sed -e 's;__webMyAccount__;$SELLYOURSAAS_ACCOUNT_URL;g' | \
			  sed -e 's;__webAppPath__;$instancedir;g' > $apacheconf"
	cat $vhostfile | sed -e "s/__webAppDomain__/$instancename.$domainname/g" | \
			  sed -e "s/__webAppAliases__/$instancename.$domainname/g" | \
			  sed -e "s/__webAppLogName__/$instancename/g" | \
              sed -e "s/__webSSLCertificateCRT__/$webSSLCertificateCRT/g" | \
              sed -e "s/__webSSLCertificateKEY__/$webSSLCertificateKEY/g" | \
              sed -e "s/__webSSLCertificateIntermediate__/$webSSLCertificateIntermediate/g" | \
			  sed -e "s/__webAdminEmail__/$EMAILFROM/g" | \
			  sed -e "s/__osUsername__/$osusername/g" | \
			  sed -e "s/__osGroupname__/$osusername/g" | \
			  sed -e "s;__osUserPath__;/home/jail/home/$osusername/$dbname;g" | \
			  sed -e "s;__VirtualHostHead__;$VIRTUALHOSTHEAD;g" | \
			  sed -e "s;__AllowOverride__;$ALLOWOVERRIDE;g" | \
			  sed -e "s;__webMyAccount__;$SELLYOURSAAS_ACCOUNT_URL;g" | \
			  sed -e "s;__webAppPath__;$instancedir;g" > $apacheconf


	#echo Enable conf with a2ensite $fqn.conf
	#a2ensite $fqn.conf
	echo Enable conf with ln -fs /etc/apache2/sellyoursaas-available/$fqn.conf /etc/apache2/sellyoursaas-online 
	ln -fs /etc/apache2/sellyoursaas-available/$fqn.conf /etc/apache2/sellyoursaas-online
	
	# Remove and recreate customurl
	rm -f /etc/apache2/sellyoursaas-available/$fqn.custom.conf
	rm -f /etc/apache2/sellyoursaas-online/$fqn.custom.conf
	if [[ "x$customurl" != "x" ]]; then
	
		export apacheconf="/etc/apache2/sellyoursaas-available/$fqn.custom.conf"
		echo `date +%Y%m%d%H%M%S`" ***** Create apache conf $apacheconf from $vhostfile"
		if [[ -s $apacheconf ]]
		then
			echo "Apache conf $apacheconf already exists, we delete it since it may be a file from an old instance with same name"
			rm -f $apacheconf
		fi

		echo "cat $vhostfile | sed -e 's/__webAppDomain__/$customurl/g' | \
				  sed -e 's/__webAppAliases__/$customurl/g' | \
				  sed -e 's/__webAppLogName__/$instancename/g' | \
                  sed -e 's/__webSSLCertificateCRT__/$webSSLCertificateCRT/g' | \
                  sed -e 's/__webSSLCertificateKEY__/$webSSLCertificateKEY/g' | \
                  sed -e 's/__webSSLCertificateIntermediate__/$webSSLCertificateIntermediate/g' | \
				  sed -e 's/__webAdminEmail__/$EMAILFROM/g' | \
				  sed -e 's/__osUsername__/$osusername/g' | \
				  sed -e 's/__osGroupname__/$osusername/g' | \
				  sed -e 's;__osUserPath__;/home/jail/home/$osusername/$dbname;g' | \
				  sed -e 's;__VirtualHostHead__;$VIRTUALHOSTHEAD;g' | \
				  sed -e 's;__AllowOverride__;$ALLOWOVERRIDE;g' | \
				  sed -e 's;__webMyAccount__;$SELLYOURSAAS_ACCOUNT_URL;g' | \
				  sed -e 's;__webAppPath__;$instancedir;g' | sed -e 's/with\.sellyoursaas\.com/$CERTIFFORCUSTOMDOMAIN/g' > $apacheconf"
		cat $vhostfile | sed -e "s/__webAppDomain__/$customurl/g" | \
				  sed -e "s/__webAppAliases__/$customurl/g" | \
				  sed -e "s/__webAppLogName__/$instancename/g" | \
                  sed -e "s/__webSSLCertificateCRT__/$webSSLCertificateCRT/g" | \
                  sed -e "s/__webSSLCertificateKEY__/$webSSLCertificateKEY/g" | \
                  sed -e "s/__webSSLCertificateIntermediate__/$webSSLCertificateIntermediate/g" | \
				  sed -e "s/__webAdminEmail__/$EMAILFROM/g" | \
				  sed -e "s/__osUsername__/$osusername/g" | \
				  sed -e "s/__osGroupname__/$osusername/g" | \
				  sed -e "s;__osUserPath__;/home/jail/home/$osusername/$dbname;g" | \
				  sed -e "s;__VirtualHostHead__;$VIRTUALHOSTHEAD;g" | \
				  sed -e "s;__AllowOverride__;$ALLOWOVERRIDE;g" | \
				  sed -e "s;__webMyAccount__;$SELLYOURSAAS_ACCOUNT_URL;g" | \
				  sed -e "s;__webAppPath__;$instancedir;g" | sed -e "s/with\.sellyoursaas\.com/$CERTIFFORCUSTOMDOMAIN/g" > $apacheconf


		echo Enable conf with ln -fs /etc/apache2/sellyoursaas-available/$fqn.custom.conf /etc/apache2/sellyoursaas-online 
		ln -fs /etc/apache2/sellyoursaas-available/$fqn.custom.conf /etc/apache2/sellyoursaas-online
	fi	
	
	
	echo /usr/sbin/apache2ctl configtest
	/usr/sbin/apache2ctl configtest
	if [[ "x$?" != "x0" ]]; then
		echo Error when running apache2ctl configtest. We remove the new created virtual host /etc/apache2/sellyoursaas-online/$fqn.conf to hope to restore configtest ok.
		rm -f /etc/apache2/sellyoursaas-online/$fqn.conf
		rm -f /etc/apache2/sellyoursaas-online/$fqn.custom.conf
		echo "Failed to deployall instance $instancename.$domainname with: Error when running apache2ctl configtest" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deployment" $EMAILTO
		exit 1
	fi
	
	if [[ "x$apachereload" != "xnoapachereload" ]]; then
		echo `date +%Y%m%d%H%M%S`" ***** Apache tasks finished. service apache2 reload."
		service apache2 reload
		if [[ "x$?" != "x0" ]]; then
			echo Error when running service apache2 reload 
			echo "Failed to deployall instance $instancename.$domainname with: Error when running service apache2 reload" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deployment" $EMAILTO
			exit 2
		fi
	else
		echo `date +%Y%m%d%H%M%S`" ***** Apache tasks finished. But we do not reload apache2 now to reduce reloading."
	fi

fi

if [[ "$mode" == "undeploy" || "$mode" == "undeployall" ]]; then

	export apacheconf="/etc/apache2/sellyoursaas-online/$fqn.conf"
	echo `date +%Y%m%d%H%M%S`" ***** Remove apache conf $apacheconf"

	if [ -f $apacheconf ]; then
	
		echo Disable conf with a2dissite $fqn.conf
		#a2dissite $fqn.conf
		rm /etc/apache2/sellyoursaas-online/$fqn.conf

		echo Disable conf with a2dissite $fqn.custom.conf
		#a2dissite $fqn.conf
		rm /etc/apache2/sellyoursaas-online/$fqn.custom.conf
		
		/usr/sbin/apache2ctl configtest
		if [[ "x$?" != "x0" ]]; then
			echo Error when running apache2ctl configtest 
			echo "Failed to undeploy or undeployall instance $instancename.$domainname with: Error when running apache2ctl configtest" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in undeployment" $EMAILTO
			exit 1
		fi 
		
		if [[ "x$apachereload" != "xnoapachereload" ]]; then
			echo `date +%Y%m%d%H%M%S`" ***** Apache tasks finished. service apache2 reload."
			service apache2 reload
			if [[ "x$?" != "x0" ]]; then
				echo Error when running service apache2 reload 
				echo "Failed to undeploy or undeployall instance $instancename.$domainname with: Error when running service apache2 reload" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in undeployment" $EMAILTO
				exit 2
			fi
		else
			echo `date +%Y%m%d%H%M%S`" ***** Apache tasks finished. But we do not reload apache2 now to reduce reloading."
		fi
	else
		echo "Virtual host $apacheconf seems already disabled"
	fi
fi



# Install/Uninstall cron

if [[ "$mode" == "deploy" || "$mode" == "deployall" ]]; then

	echo `date +%Y%m%d%H%M%S`" ***** Install cron file $cronfile"
	
	if [[ -s $cronfile ]]
	then
		if [[ -f /var/spool/cron/crontabs/$osusername ]]; then
			echo merge existing $cronfile with existing /var/spool/cron/crontabs/$osusername
			echo "cat /var/spool/cron/crontabs/$osusername | grep -v $dbname > /tmp/$dbname.tmp"
			cat /var/spool/cron/crontabs/$osusername | grep -v $dbname > /tmp/$dbname.tmp
			echo "cat $cronfile >> /tmp/$dbname.tmp"
			cat $cronfile >> /tmp/$dbname.tmp
			echo cp /tmp/$dbname.tmp /var/spool/cron/crontabs/$osusername
			cp /tmp/$dbname.tmp /var/spool/cron/crontabs/$osusername
		else
			echo cron file /var/spool/cron/crontabs/$osusername does not exists yet
			echo cp $cronfile /var/spool/cron/crontabs/$osusername
			cp $cronfile /var/spool/cron/crontabs/$osusername
		fi
	
		chown $osusername.$osusername /var/spool/cron/crontabs/$osusername
		chmod 600 /var/spool/cron/crontabs/$osusername
	else
		echo There is no cron file to install
	fi
fi

if [[ "$mode" == "undeploy" || "$mode" == "undeployall" ]]; then

	echo `date +%Y%m%d%H%M%S`" ***** Remove cron file /var/spool/cron/crontabs/$osusername"
	if [ -s /var/spool/cron/crontabs/$osusername ]; then
		mkdir -p /var/spool/cron/crontabs.disabled
		rm -f /var/spool/cron/crontabs.disabled/$osusername
		echo cp /var/spool/cron/crontabs/$osusername /var/spool/cron/crontabs.disabled/$osusername
		cp /var/spool/cron/crontabs/$osusername /var/spool/cron/crontabs.disabled/$osusername

		#cat /var/spool/cron/crontabs/$osusername | grep -v $dbname > /tmp/$dbname.tmp
		#echo cp /tmp/$dbname.tmp /var/spool/cron/crontabs/$osusername
		#cp /tmp/$dbname.tmp /var/spool/cron/crontabs/$osusername
		echo rm -f /var/spool/cron/crontabs/$osusername
		rm -f /var/spool/cron/crontabs/$osusername
	else
		echo cron file /var/spool/cron/crontabs/$osusername already removed or empty
	fi 
fi
if [[ "$mode" == "undeployall" ]]; then

	echo rm -f /var/spool/cron/crontabs.disabled/$osusername
	rm -f /var/spool/cron/crontabs.disabled/$osusername 

fi


# Create database (last step, the longer one)

if [[ "$mode" == "deploy" || "$mode" == "deployall" ]]; then

	echo `date +%Y%m%d%H%M%S`" ***** Create database $dbname for user $dbusername"
	
	Q1="CREATE DATABASE IF NOT EXISTS $dbname; "
	#Q2="CREATE USER IF NOT EXISTS '$dbusername'@'localhost' IDENTIFIED BY '$dbpassword'; "
	Q2="CREATE USER '$dbusername'@'localhost' IDENTIFIED BY '$dbpassword'; "
	SQL="${Q1}${Q2}"
	echo "$MYSQL -A -usellyoursaas -pXXXXXX -e \"$SQL\""
	$MYSQL -A -usellyoursaas -p$passsellyoursaas -e "$SQL"
	
	Q1="CREATE DATABASE IF NOT EXISTS $dbname; "
	#Q2="CREATE USER IF NOT EXISTS '$dbusername'@'%' IDENTIFIED BY '$dbpassword'; "
	Q2="CREATE USER '$dbusername'@'%' IDENTIFIED BY '$dbpassword'; "
	SQL="${Q1}${Q2}"
	echo "$MYSQL -A -usellyoursaas -pXXXXXX -e \"$SQL\""
	$MYSQL -A -usellyoursaas -p$passsellyoursaas -e "$SQL"
	
	Q1="GRANT CREATE,CREATE TEMPORARY TABLES,CREATE VIEW,DROP,DELETE,INSERT,SELECT,UPDATE,ALTER,INDEX,LOCK TABLES,REFERENCES,SHOW VIEW ON $dbname.* TO '$dbusername'@'localhost'; "
	Q2="GRANT CREATE,CREATE TEMPORARY TABLES,CREATE VIEW,DROP,DELETE,INSERT,SELECT,UPDATE,ALTER,INDEX,LOCK TABLES,REFERENCES,SHOW VIEW ON $dbname.* TO '$dbusername'@'%'; "
	Q3="UPDATE mysql.user SET Password=PASSWORD('$dbpassword') WHERE User='$dbusername'; "
	# If we use mysql and not mariadb, we set password differently
	dpkg -l | grep mariadb > /dev/null
	if [ $? == "1" ]; then
		# For mysql
		Q3="SET PASSWORD FOR '$dbusername' = PASSWORD('$dbpassword'); "
	fi
	Q4="FLUSH PRIVILEGES; "
	SQL="${Q1}${Q2}${Q3}${Q4}"
	echo "$MYSQL -A -usellyoursaas -e \"$SQL\""
	$MYSQL -A -usellyoursaas -p$passsellyoursaas -e "$SQL"

	echo "You can test with mysql $dbname -h $REMOTEIP -u $dbusername -p$dbpassword"

	# Load dump file
	echo Search dumpfile into $dirwithdumpfile
	for dumpfile in `ls $dirwithdumpfile/*.sql 2>/dev/null`
	do
		echo "$MYSQL -A -usellyoursaas -p$passsellyoursaas -D $dbname < $dumpfile"
		$MYSQL -A -usellyoursaas -p$passsellyoursaas -D $dbname < $dumpfile
		result=$?
		if [[ "x$result" != "x0" ]]; then
			echo Failed to load dump file $dumpfile
			echo "Failed to $mode instance $instancename.$domainname with: Failed to load dump file $dumpfile" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in deploy/undeploy" $EMAILTO
			exit 1
		fi
	done

fi


# Drop database

if [[ "$mode" == "undeploy" || "$mode" == "undeployall" ]]; then

	echo `date +%Y%m%d%H%M%S`" ***** Archive and dump database $dbname in $archivedir/$osusername"

	echo "Do a dump of database $dbname - may fails if already removed"
	mkdir -p $archivedir/$osusername
	echo "$MYSQLDUMP -usellyoursaas -p$passsellyoursaas $dbname | gzip > $archivedir/$osusername/dump.$dbname.$now.sql.gz"
	$MYSQLDUMP -usellyoursaas -p$passsellyoursaas $dbname | gzip > $archivedir/$osusername/dump.$dbname.$now.sql.gz

	if [[ "x$?" == "x0" ]]; then
		echo "Now drop the database"
		echo "echo 'DROP DATABASE $dbname;' | $MYSQL -usellyoursaas -p$passsellyoursaas $dbname"
		if [[ $testorconfirm == "confirm" ]]; then
			echo "DROP DATABASE $dbname;" | $MYSQL -usellyoursaas -p$passsellyoursaas $dbname
		fi
	else
		echo "ERROR in dumping database, so we don't try to drop it"	
	fi
fi


# Delete os directory and user + group

if [[ "$mode" == "undeployall" ]]; then
	
	echo `date +%Y%m%d%H%M%S`" ***** Delete user $osusername with home into /home/jail/home/$osusername and archive it into $archivedir"

	echo crontab -r -u $osusername
	crontab -r -u $osusername
	
	# Note: When we do this the home dir of $osusername was already archived by code few lines previously
	echo deluser --remove-home --backup --backup-to $archivedir/$osusername $osusername
	if [[ $testorconfirm == "confirm" ]]
	then
		deluser --remove-home --backup --backup-to $archivedir/$osusername $osusername
		chmod -R ug+r $archivedir/$osusername/*.bz2
	fi
	
	echo deluser --group $osusername
	if [[ $testorconfirm == "confirm" ]]
	then
		deluser --group $osusername
	fi

fi


# Execute after CLI

if [[ "$mode" == "deploy" || "$mode" == "deployall" ]]; then
	if [[ "x$cliafter" != "x" ]]; then
		if [ -f $cliafter ]; then
			echo ". $cliafter"
			. $cliafter
			if [[ "x$?" != "x0" ]]; then
				echo Error when running the CLI script $cliafter 
				echo "Error when running the CLI script $cliafter" | mail -aFrom:$EMAILFROM -s "[Alert] Pb in undeployment" $EMAILTO
				exit 1
			fi
		fi
	fi
fi


if [[ "$mode" == "undeploy" || "$mode" == "undeployall" ]]; then
	
	echo "$mode $instancename.$domainname" >> $archivedir/$osusername/$mode-$instancename.$domainname.txt

fi


#if ! grep test_$i /etc/hosts >/dev/null; then
#	echo Add name test_$i into /etc/hosts
#	echo 127.0.0.1 test_$i >> /etc/hosts
#fi

echo `date +%Y%m%d%H%M%S`" Process of action $mode of $instancename.$domainname for user $osusername finished with no error"
echo

exit 0
