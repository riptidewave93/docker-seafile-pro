#!/bin/bash

sharedpath=/shared/seafile
stampfile=$sharedpath/seafile-data/current_version
seafilepath=/opt/seafile/seafile-server-latest

sfp_bootstrap() {
	export SERVER_NAME=seafile
	export SERVER_IP=$SEAFILE_DOMAIN
	export MYSQL_USER=seafile
	export MYSQL_USER_PASSWD=`dd if=/dev/urandom count=1 status=none | sha1sum | awk '{ print $1}'`
	export MYSQL_USER_HOST=127.0.0.1
	export MYSQL_ROOT_PASSWD=

	# Do our install
	/opt/seafile/seafile-pro-server-$SEAFILE_VERSION/setup-seafile-mysql.sh auto -n seafile
	if [[ $? != 0 ]]; then
		echo 'Error during the setup of Seafile Pro, exiting...'
		exit 1
	fi

	# Copy our configs to our volume for persistance
	move_dirs=(
		ccnet
		conf
		pro-data
		seafile-data
		seahub-data
	)
	for d in ${move_dirs[*]}; do
	    mv /opt/seafile/$d $sharedpath
	done

	# Make our log dir
	mkdir $sharedpath/logs

	# Apply patch to our ccnet config
	echo -e "[Client]\nUNIX_SOCKET = /opt/seafile/ccnet.sock\n" >> $sharedpath/conf/ccnet.conf
	echo -e "FILE_SERVER_ROOT = \"$URL_PROTO$SERVER_IP/seafhttp\"\n" >> $sharedpath/conf/seahub_settings.py

	# Add our admin user info for headless install
	echo "{\"email\":\"$SEAFILE_ADMIN_EMAIL\",\"password\":\"$SEAFILE_ADMIN_PASSWORD\"}" > $sharedpath/conf/admin.txt

	# Add our stamp file
	echo "$SEAFILE_VERSION" > $stampfile
}

sfp_upgrade() {
	OurSeafileVer=`cat $stampfile`
	Stripped_Our_Ver="${OurSeafileVer::-2}"
	Stripped_Latest_Ver="${SEAFILE_VERSION::-2}"
	UpgradeScripts=`ls $seafilepath/upgrade/ | grep 'upgrade_.*.sh'`

	# First, are we a minor upgrade? If so, do that and walk away
	if [[ "$Stripped_Our_Ver" == "$Stripped_Latest_Ver" ]]; then
		yes | $seafilepath/upgrade/minor-upgrade.sh
		if [[ $? != 0 ]]; then
			echo 'Error during Upgrade, exiting...'
			exit 1
		fi
		# Upgrade Stamp file
		echo "$SEAFILE_VERSION" > $stampfile
		return 0
	fi

	# We know where we are...
	StartIndex=0
	for script in $UpgradeScripts; do
		if [[ $script == "upgrade_$Stripped_Our_Ver"* ]]; then
			break
		fi
		let StartIndex++
	done

	# We know where we are going...
	EndIndex=0
	for script in $UpgradeScripts; do
		if [[ $script == *"_$Stripped_Latest_Ver.sh" ]]; then
			break
		fi
		let EndIndex++
	done

	# We have our start and end index, now we need to run all of the scripts inbetween
	ScriptArray=($UpgradeScripts)
	for i in `seq $StartIndex $EndIndex`; do
		yes | $seafilepath/upgrade/${ScriptArray[$i]}
		if [[ $? != 0 ]]; then
			echo "Error during upgrade while running ${ScriptArray[$i]}, exiting..."
			exit 1
		fi
	done
	# Upgrade Stamp file
	echo "$SEAFILE_VERSION" > $stampfile
}

######################
# Script starts here #
######################

# Are our required vars defined?
if [ -z ${SEAFILE_DOMAIN+x} ]; then
	export SEAFILE_DOMAIN=0.0.0.0
fi
if [ -z ${IS_HTTPS+x} ]; then
	export URL_PROTO=http://
else
	export URL_PROTO=https://
fi

# Wait for MySQL to come up before we do things
count=0
while [[ ! -S /var/run/mysqld/mysqld.sock ]]; do
	let count++
	sleep 1
	if [[ $count -eq 10 ]]; then
		echo "Error with starting MySQL, exiting..."
		exit 1
	fi
done

# Have we been bootstrapped before?
if [[ ! -e "$stampfile" ]]; then
	echo "Seafile has not been bootstrapped. Starting setup..."
	# Make sure these are set before bootstrap. Only needed on 1st run
	if [ -z ${SEAFILE_ADMIN_EMAIL+x} ]; then
		echo "Error, SEAFILE_ADMIN_EMAIL is not set! Exiting..."
		exit 1
	fi
	if [ -z ${SEAFILE_ADMIN_PASSWORD+x} ]; then
		echo "Error, SEAFILE_ADMIN_PASSWORD is not set! Exiting..."
		exit 1
	fi
	sfp_bootstrap
fi

# Adjust our Seafile config as needed/required
if ! grep -q "$URL_PROTO$SEAFILE_DOMAIN" $sharedpath/conf/ccnet.conf; then
	echo "Updating Seafile URL to $URL_PROTO$SEAFILE_DOMAIN"
	sed -i "s|SERVICE_URL =.*|SERVICE_URL = $URL_PROTO$SEAFILE_DOMAIN|g" $sharedpath/conf/ccnet.conf
	sed -i "s|FILE_SERVER_ROOT =.*|FILE_SERVER_ROOT = $URL_PROTO$SEAFILE_DOMAIN/seafhttp|g" $sharedpath/conf/ccnet.conf
fi

# Symlink to our data volume
/scripts/create_symlinks.sh

# Have we been updated?
if [[ $SEAFILE_VERSION != `cat $stampfile` ]]; then
	echo "Seafile requires updating! Starting update process..."
	sfp_upgrade
fi

# Configure and start our services
$seafilepath/seafile.sh start
$seafilepath/seahub.sh start

# Monitor to make sure we are running, exit as needed.
sleep 5
while true; do
	for procs in seafile-controller ccnet-server seaf-server; do
		if [[ ! `ps aux | grep $procs | grep -v grep` ]]; then
			echo "Error, $procs is no longer running! Exiting..."
			exit 1
		fi
	done
	sleep 60 # zzz
done
