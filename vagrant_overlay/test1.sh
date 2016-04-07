# Create a network, list it, delete it, list it.

NID=`docker network create -d openvswitch --subnet=192.168.1.0/24 foo`

OVN_REMOTE=`ovs-vsctl get o . external_ids:ovn-nb | sed 's/"//g'`
if docker network ls | grep foo 2>&1 >/dev/null; then :; else
  echo "test failed while creating network"
fi

logical_switch=`ovn-nbctl --db=$OVN_REMOTE --if-exists get logical_switch $NID name | sed 's/"//g'`



if [ "$NID" != "$logical_switch" ]; then
    echo "Logical switch in OVN does not match Docker network uuid"
    docker network rm foo
    exit 1
fi

docker network rm foo

if docker network ls | grep foo 2>&1 >/dev/null; then
  echo "test failed while deleting network"
fi

logical_switch=`ovn-nbctl --db=$OVN_REMOTE --if-exists get logical_switch $NID name`

if [ -n "$logical_switch" ]; then
   echo "Logical switch in OVN still exists after deleting docker network"
   exit 1
fi
