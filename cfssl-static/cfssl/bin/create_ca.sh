#!/bin/bash

# creates a certificate/key pair meant to be used as a CA

# LIST OF INTERPRETED ENVIRONMENT VARIABLES:
#
#   - CN, O, OU, L, ST, C
#   - KEY_ALGO, KEY_SIZE
#   - CA_EXPIRY

OUT_DIR=/out
CONF_DIR=/cfssl/config
CONF_FILE=${CONF_DIR}/root_ca_config.json

# out dir does not exist
if [ ! -d "${OUT_DIR}" ]; then

    echo "FATAL: unable to find directory \"${OUT_DIR}\", please volume mount"
    exit 1
fi

# out dir is not writeable
touch ${OUT_DIR}/test

if [ $? != 0 ]; then

    echo "FATAL: unable to write into \"${OUT_DIR}\""
    exit 1
else

    rm ${OUT_DIR}/test
fi

# conf dir does not exist
if [ ! -d "${CONF_DIR}" ]; then

    echo "FATAL: unable to find directory \"${CONF_DIR}\""
    exit 1
fi

# conf file skeleton does not exist
if [ ! -f "${CONF_FILE}" ]; then

    echo "FATAL: unable to open \"${CONF_FILE}\""
    exit 1
fi

if [ "x${CN}" == "x" ]; then

    echo "FATAL: mandatory variable \"CN\" is not set"
    exit 1
fi

# load the csr from file
CONF=$(cat ${CONF_FILE} | jq '.')

# set cn
CONF=$(echo $CONF | jq --arg CN "${CN}" '.CN |= $CN')

# update key algo if needed
if [ "x${KEY_ALGO}" != "x" ]; then

    CONF=$(echo ${CONF} | jq --arg KEY_ALGO "${KEY_ALGO}" '.key.algo |= $KEY_ALGO')
fi

# update key size if needed
if [ "x${KEY_SIZE}" != "x" ]; then

    CONF=$(echo ${CONF} | jq --argjson KEY_SIZE "${KEY_SIZE}" '.key.size |= $KEY_SIZE')
fi

# update expiry if needed
if [ "x${CA_EXPIRY}" != "x" ]; then

    CONF=$(echo ${CONF} | jq --arg CA_EXPIRY "${CA_EXPIRY}" '.ca.expiry |= $CA_EXPIRY')
fi

# start with an empty JSON tag
NAMES="{}"

# update names
if [ "x${O}" != "x" ];  then NAMES=$(echo "${NAMES}" | jq --arg O  "${O}" '.O = $O'); fi
if [ "x${OU}" != "x" ]; then NAMES=$(echo "${NAMES}" | jq --arg OU "${OU}" '.OU = $OU'); fi
if [ "x${L}" != "x" ];  then NAMES=$(echo "${NAMES}" | jq --arg L  "${L}" '.L = $L'); fi
if [ "x${ST}" != "x" ]; then NAMES=$(echo "${NAMES}" | jq --arg ST "${ST}" '.ST = $ST'); fi
if [ "x${C}" != "x" ];  then NAMES=$(echo "${NAMES}" | jq --arg C  "${C}" '.C = $C'); fi

NAMES=$(echo $NAMES | jq -c '.')

if [ "${NAMES}" != "{}" ]; then

    CONF=$(echo ${CONF} | jq --argjson NAMES "${NAMES}" '.names |= [$NAMES]')
fi

# deploy config
echo ${CONF} | jq '.' > /tmp/create_ca.json

# display config
echo "GENERATE CONFIGURATION"
echo
cat /tmp/create_ca.json

#
echo "RUNNING CFSSL"
CRYPTO=$(cfssl gencert -initca /tmp/create_ca.json 2> /tmp/cfssl_output.txt)
ret=$?

cat /tmp/cfssl_output.txt
if [ $ret -ne 0 ]; then exit $ret; fi

# debug
if [ "x${DEBUG}" != "x" ]; then

    echo "DEBUG: CRYPTO RAW OUTPUT"
    echo "${CRYPTO}"
fi

# default produced certificate name to cert.pem and key name to key.pem
if [ "x${OUT_CERT_FILE}" == "x" ]; then OUT_CERT_FILE="cert.pem"; fi
if [ "x${OUT_KEY_FILE}" == "x" ]; then OUT_KEY_FILE="key.pem"; fi

# saving cert and key
echo "${CRYPTO}" | jq -r '.cert' | grep "\S" > "${OUT_DIR}/${OUT_CERT_FILE}"
echo "${CRYPTO}" | jq -r '.key' | grep "\S" > "${OUT_DIR}/${OUT_KEY_FILE}"

# print out the decoded certificate
echo "GENERATED CERTIFICATE:"
echo
openssl x509 -in ${OUT_DIR}/${OUT_CERT_FILE} -noout -text
