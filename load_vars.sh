#!/bin/bash
FOLDERS=$(find ../*/ -mindepth 0 -maxdepth 0 -type d && find ./*/ -mindepth 0 -maxdepth 0 -type d)
for dir in ${FOLDERS} ; do
   echo "Processing $dir"
   if [ -f "${dir}/docker-compose.yml" ] ; then
      echo "    $dir contains compose.yml"
      if [ -f "${dir}/vars" ] ; then
         echo "    source vars from ${dir}/vars"
         # shellcheck source=/dev/null
         source "${dir}"/vars
      fi
   fi
done
