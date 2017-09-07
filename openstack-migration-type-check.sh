#!/bin/bash

if [ $# -lt 1 ]
then
	echo "Usage: $0 HYPERVISOR_NAME"
	exit 1
fi


OPENSTACK_PROJECT_RC=$(find ${HOME} -path ${HOME}/SSI\ Network\ Root -prune -o -type f -name admin-openrc.sh -print)
#OPENSTACK_PROJECT_RC=$(find ${HOME} -name admin-openrc.sh 2> /dev/null)

if [ -n ${OPENSTACK_PROJECT_RC} ]
then
	echo "Found admin-openrc.sh in users home"
	echo "source ${OPENSTACK_PROJECT_RC}"
	source "${OPENSTACK_PROJECT_RC}"
	#read OPENSTACK_PROJECT_RC
	#source "${OPENSTACK_PROJECT_RC}"
else
	echo "Could not find admin-openrc.sh in ${HOME}"
	echo "Please set admin-openrc.sh OPENSTACK_PROJECT_RC: /path/to/project/project_rc_file"
	read OPENSTACK_PROJECT_RC
	source "${OPENSTACK_PROJECT_RC}"
fi


HYPERVISOR_NAME=$1

IFS=$'\n'
# Get list of Instances
# INSTANCE_ARRAY=($(openstack server list --long --all-projects -c "ID" -c "Name" -c "Host" -c "Status" -c "Power State" -c "Networks" | grep "${HYPERVISOR_NAME}"))


#VOLUME_ID_ARRAY=($(openstack volume list --all | grep ${INSTANCE_ID} | awk -F'|' '{print $2,$6}' | awk '{print $1,$6}'))

migration_type_check()
{

for INSTANCE_ID in $(openstack server list --long --all-projects -c "ID" -c "Name" -c "Host" -c "Status" -c "Power State" -c "Networks" | grep "${HYPERVISOR_NAME}" | awk '{print $2}')
do
	#VOLUME_ID_ARRAY=(GOOGLE	EYES)
	#echo ${#VOLUME_ID_ARRAY[@]}
	VOLUME_ID_ARRAY=($(openstack volume list --all | grep ${INSTANCE_ID} | awk -F'|' '{print $2,$6}' | awk '{print $1,$6}'))
	#echo "${#VOLUME_ID_ARRAY[@]}"
	INSTANCE_NAME=$(openstack server show ${INSTANCE_ID} | grep -w "name " | awk '{print $4}')
	INSTANCE_PROJECT=$(openstack server show ${INSTANCE_ID} | grep -w "addresses " | awk '{print $4}' | awk -F'=' '{print $1}')
# Is this instance able to be migrated, what type of migration?
	if [ ${#VOLUME_ID_ARRAY[@]} -gt 0 ]
	then
		LOOP_COUNT=${#VOLUME_ID_ARRAY[@]}
		while [ ${LOOP_COUNT} -gt 0 ]
		do
			for VOLUME_ID in ${VOLUME_ID_ARRAY[@]} ; do
				#echo ${VOLUME_ID}
				if [[ $(echo ${VOLUME_ID} | awk '{print $2}') == "/dev/vda" ]]
				then
					#echo "We have a root mount - dispatch to live_san_migration"
					echo "${INSTANCE_NAME} ${INSTANCE_PROJECT} live_san_migration"
					break 2
				else
					LOOP_COUNT=$[ ${LOOP_COUNT} - 1 ]
				fi
			done
		# echo "We have SAN volumes and hypervisor volumes - we need to do an offline_migration"
		echo "${INSTANCE_NAME} ${INSTANCE_PROJECT} offline_migration"
		done
	else
		#echo "My VOLUME_ID_ARRAY is empty - must not be sharing storage - use block_migration"
		echo "${INSTANCE_NAME} ${INSTANCE_PROJECT} live_block_migration"
	fi
done
}

migration_type_check
