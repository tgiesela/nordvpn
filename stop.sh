#!/bin/bash
CMD=$1
if [ -z "$CMD" ] ; then
    echo "No option specified, assuming STOP"
    CMD=stop
fi

for dir in $(ls -d ../*/ ./*/) ;do
echo "Processing $dir"
   if [ -f "${dir}/docker-compose.yml" ] ; then
echo "    $dir contains compose.yml"
       if [ -f "${dir}/vars" ] ; then
echo "    source vars from $dir"
            source ${dir}/vars
       fi
   fi
done

docker compose $CMD
