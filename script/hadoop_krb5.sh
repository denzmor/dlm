function kinitad {

export KRB5_CONFIG=/etc/krb5.conf
unset KRB5CCNAME
echo "Please enter your Active Directory password"
kinit $(id -nu)

}

function kinitidm {

export KRB5_CONFIG=/etc/krb5_idm.conf
unset KRB5CCNAME
echo "Please enter your IDM password"
kinit $(id -nu)

}

# Set to OS krb5 file
export KRB5_CONFIG=/etc/krb5_idm.conf

# If you are a genid, set to the krb5.conf deployed by Ambari
hadoop_account=(hdfs mapred ambari ranger yarn hive hcat hbase zookeeper knox activity_analyzer storm infra-solr oozie atlas ams tez zeppelin logsearch livy spark ambari-qa kafka sqoop slider falcon nifi solr)

for user in "${hadoop_account[@]}" ; do
  if [[  $(id -nu) == $user ]] ; then
    export KRB5_CONFIG=/etc/krb5.conf
    unset KRB5CCNAME
  fi
done

