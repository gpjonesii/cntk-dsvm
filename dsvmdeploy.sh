#!/bin/bash

TERRAFORM_DIR="dsvm"

while test $# -gt 0; do
        case "$1" in
             -h|--help)
                   echo "Deploy CNTK DSVM into Azure"
                   echo " "
                   echo "options: "
                   echo "-h, --help		you're reading it!"
                   echo "-n, --no-gpu		deploy standard VM with no GPU"
                   exit 0
                   ;;
             -n|--no-gpu)
                   echo "Deploying CNTK DSVM onto Standard VM size"
                   TERRAFORM_DIR="dsvm-no-gpu"
                   break
                   ;;
	     *)
                   break
                   ;;
        esac
done

cd $TERRAFORM_DIR
echo $TERRAFORM_DIR
terraform init
terraform apply -input=false -auto-approve=true
