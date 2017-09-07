#!/bin/bash

# Ensure you source the appropriate project

# To Dos
# Code for instances with one volume type - eg SAN only or Hypervisor local (hypervisor local needs --block-migration & while SAN doesn't) - DONE
# Code for instances with SAN and local storage - requires full outage to do this - DONE
# Migrate instance that is shutdown - Have yet to find a command that does this
# Make Functions for scenarios - DONE
# Add checks/waits for when node is active and shutoff - DONE
# Add check for which hypervisor is best - DONE
# Add feature to do this from admin project - DONE
# Add check to ensure $1 is set - DONE
# Add fix for offline_migration loop when instances fail to receive start/stop commands

# For Instances with storage on hypervisor and SAN


if [ $# -lt 1 ]
then
	echo "Usage: $0 INSTANCE_NAME"
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


# SET NEEDED VARS
INSTANCE_NAME=$1
echo ${INSTANCE_NAME}
#HYPERVISOR_VAR=$2
# Get Instance ID
INSTANCE_ID=$(openstack server list --all | grep -w ${INSTANCE_NAME} | awk '{print $2}')
echo ${INSTANCE_ID}

# Set Internal Field Separator to New Line - for array usage
IFS=$'\n'
# Set Volume IDs
VOLUME_ID_ARRAY=($(openstack volume list --all | grep ${INSTANCE_ID} | awk -F'|' '{print $2,$6}' | awk '{print $1,$6}'))
echo ${VOLUME_ID_ARRAY[@]}
CURRENT_HYPERVISOR_NAME=$(openstack server show ${INSTANCE_ID} | grep -w "OS-EXT-SRV-ATTR:hypervisor_hostname" | awk '{print $4}')

set_hypervisor()
{

	# Select best hypervisor
	# HYPERVISOR_ARRAY=($(nova hypervisor-list 2> /dev/null | grep -v disabled | grep mhv | awk '{print $4}'))
	
	#nova hypervisor-list 2> /dev/null
	#openstack hypervisor list --long
	echo "Setting NEW_HYPERVISOR_NAME"
	HYPERVISOR_LIST_ARRAY=($(nova hypervisor-list 2> /dev/null | grep enabled | grep -v ${CURRENT_HYPERVISOR_NAME} | awk '{print $4}'))	
	HYPERVISOR_LIST=$(for x in ${HYPERVISOR_LIST_ARRAY[@]} ; do echo -n "${x}|" ; done)
	HYPERVISOR_LIST=$(echo ${HYPERVISOR_LIST} | sed s'/.$//')

	NEW_HYPERVISOR_NAME=$(openstack hypervisor list --long | egrep "${HYPERVISOR_LIST}" | awk '{print $12, $4}' | sort -n | sed '1!d' | awk '{print $2}')

	#echo "Based on two tables above, please select best hypervisor - DO NOT SELECT A DISABLED HYPERVISOR, please use full name of hypervisor"
	#echo "CURRENT_HYPERVISOR_NAME = ${CURRENT_HYPERVISOR_NAME}"
	#read NEW_HYPERVISOR_NAME
	echo ${NEW_HYPERVISOR_NAME}

}

migration_type_dispatch()
{
	# Is this instance able to be migrated, what type of migration?
	if [ ${#VOLUME_ID_ARRAY[@]} -gt 0 ]
	then
		echo "We have at least one SAN volume"
		LOOP_COUNT=${#VOLUME_ID_ARRAY[@]}
		while [ ${LOOP_COUNT} -gt 0 ]
		do
			for VOLUME_ID in ${VOLUME_ID_ARRAY[@]} ; do
				echo ${VOLUME_ID}
				if [[ $(echo ${VOLUME_ID} | awk '{print $2}') == "/dev/vda" ]]
				then
					echo "We have a root mount - dispatch to live_san_migration"
					live_san_migration
				else
					LOOP_COUNT=$[ ${LOOP_COUNT} - 1 ]
				fi
			done
		echo "We have SAN volumes and hypervisor volumes - we need to do an offline_migration"
		offline_migration
		done
	else
		echo "My VOLUME_ID_ARRAY is empty - must not be sharing storage - use block-migration"
		live_block_migration
	fi
}

live_block_migration()
{
	echo "we are in live_block_migration"
	openstack server migrate ${INSTANCE_ID} --live ${NEW_HYPERVISOR_NAME} --block-migration --wait
	if [[ "$(echo ${CURRENT_HYPERVISOR_NAME})" != "$(openstack server show ${INSTANCE_ID} | grep -w "OS-EXT-SRV-ATTR:hypervisor_hostname" | awk '{print $4}')" ]]
	then
		openstack server show ${INSTANCE_ID}
		echo "Server has been successfully migrated from ${CURRENT_HYPERVISOR_NAME} to ${NEW_HYPERVISOR_NAME}"
		exit 0
	else
		echo "Server DID NOT successfully migrate from ${CURRENT_HYPERVISOR_NAME} to ${NEW_HYPERVISOR_NAME}"
		exit 1
	fi
}

live_san_migration()
{
	echo "we are in live_san_migration"
	openstack server migrate ${INSTANCE_ID} --live ${NEW_HYPERVISOR_NAME} --wait	
	if [[ "$(echo ${CURRENT_HYPERVISOR_NAME})" != "$(openstack server show ${INSTANCE_ID} | grep -w "OS-EXT-SRV-ATTR:hypervisor_hostname" | awk '{print $4}')" ]]
	then
		openstack server show ${INSTANCE_ID}
		echo "Server has been successfully migrated from ${CURRENT_HYPERVISOR_NAME} to ${NEW_HYPERVISOR_NAME}"
		exit 0
	else
		echo "Server DID NOT successfully migrate from ${CURRENT_HYPERVISOR_NAME} to ${NEW_HYPERVISOR_NAME}"
		exit 1
	fi
	#openstack server migrate ${INSTANCE_ID} --live mhv${HYPERVISOR_VAR}.ssint1.pv.metacloud.in
}

offline_migration()
{

	echo "we are in offline_migration"
	# Stop Instance
	openstack server stop ${INSTANCE_ID}
	while [[ $(openstack server show ${INSTANCE_ID} | grep -w "status" | awk '{print $4}') == "ACTIVE" ]]
	do
		echo "${INSTANCE_ID} is still ACTIVE - sleeping for 15 seconds"
		sleep 15
	done

	# Detach SAN storage from instance
	for VOLUME_ID in ${VOLUME_ID_ARRAY[@]} ; do
        openstack server remove volume ${INSTANCE_ID} $(echo ${VOLUME_ID} | awk '{print $1}')
	done

	# Start Instance
	openstack server start ${INSTANCE_ID}
	while [[ $(openstack server show ${INSTANCE_ID} | grep -w "status"  | awk '{print $4}') == "SHUTOFF" ]]
	do
		echo "${INSTANCE_ID} is still SHUTOFF - sleeping for 15 seconds"
		sleep 15
	done

	# Migrate Instance to new hypervisor - can this be done without booting???
	openstack server migrate ${INSTANCE_ID} --live ${NEW_HYPERVISOR_NAME} --block-migration --wait
	if [[ "$(echo ${CURRENT_HYPERVISOR_NAME})" != "$(openstack server show ${INSTANCE_ID} | grep -w "OS-EXT-SRV-ATTR:hypervisor_hostname" | awk '{print $4}')" ]]
	then
		openstack server show ${INSTANCE_ID}
		echo "Server has been successfully migrated from ${CURRENT_HYPERVISOR_NAME} to ${NEW_HYPERVISOR_NAME}"
	else
		echo "Server DID NOT successfully migrate from ${CURRENT_HYPERVISOR_NAME} to ${NEW_HYPERVISOR_NAME}"
	fi

	# Stop Instance
	openstack server stop ${INSTANCE_ID}
	while [[ $(openstack server show ${INSTANCE_ID} | grep -w "status"  | awk '{print $4}') == "ACTIVE" ]]
	do
		echo "${INSTANCE_ID} is still ACTIVE - sleeping for 15 seconds"
		sleep 15
	done
	
	# Attach SAN storage to instance
	for VOLUME_ID in ${VOLUME_ID_ARRAY[@]} ; do
        openstack server add volume ${INSTANCE_ID} $(echo ${VOLUME_ID} | awk '{print $1}') --device $(echo ${VOLUME_ID} | awk '{print $2}')
	done

	# Start Instance
	openstack server start ${INSTANCE_ID} 
}

set_hypervisor
migration_type_dispatch

#Test/Validate
