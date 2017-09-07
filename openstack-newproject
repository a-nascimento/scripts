#!/bin/bash
PROJECT_NAME=CTC-BAKER
INTERNAL=26
EXTERNAL=86
DNS1=10.1.73.23
DNS2=10.1.73.24
ADMIN_GROUP="andrew_nascimento Adam_Ravid Daniel_Goosen bobby_tyner ken_lemoine"
USER_GROUP="adam_balazs brett_baker zoltan_beke"
#USER_GROUP="rob_beattie brian_connolly chen_huang des_breen Gabriela_Magureanu HANNAH_MIANO Owen_Lagula paul_sideleau rekha_bojja"

#
DOMAIN_UUID=`openstack domain list | sed -n 's/^| \([^ ]*\) | surveysampling.*$/\1/p'`
if [ -z "${DOMAIN_UUID}" ]; then echo "Domain not found."; exit 1; fi
#
openstack project create "${PROJECT_NAME}" --domain "${DOMAIN_UUID}"
PROJECT_UUID=`openstack project list | sed -n 's/^| \([^ ]*\) | '"${PROJECT_NAME}"'.*/\1/p'`
if [ -z "${PROJECT_UUID}" ]; then echo "Something went wrong creating the tenant."; exit 1; fi
#
# user names are case sensitive
for admin in ${ADMIN_GROUP} ; do
  USER_UUID=`openstack user list --domain "${DOMAIN_UUID}" | sed -n 's/^| \([^ ]*\) | '$admin'.*/\1/p'`
  if [ -z "${USER_UUID}" ]; then 
    openstack user show $admin --domain "${DOMAIN_UUID}"
    USER_UUID=`openstack user list --domain "${DOMAIN_UUID}" | sed -n 's/^| \([^ ]*\) | '$admin'.*/\1/p'`
    if [ -z "${USER_UUID}" ]; then echo "User not found:  $admin."; exit 1; fi
  fi
  openstack role add --user-domain "${DOMAIN_UUID}" --user $admin --project "${PROJECT_UUID}" admin
done
#
for member in ${USER_GROUP} ; do
  USER_UUID=`openstack user list --domain "${DOMAIN_UUID}" | sed -n 's/^| \([^ ]*\) | '"${member}"'.*/\1/p'`
  if [ -z "${USER_UUID}" ]; then 
    openstack user show $member --domain "${DOMAIN_UUID}"
    USER_UUID=`openstack user list --domain "${DOMAIN_UUID}" | sed -n 's/^| \([^ ]*\) | '"${member}"'.*/\1/p'`
    if [ -z "${USER_UUID}" ]; then echo "User not found:  ${member}"; exit 1; fi
  fi
  openstack role add --user-domain "${DOMAIN_UUID}" --user "${member}" --project "${PROJECT_UUID}" _member_
done
#
neutron net-create --tenant-id "${PROJECT_UUID}" "${PROJECT_NAME}"
#neutron subnet-create --disable-dhcp --tenant_id 102051bc66434bbb8d5dda017a442095 --ip_version 4 --allocation_pool start=10.1.${EXTERNAL}.5,end=10.1.${EXTERNAL}.254 --name 'PUBLIC SUBNET 10.1.'${EXTERNAL}'.0/24 - DO NOT MODIFY' c6c80e8e-c170-41c4-bfbb-97dc8d9be7f1 10.1.${EXTERNAL}.0/24
neutron subnet-create --disable-dhcp --tenant_id "${PROJECT_UUID}" --ip_version 4 --allocation_pool start=10.1.${EXTERNAL}.5,end=10.1.${EXTERNAL}.254 --name 'PUBLIC SUBNET 10.1.'${EXTERNAL}'.0/24 - DO NOT MODIFY' c6c80e8e-c170-41c4-bfbb-97dc8d9be7f1 10.1.${EXTERNAL}.0/24
neutron subnet-create --tenant-id "${PROJECT_UUID}" --name "${PROJECT_NAME}" --dns-nameserver $DNS1 --dns-nameserver $DNS2 "${PROJECT_NAME}" "10.2.${INTERNAL}.0/24"
neutron router-create --tenant-id "${PROJECT_UUID}" "${PROJECT_NAME}"
neutron router-interface-add "${PROJECT_NAME}" "${PROJECT_NAME}"
neutron router-gateway-set --fixed-ip subnet_id="PUBLIC SUBNET - DO NOT MODIFY" "${PROJECT_NAME}" "PUBLIC EXTERNAL - DO NOT MODIFY"
openstack quota set --floating-ips "-1" "${PROJECT_UUID}"
#neutron router-gateway-set --fixed-ip subnet_id="PUBLIC SUBNET - DO NOT MODIFY" ${PROJECT_NAME}_HA_backup_1 "PUBLIC EXTERNAL - DO NOT MODIFY" 
EXTERNAL_SUBNET_UUID=`neutron subnet-list | sed -n 's/^| \([^ ]*\) | PUBLIC SUBNET 10\.1\.'"${EXTERNAL}"'\..*/\1/p'`
if [ -z "${EXTERNAL_SUBNET_UUID}" ]; then echo "EXTERNAL_SUBNET not found.  Aborting."; exit 1; fi
for ip in `seq 7 254`; do 
  neutron floatingip-create --tenant-id "${PROJECT_UUID}" --subnet "${EXTERNAL_SUBNET_UUID}" --floating-ip-address "10.1.${EXTERNAL}.${ip}" "PUBLIC EXTERNAL - DO NOT MODIFY"; 
done
#
SG=`openstack security group list --project ${PROJECT_NAME} | sed -n 's/^| \([-0-9a-f]*\) | default | Default security group .*$/\1/p'`
if [ -z "${SG}" ]; then echo "Default security group not found.  Aborting."; exit 1; fi
openstack security group rule create $SG --protocol icmp --remote-ip 0.0.0.0/0
openstack security group rule create $SG --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0
