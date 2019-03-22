#!/bin/sh
#
dir=$(cd $(dirname $0) && pwd)
cd $dir
. ./setEnv.sh

java -cp "$INSTALL_CP" com.oracle.determinations.hub.exec.HubExecCmdLineCustomer undeploy "$@" <&0

