#!/bin/bash
# Delete and readd floating IP subnet for a particular project
# Andrew Nascimento - 03-28-2017

# enable error checking
## set -eu

# set needed vars
PROJECT_NAME=$1
INTERNAL_SUBNET=$2
EXTERNAL_SUBNET=$3


SUBNET_UUID=$(neutron subnet-list | grep "10.1.${EXTERNAL_SUBNET}." | awk '{print $2}')
PROJECT_UUID=$(openstack project list | grep -i ${PROJECT_NAME} | awk '{print $2}')

# check if floating IPs are used by an instance (report back the IPs used by the instance so they can be reallocated afterward)
## create array and test if empty

IFS=$'\n'
FLOATING_IP_ARRAY=($(openstack floating ip list | grep  10.2.${INTERNAL_SUBNET}. | awk '{print $2,$4,$6,$8}'))

# Test if array empty
if [ ${#FLOATING_IP_ARRAY[@]} -ne 0 ] ; then
	#echo back the each line of the array
	echo "FLOATING_IP_ARRAY not empty.  Do you want to proceed?"
	for ASSOCIATION in ${FLOATING_IP_ARRAY[@]} ; do
		echo ${ASSOCIATION}
	done
	read -p "pausing - ctrl + c - to quit"
	# Unassociate floating IPs from an instance
	for ASSOCIATION in ${FLOATING_IP_ARRAY[@]} ; do
		neutron floatingip-disassociate $(echo ${ASSOCIATION} | awk '{print $1}')
	done 
else
	echo "This subnet, ${EXTERNAL_SUBNET} does not have any FLOATING_IP associations. FLOATING_IP_ARRAY empty.  Would you like to proceed with deleting the allocated floating IPs?"
	read -p "pausing - ctrl + c - to quit"
fi

# delete allocated floating IPs
echo "Deleting floatingips in subnet"
for ID in $(neutron floatingip-list | grep 10.1.${EXTERNAL_SUBNET}. | awk '{print $2}') ; do echo "deleting floatingip with ID: ${ID}" ; neutron floatingip-delete ${ID} ; done

# delete subnet
echo "Deleting Subnet: ${SUBNET_UUID}"
openstack subnet delete ${SUBNET_UUID}

# recreate subnet
echo "Creating new subnet"
neutron subnet-create --disable-dhcp --tenant_id ${PROJECT_UUID} --ip_version 4 --allocation_pool start=10.1.${EXTERNAL_SUBNET}.5,end=10.1.${EXTERNAL_SUBNET}.254 --name 'PUBLIC SUBNET 10.1.'${EXTERNAL_SUBNET}'.0/24 - DO NOT MODIFY' c6c80e8e-c170-41c4-bfbb-97dc8d9be7f1 10.1.${EXTERNAL_SUBNET}.0/24

# set floatingip quota
echo "Setting floatingip quota"
openstack quota set --floating-ips "-1" "${PROJECT_UUID}"

# preallocate floating IP subnet IPs
echo "Setting variable for floating IP subnet UUID"
FLOATING_IP_SUBNET_UUID=$(neutron subnet-list | grep "PUBLIC SUBNET 10.1.${EXTERNAL_SUBNET}." | awk '{print $2}')

## allocate floating IP
echo "Allocating floating IPs to ${FLOATING_IP_SUBNET_UUID}"
for IP in $(seq 7 254) ; do neutron floatingip-create --tenant-id ${PROJECT_UUID} --subnet ${FLOATING_IP_SUBNET_UUID} --floating-ip-address "10.1.${EXTERNAL_SUBNET}.${IP}" "PUBLIC EXTERNAL - DO NOT MODIFY" ; done

# Reassign IPs that were pre-existing 
## Need to get new floating IP ID - while maintaining old IPs from original array
echo "Reassigning floating IPs that were previously assigned"
echo "Previous allocations (note column 1 will be different from new output):" 
echo "$(for ASSOCIATION in ${FLOATING_IP_ARRAY[@]} ; do
		echo ${ASSOCIATION}
	done)"
for ASSOCIATION in "${FLOATING_IP_ARRAY[@]}" ; do
		neutron floatingip-associate $(neutron floatingip-list | grep -w $(echo ${ASSOCIATION} | awk '{print $2}') | awk '{print $2}') $(echo ${ASSOCIATION} | awk '{print $4}')
done

echo "Reset var to compare from previous allocations"
FLOATING_IP_ARRAY=($(openstack floating ip list | grep 10.2.${INTERNAL_SUBNET}. | awk '{print $2,$4,$6,$8}'))

for ASSOCIATION in ${FLOATING_IP_ARRAY[@]} ; do
	echo ${ASSOCIATION}
done

exit 0

