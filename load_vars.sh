# ! /bin/bash
for dir in $(ls -d ../*/ ./*/) ;do
echo "Processing $dir"
   if [ -f "${dir}/docker-compose.yml" ] ; then
echo "    $dir contains compose.yml"
       if [ -f "${dir}/vars" ] ; then
echo "    source vars from $dirvars"
            source ${dir}vars
       fi
   fi
done
