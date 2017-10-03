#!/bin/bash

echo "CI: Setting mock env vars"
export SEAFILE_ADMIN_EMAIL=test@test.com
export SEAFILE_ADMIN_PASSWORD=`dd if=/dev/urandom count=1 status=none | sha1sum | awk '{ print $1}'`

echo "CI: Starting up Seafile... please wait..."
nohup /scripts/bootstrap.sh >/dev/null 2>&1 &
sleep 60

verify_procs=(
	ccnet-server
	memcached
	mysqld
	nginx
	seafile-controller
	seaf-server
)
for procs in ${verify_procs[*]}; do
	echo "CI: Verifying Process $procs is running..."
	if [[ ! `ps aux | grep $procs | grep -v grep` ]]; then
		echo "CI: FAIL - $procs is not running."
		exit 1
	fi
done

echo "CI: Make sure cron script exists and is executable"
if [[ ! -e /etc/cron.daily/seafile-pro-gc ]]; then
	echo "CI: FAIL - Daily garbage collector cron script does not exist."
	exit 1
fi
if [[ ! -x /etc/cron.daily/seafile-pro-gc ]]; then
	echo "CI: FAIL - Daily garbage collector cron script is not executable."
	exit 1
fi

echo "CI: Make sure fingerprint file exists"
if [[ ! -e /shared/seafile/seafile-data/current_version ]]; then
	echo "CI: FAIL - Unable to find fingerprint file."
	exit 1
fi

echo "CI: Check HTTP response code"
resp=`curl -s -o /dev/null -w "%{http_code}" http://localhost/accounts/login/?next=/`
if [[ "$resp" != "200" ]]; then
	echo "CI: FAIL - HTTP call returned code of $resp."
	exit 1
fi

echo "CI: Check API for pong response"
if [[ `curl -s http://localhost/api2/ping/` != '"pong"' ]]; then
	echo "CI: FAIL - API ping/pong test failed."
	exit 1
fi

echo "CI: Test admin login via API"
resp=`curl -s -o /dev/null -w "%{http_code}" -d "username=$SEAFILE_ADMIN_EMAIL&password=$SEAFILE_ADMIN_PASSWORD" http://localhost/api2/auth-token/`
if [[ "$resp" != "200" ]]; then
	echo "CI: FAIL - Failed to auth via API. Response code of $resp."
	exit 1
fi

echo "CI: PASS - All tests completed without issue."
exit 0
