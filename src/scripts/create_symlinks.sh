#!/bin/bash

set -e
set -o pipefail

dirs=(
	ccnet
  conf
	logs
	pro-data
  seafile-data
  seahub-data
)

for d in ${dirs[*]}; do
    src=/shared/seafile/$d
    if [[ -e $src ]]; then
        ln -sf $src /opt/seafile/
    fi
done

if [[ -e /shared/logs/seafile ]]; then
    ln -sf /shared/logs/seafile/ /opt/seafile/logs
fi

current_version_dir=/opt/seafile/seafile-pro-server-${SEAFILE_VERSION}
latest_version_dir=/opt/seafile/seafile-server-latest
seahub_data_dir=/shared/seafile/seahub-data

if [[ ! -e ${latest_version_dir} ]]; then
    ln -sf ${current_version_dir} ${latest_version_dir}
fi

source_avatars_dir=${current_version_dir}/seahub/media/avatars
rm -rf $source_avatars_dir
ln -sf ${seahub_data_dir}/avatars $source_avatars_dir

source_custom_dir=${current_version_dir}/seahub/media/custom
rm -rf $source_custom_dir
mkdir -p ${seahub_data_dir}/custom
ln -sf ${seahub_data_dir}/custom $source_custom_dir
