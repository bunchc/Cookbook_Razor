vagrant destroy -f chef
vagrant destroy -f razor
rm *.pem
vagrant up chef --provider=vmware_fusion
vagrant up razor --provider=vmware_fusion
