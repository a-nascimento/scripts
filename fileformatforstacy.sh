#!/bin/bash

# File formatting
for line in $(cat fileA.txt)
do
	LETTER=$(echo ${line} | cut -c1)
	if [ ${LETTER} == P ]
	then
		echo ${line} >> outputfile.txt
		LASTFIELD=$(echo ${line##*|})
	fi

	if [ -n ${LASTFIELD} ]
	then
		if [ ${LETTER} == R ]
		then
			echo "${line}|${LASTFIELD}" >> outputfile.txt
		fi
	fi
done
