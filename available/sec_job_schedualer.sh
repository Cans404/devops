#!/bin/bash

# created by Cans, 20181217
# sec job schedualer

step=10
cd ${oops_home}

for (( i = 0; i < 60; i++ step)); do
	./ocr_status_logger.sh "handle" 1>>${oops_home}/log/logger.trc 2>&1
	sleep ${step}
done
