#!/bin/sh

CHECK_AWS=$(which aws)
test -n "${CHECK_AWS}" || { echo "aws command does not exist, exiting." ; exit $?; }

CHECK_CREDS=$(aws iam get-user)
test -n "${CHECK_CREDS}" || { echo "you are not authorized with an API key. exiting" ; exit $?; }

for ROLE in $(aws iam list-roles | grep RoleName | awk '{print $2}' | cut -d'"' -f2)
do
  echo ${ROLE}
  aws iam list-attached-role-policies --role-name ${ROLE} | egrep 'PolicyName|PolicyArn'
done
