#!/bin/bash
DOMAIN=${1}
BIT_SIZE=2048
KEY_FILE=${DOMAIN}.key
CSR_FILE=${DOMAIN}.csr

echo ${KEY_FILE}
echo ${CSR_FILE}

if [ $# != 1 ]
then
	echo "Usage: $0 DOMAIN"
	exit 1
fi

# Generate Key - need to generate key before CSR 
openssl genrsa -out ${KEY_FILE} ${BIT_SIZE}
# Generate CSR
openssl req -new -key ${KEY_FILE} -out ${CSR_FILE}
# Read CSR
#openssl req -in ${CSR_FILE} -noout -text
# Convert p7b to pem
#openssl pkcs7 -print_certs -in ${DOMAIN}.p7b -out ${DOMAIN}.pem
# Read pem file
#openssl x509 -in ${DOMAIN} -text -noout
# Hash of cert file
#openssl x509 -noout -modulus -in ${DOMAIN}.pem | openssl md5
# Hash of key file
#openssl rsa -noout -modulus -in ${DOMAIN}.key | openssl md5

exit 0
