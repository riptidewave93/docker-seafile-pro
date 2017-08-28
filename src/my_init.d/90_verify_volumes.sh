#!/bin/bash

# Used to verify our required volumes are mounted before we run

if [ "$CI_TEST" ]; then
	exit 0
fi

if [[ ! -d /shared/seafile ]]; then
	echo "Error, you do not have your Seafile volume mounted!"
	echo "Exiting to prevent any data loss."
	exit 1
fi
