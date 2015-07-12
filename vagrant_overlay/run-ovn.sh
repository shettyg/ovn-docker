IPAM_IP=$1 # 192.168.50.101
LOCAL_IP=$2 #192.168.50.101


ovn-integrate create-integration-bridge
ovn-integrate set-ipam $IPAM_IP
ovn-integrate set-tep $LOCAL_IP
ovn-controller --pidfile --detach -vconsole:off --log-file
ovn-docker-driver --overlay-mode --detach
