vagrant destroy -f chef
vagrant destroy -f razor
vagrant destroy -f node-01
rm *.pem
vagrant up chef #--provider=vmware_fusion
vagrant up razor #--provider=vmware_fusion
