#use alises it will help a lot cause we will type a lot, some of them are already enable and complition is turnd on (TAB TAB)
alias k='kubectl'
export do="--dry-run=client -o yaml"    # k create deploy nginx --image=nginx $do > pod.yaml
export now="--force --grace-period 0"   # k delete pod x $now


#some usefull commands to remember, thanks me later ;) 
#use "kubectl explain" to check the structure of a resource object if you do not remeber spec and could not find it in docs
kubectl explain deployment --recursive
#delete all pods in specific namespace
kubectl delete  -n [nameNAMESPACE] pod --all

#every "kubectl create [resourseNAME] --help"  will show the example command how to use it 
kubectl create configmap --help
OUTPUT >>>Examples:
          # Create a new config map named my-config based on folder bar
          kubectl create configmap my-config --from-file=path/to/bar
kubectl create secret generic --help
OUTPUT>>> Examples:
          # Create a new secret named my-secret with key1=supersecret and key2=topsecret
          kubectl create secret generic my-secret --from-literal=key1=supersecret --from-literal=key2=topsecret

#Print what resourse do we have in cluster
kubectl api-resources

#Print the supported API versions on the server, in the form of "group/version".
kubectl api-versions

#Deploy a new Pod
kubectl run my-pod –image=[podNAME]–namespace=[namepsaceNAME]

#get all pods across all namespaces
kubectl get pod --all-namespaces or k get pod -A

# Expose the Pod as a Service
kubectl expose pod my-pod –port=80 –namespace=[namepsaceNAME]

#This increas number of pods in deployment and replicasets
kubectl scale --replicas=3 deployment [deploymentNAME]

# Describe a resource
kubectl describe pod my-pod –-namespace=[namepsaceNAME]

# Check Pod logs in [namepsaceNAME]
kubectl logs my-pod –-namespace=[namepsaceNAME]

#Check events which are happening in [namepsaceNAME]
kubctl get events --nnapecpace=[namepsaceNAME] --sort-by='.metadata.creationTimestamp'

#In pod [podNAME] inside of it container [containerNAME] executes command sh passed after -- and is attached to interactive shell
kubectl exec -it [podNAME] -c [containerNAME] -- sh

#This commands shows us the current enabled admission controllers
kubectl exec -it -n kube-system kube-apiserver-controlplane -- kube-apiserver -h | grep -i enable-admission-plugins

#Will remove newlines from output usful when working with secrets
cat fileNAME | base64 -w 0

#Creates deployment yaml file to work with using image [imageNAME] and setting deployment name [deploymentNAME]
kubectl create deployment --dry-run=client --image=[imageNAME] --output=yaml [deploymentNAME] > [NAME.yml]

#create SVC
kubectl create service clusterip [serviceNAME] --tcp=[portNUMBER] --dry-run=client -o yaml

#Create Role
kubectl create role [roleNAME] --verb=list --verb=watch --resource=pods

#Create Role binding
kubectl create rolebinding [rolebindingNAME] --role=[roleNAME] --serviceaccount=[namespaceNAME]:[serviceaccountNAME]
kubectl auth can-i --help 

#Output: 
kubectl auth can-i list pods --as=system:serviceaccount:dev:foo -n prod
