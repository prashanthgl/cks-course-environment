# Certified Kubernetes Security Specialist

## CHAPTER 1

**Exam Details and Resources**


### Extractive Summary


Exam Details and Resources This introductory chapter addresses the most pressing questions candidates ask when preparing for the Certified Kubernetes Security Specialist (CKS) exam .


Kubernetes Certification  Learning Path The CNCF offers four different Kubernetes certifications.


Kubernetes and Cloud Native Security Associate (KCSA) The certification focuses on basic knowledge of security concepts and their applica‐ tion in a Kubernetes cluster.


Certified  Kubernetes Application Developer (CKAD) The CKAD exam focuses on verifying your ability to build, configure, and deploy a microservices-based application to Kubernetes.


Certified  Kubernetes Administrator (CKA) The target audience for the CKA exam are DevOps practitioners, system administra‐ tors, and site reliability engineers.


This exam tests your ability to perform in the role of a Kubernetes administrator, which includes tasks like cluster, network, storage, and beginner-level security management, with a big emphasis on troubleshooting scenarios.


Certified  Kubernetes Security Specialist (CKS) The CKS exam expands on the topics verified by the CKA exam.


For this certification, you are expected to have a deeper knowledge of Kubernetes security aspects.


The Cloud Native Computing Foundation (CNCF) developed the Certified Kubernetes Security Specialist (CKS) certification to verify a Kubernetes administrator’s proficiency to protect a Kubernetes cluster and the cloud native software operated in it.


As part of the CKS exam, you are expected to understand Kubernetes core security features, as well as third-party tools and established practi‐ ces for securing applications and infrastructure.


Kubernetes version used during the exam At the time of writing, the exam is based on Kubernetes 1.26.


While preparing for the certification, review the Kubernetes release notes  and prac‐ tice with the Kubernetes version used during the exam to avoid unpleasant surprises.


Curriculum The following overview lists the high-level sections, also called domains, of the CKS exam and their scoring weights: •10%: Cluster Setup• •15%: Cluster Hardening• •15%: System Hardening• •20%: Minimize Microservice Vulnerabilities• •20%: Supply Chain Security• •20%: Monitoring, Logging, and Runtime Security• Curriculum | 3  How the book works The outline of the book follows the CKS curriculum to a T.


Cluster Setup This section covers Kubernetes concepts that have already been covered by the CKA exam; however, they assume that you already understand the basics and expect you to be able to go deeper.


Configuring audit logging for a Kubernetes cluster is part of the exam.


Involved Kubernetes Primitives Some of the exam objectives can be covered by understanding the relevant core Kubernetes primitives.


Kubernetes primitives relevant to the exam 6 | Chapter 1: Exam Details and Resources  In addition to Kubernetes core primitives, you will also need to have a grasp of specific Custom Resource Definitions (CRDs) provided by open source projects.


The official Kubernetes documentation includes the reference manual, the GitHub site, and the blog: •Reference manual: https://kubernetes.io/docs • •GitHub: https://github.com/kubernetes • •Blog: https://kubernetes.io/blog • For external tools, you are allowed to open and browse the following URL: •Trivy: https://github.com/aquasecurity/trivy • •Falco: https://falco.org/docs • •AppArmor: https://gitlab.com/apparmor/apparmor/-/wikis/Documentation • Documentation | 7  Candidate Skills The CKS certification assumes that you already have an administrator-level under‐ standing of Kubernetes.


If you have not passed the CKA exam yet or if you want to brush up on the topics, I’ d recommend having a look at my book Certified  Kubernetes Administrator (CKA) Study Guide .


For that purpose, you’ll need a functioning Kubernetes cluster environment.


Revisit the book’s materials for a refresher on the foundations. •Killer Shell  is a simulator with sample exercises for all Kubernetes certifications. • 8 | Chapter 1: Exam Details and Resources  •The CKS practice exam from Study4exam  offers a commercial, web-based test • environment to assess your knowledge level.


Summary The CKS exam verifies your hands-on knowledge of security-related aspects in Kubernetes.


The exam also involves helpful third-party security tools.


_Chapter length: 2417 words; sentences considered: 117._


---

## CHAPTER 2

**Cluster Setup**


### Extractive Summary


At a high level, this chapter covers the following concepts: •Using network policies to restrict Pod-to-Pod communication• •Running CIS benchmark tooling to identify security risks for cluster components• •Setting up an Ingress object with TLS support• •Protecting node ports, API endpoints, and GUI access• •Verifying platform binaries against their checksums• Using Network Policies to Restrict Pod-to-Pod Communication For a microservice architecture to function in Kubernetes, a Pod needs to be able to reach another Pod running on the same or on a different node without Network Address Translation (NAT).


It’s recommended to use Pod-to-Service communication over Pod-to-Pod communication so that you can rely on a consistent network interface.


Network policies act similarly to firewall rules, but for Pod-to-Pod communication.


Given Kubernetes default behavior for Pod-to-Pod network communi‐ cation, Pod 1 can talk to Pod 2 unrestrictedly and vice versa.


An attacker who gained access to Pod 1 has network access to other Pods 12 | Chapter 2: Cluster Setup  Observing the Default Behavior We’ll set up three Pods to demonstrate the unrestricted Pod-to-Pod network commu‐ nication in practice.


YAML manifest for three Pods in different  namespaces apiVersion : v1 kind: Namespace metadata :   labels:     app: orion   name: g04 --- apiVersion : v1 kind: Pod metadata :   labels:     tier: backend   name: backend   namespace : g04 spec:   containers :   - image: bmuschko/nodejs-hello-world:1.0.0     name: hello     ports:     - containerPort : 3000   restartPolicy : Never --- apiVersion : v1 kind: Pod metadata :   labels:     tier: frontend   name: frontend   namespace : g04 spec:   containers :   - image: alpine     name: frontend     args:     - /bin/sh     - -c     - while true; do sleep 5; done;   restartPolicy : Never --- apiVersion : v1 Using Network Policies to Restrict Pod-to-Pod Communication | 13  kind: Pod metadata :   labels:     tier: outside   name: other spec:   containers :   - image: alpine     name: other     args:     - /bin/sh     - -c     - while true; do sleep 5; done;   restartPolicy : Never Start by creating the objects from the existing YAML manifest using the declarative kubectl apply  command: $ kubectl apply -f setup.yaml namespace/g04 created pod/backend created pod/frontend created pod/other created Let’s verify that the namespace g04 runs the correct Pods.


The backend  Pod uses the IP address 10.0.0.43, and the frontend  Pod uses the IP address 10.0.0.193: $ kubectl get pods -n g04 -o wide NAME       READY   STATUS    RESTARTS   AGE   IP           NODE     \   NOMINATED NODE   READINESS GATES backend    1/1     Running   0          15s   10.0.0.43    minikube \   <none>           <none> frontend   1/1     Running   0          15s   10.0.0.193   minikube \   <none>           <none> The default  namespace handles a single Pod: $ kubectl get pods NAME    READY   STATUS    RESTARTS   AGE other   1/1     Running   0          4h45m The frontend  Pod can talk to the backend  Pod as no communication restrictions have been put in place: $ kubectl exec frontend -it -n g04 -- /bin/sh / # wget --spider --timeout=1 10.0.0.43:3000 Connecting to 10.0.0.43:3000 (10.0.0.43:3000) remote file exists / # exit 14 | Chapter 2: Cluster Setup  The other  Pod residing in the default  namespace can communicate with the back end Pod without problems: $ kubectl exec other -it -- /bin/sh / # wget --spider --timeout=1 10.0.0.43:3000 Connecting to 10.0.0.43:3000 (10.0.0.43:3000) remote file exists / # exit In the next section, we’ll talk about restricting Pod-to-Pod network communication to a maximum level with the help of deny-all network policy rules.


Denying Directional Network Traffic The best way to restrict Pod-to-Pod network traffic is with the principle of least privi‐ lege.


A default deny-all ingress network policy apiVersion : networking.k8s.io/v1 kind: NetworkPolicy metadata :   name: default-deny-ingress   namespace : g04 spec:   podSelector : {}   policyTypes :   - Ingress Selecting all Pods is denoted by the value {} assigned to the spec.podSelector attribute.


Using Network Policies to Restrict Pod-to-Pod Communication | 15  The contents of the “deny-all” network policy have been saved in the file deny-all- ingress-network-policy.yaml .


The following command creates the object from the file: $ kubectl apply -f deny-all-ingress-network-policy.yaml networkpolicy.networking.k8s.io/default-deny-ingress created Let’s see how this changed the runtime behavior for Pod-to-Pod network communi‐ cation.


Say we wanted to allow ingress traffic to the backend  Pod only from the frontend  Pod that lives in the same namespace.


Identify the labels of the g04 namespace and the Pod objects running in the same namespace so we can use them in the network policy: $ kubectl get ns g04 --show-labels NAME   STATUS   AGE   LABELS g04    Active   12m   app=orion,kubernetes.io/metadata.name=g04 $ kubectl get pods -n g04 --show-labels NAME       READY   STATUS    RESTARTS   AGE     LABELS backend    1/1     Running   0          9m46s   tier=backend frontend   1/1     Running   0          9m46s   tier=frontend 16 | Chapter 2: Cluster Setup  The label assignment for the namespace g04 includes the key-value pair app=orion .


The Pod backend  label set includes the key-value pair tier=backend , and the front end Pod the key-value pair tier=frontend .


Create a new network policy that allows the frontend  Pod to talk to the backend  Pod only on port 3000.


Network policy that allows ingress traffic apiVersion : networking.k8s.io/v1 kind: NetworkPolicy metadata :   name: backend-ingress   namespace : g04 spec:   podSelector :     matchLabels :       tier: backend   policyTypes :   - Ingress   ingress:   - from:     - namespaceSelector :         matchLabels :           app: orion       podSelector :         matchLabels :           tier: frontend     ports:     - protocol : TCP       port: 3000 The definition of the network policy has been stored in the file backend-ingress- network-policy.yaml .


Create the object from the file: $ kubectl apply -f backend-ingress-network-policy.yaml networkpolicy.networking.k8s.io/backend-ingress created The frontend  Pod can now talk to the backend  Pod: $ kubectl exec frontend -it -n g04 -- /bin/sh / # wget --spider --timeout=1 10.0.0.43:3000 Connecting to 10.0.0.43:3000 (10.0.0.43:3000) remote file exists / # exit Using Network Policies to Restrict Pod-to-Pod Communication | 17  Pods running outside of the g04 namespace still can’t connect to the backend  Pod.


The wget  command times out: $ kubectl exec other -it -- /bin/sh / # wget --spider --timeout=1 10.0.0.43:3000 Connecting to 10.0.0.43:3000 (10.0.0.43:3000) wget: download timed out Applying Kubernetes Component Security Best Practices Managing an on-premises Kubernetes cluster gives you full control over the config‐ uration options applied to cluster components, such as the API server, etcd, the kubelet, and others.


The following command runs the verification checks against the control plane node: $ kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/ \ main/job-master.yaml job.batch/kube-bench-master created Upon Job execution, the corresponding Pod running the verification process can be identified by its name in the default  namespace.


The following output uses the Pod named kube-bench-master-8f6qh : $ kubectl get pods NAME                      READY   STATUS      RESTARTS   AGE kube-bench-master-8f6qh   0/1     Completed   0          45s Wait until the Pod transitions into the “Completed” status to ensure that all verifica‐ tion checks have finished.


1.2.1 Edit the API server pod specification file /etc/kubernetes/manifests/ \ kube-apiserver.yaml on the control plane node and set the below parameter. --anonymous-auth=false Applying Kubernetes Component Security Best Practices | 19  ...


Then, edit the API server pod specification file  /etc/kubernetes/manifests/kube-apiserver.yaml on the control plane node and \  set the --kubelet-certificate-authority parameter to the path to the cert \  file for the certificate authority.  --kubelet-certificate-authority=<ca-string>  ... == Summary total ==  42 checks PASS 9 checks FAIL 11 checks WARN 0 checks INFO The inspected node, in this case the control plane node.


1.2.12 Edit the API server pod specification file /etc/kubernetes/manifests/ \ kube-apiserver.yaml on the control plane node and set the --enable-admission-plugins parameter \ to include AlwaysPullImages. --enable-admission-plugins=...,AlwaysPullImages,...


Go ahead and edit the file kube-apiserver.yaml : $ sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml After appending the value AlwaysPullImages  to the argument --enable-admission- plugins , the result could look as follows: apiVersion : v1 kind: Pod metadata :   annotations :     kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint : \     192.168.56.10:6443   creationTimestamp : null   labels:     component : kube-apiserver     tier: control-plane   name: kube-apiserver   namespace : kube-system spec:   containers :   - command:     - kube-apiserver     - --advertise-address=192.168.56.10     - --allow-privileged=true     - --authorization-mode=Node,RBAC     - --client-ca-file=/etc/kubernetes/pki/ca.crt     - --enable-admission-plugins=NodeRestriction,AlwaysPullImages ...


Applying Kubernetes Component Security Best Practices | 21  Y ou will need to delete the existing Job object before you can verify the changed result: $ kubectl delete job kube-bench-master job.batch "kube-bench-master" deleted The verification check 1.2.12 now reports a passed result: $ kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/ \ main/job-master.yaml job.batch/kube-bench-master created $ kubectl get pods NAME                      READY   STATUS      RESTARTS   AGE kube-bench-master-5gjdn   0/1     Completed   0          10s $ kubectl logs kube-bench-master-5gjdn | grep 1.2.12 [PASS] 1.2.12 Ensure that the admission control plugin AlwaysPullImages is \ set (Manual) Creating an Ingress with TLS Termination An Ingress routes HTTP and/or HTTPS traffic from outside of the cluster to one or many Services based on a matching URL context path.


YAML manifest for exposing nginx through a Service apiVersion : v1 kind: Namespace metadata :   name: t75 --- apiVersion : apps/v1 kind: Deployment metadata :   name: nginx-deployment   namespace : t75   labels:     app: nginx spec:   replicas : 3   selector :     matchLabels :       app: nginx   template :     metadata : Creating an Ingress with TLS Termination | 23        labels:         app: nginx     spec:       containers :       - name: nginx         image: nginx:1.14.2         ports:         - containerPort : 80 --- apiVersion : v1 kind: Service metadata :   name: accounting-service   namespace : t75 spec:   selector :     app: nginx   ports:     - protocol : TCP       port: 80       targetPort : 80 Create the objects from the YAML file with the following command: $ kubectl apply -f setup.yaml namespace/t75 created deployment.apps/nginx-deployment created service/accounting-service created Let’s quickly verify that the objects have been created properly, and the Pods have transitioned into the “Running” status.


Upon executing the get all  command, you should see a Deployment named nginx-deployment  that controls three replicas, and a Service named accounting-service  of type ClusterIP : $ kubectl get all -n t75 NAME                                    READY   STATUS    RESTARTS   AGE pod/nginx-deployment-6595874d85-5rdrh   1/1     Running   0          108s pod/nginx-deployment-6595874d85-jmhvh   1/1     Running   0          108s pod/nginx-deployment-6595874d85-vtwxp   1/1     Running   0          108s NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S) \   AGE service/accounting-service   ClusterIP   10.97.101.228   <none>        80/TCP \   108s NAME                               READY   UP-TO-DATE   AVAILABLE   AGE deployment.apps/nginx-deployment   3/3     3            3           108s Calling the Service endpoint from another Pod running on the same node should result in a successful response from the nginx Pod.


The resulting files are named accounting.crt  and accounting.key : $ openssl req -nodes -new -x509 -keyout accounting.key -out accounting.crt  \   -subj "/CN=accounting.tls" Generating a 2048 bit RSA private key ...........................+ ..........................+ writing new private key to 'accounting.key' ----- $ ls accounting.crt accounting.key For use in production environments, you’ d generate a key file and use it to obtain a TLS certificate from a certificate authority (CA).


The following command uses the Secret option tls and assigns the certificate and key file name with the options --cert  and --key : $ kubectl create secret tls accounting-secret --cert=accounting.crt  \   --key=accounting.key -n t75 secret/accounting-secret created Example 2-5  shows the YAML representation of a TLS Secret if you want to create the object declaratively.


A Secret using the type kubernetes.io/tls apiVersion : v1 kind: Secret metadata :   name: accounting-secret   namespace : t75 type: kubernetes.io/tls data:   tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk...   tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk...


The information relevant to creating the connection between Ingress object and the TLS Secret is the appended argument tls=accounting-secret : $ kubectl create ingress accounting-ingress  \   --rule="accounting.internal.acme.com/*=accounting-service:80,  \   tls=accounting-secret" -n t75 ingress.networking.k8s.io/accounting-ingress created Example 2-6  shows a YAML representation of an Ingress.


A YAML manifest for defining  a TLS-terminated Ingress apiVersion : networking.k8s.io/v1 kind: Ingress metadata :   name: accounting-ingress   namespace : t75 spec:   tls:   - hosts:     - accounting.internal.acme.com     secretName : accounting-secret 26 | Chapter 2: Cluster Setup    rules:   - host: accounting.internal.acme.com     http:       paths:       - path: /         pathType : Prefix         backend:           service:             name: accounting-service             port:               number: 80 After creating the Ingress object with the imperative or declarative approach, you should be able to find it in the namespace t75.


As you can see in the following output, the port 443 is listed in the “PORT” column, indicating that TLS termination has been enabled: $ kubectl get ingress -n t75 NAME                 CLASS   HOSTS                          ADDRESS       \   PORTS     AGE accounting-ingress   nginx   accounting.internal.acme.com   192.168.64.91 \   80, 443   55s Describing the Ingress object shows that the backend could be mapped to the path / and will route traffic to the Pod via the Service named accounting-service : $ kubectl describe ingress accounting-ingress -n t75 Name:             accounting-ingress Labels:           <none> Namespace:        t75 Address:          192.168.64.91 Ingress Class:    nginx Default backend:  <default> TLS:   accounting-secret terminates accounting.internal.acme.com Rules:   Host                          Path  Backends   ----                          ----  --------   accounting.internal.acme.com                                 /   accounting-service:80 \                                 (172.17.0.5:80,172.17.0.6:80,172.17.0.7:80) Annotations:                    <none> Events:   Type    Reason  Age               From                      Message   ----    ------  ----              ----                      -------   Normal  Sync    1s (x2 over 31s)  nginx-ingress-controller  Scheduled for sync Creating an Ingress with TLS Termination | 27  Calling the Ingress To test the behavior on a local Kubernetes cluster on your machine, you need to first find out the IP address of a node.


192.168.64.91   accounting.internal.acme.com Y ou can now send HTTPS requests to the Ingress using the assigned domain name and receive an HTTP response code 200 in return: $ wget -O- https://accounting.internal.acme.com --no-check-certificate --2022-07-28 15:32:43--  https://accounting.internal.acme.com/ Resolving accounting.internal.acme.com (accounting.internal.acme.com)... \ 192.168.64.91 Connecting to accounting.internal.acme.com (accounting.internal.acme.com) \ |192.168.64.91|:443... connected.


Scenario: A Compromised Pod Can Access the Metadata Server Figure 2-3  shows an attacker who gained access to a Pod running on a node within a cloud provider Kubernetes cluster.


A default deny-all egress to IP address 169.254.169.254 network policy apiVersion : networking.k8s.io/v1 kind: NetworkPolicy metadata :   name: default-deny-egress-metadata-server   namespace : a12 spec:   podSelector : {}   policyTypes :   - Egress   egress:   - to:     - ipBlock:         cidr: 0.0.0.0/0 30 | Chapter 2: Cluster Setup          except:         - 169.254.169.254/32 Once the network policy has been created, Pods in the namespace a12 should not be able to reach the metadata endpoints anymore.


Scenario: An Attacker Gains Access to the Dashboard Functionality The Kubernetes Dashboard runs as a Pod inside of the cluster.


The following command lists all of them: $ kubectl get deployments,pods,services -n kubernetes-dashboard NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE deployment.apps/dashboard-metrics-scraper   1/1     1            1           11m deployment.apps/kubernetes-dashboard        1/1     1            1           11m NAME                                             READY   STATUS    RESTARTS   AGE pod/dashboard-metrics-scraper-78dbd9dbf5-f8z4x   1/1     Running   0          11m pod/kubernetes-dashboard-5fd5574d9f-ns7nl        1/1     Running   0          11m NAME                                TYPE        CLUSTER-IP       EXTERNAL-IP \   PORT(S)    AGE service/dashboard-metrics-scraper   ClusterIP   10.98.6.37       <none>      \   8000/TCP   11m service/kubernetes-dashboard        ClusterIP   10.102.234.158   <none>      \   80/TCP     11m Accessing the Kubernetes Dashboard The kubectl proxy  command can help with temporarily creating a proxy that allows you to open the Dashboard in a browser.


Service account for admin permissions apiVersion : v1 kind: ServiceAccount metadata :   name: admin-user   namespace : kubernetes-dashboard Next, store the contents of Example 2-9  in the file admin-user-clusterrole binding.yaml  to map the ClusterRole named cluster-admin  to the ServiceAccount.


ClusterRoleBinding for admin permissions apiVersion : rbac.authorization.k8s.io/v1 kind: ClusterRoleBinding metadata :   name: admin-user roleRef:   apiGroup : rbac.authorization.k8s.io   kind: ClusterRole   name: cluster-admin subjects : - kind: ServiceAccount   name: admin-user   namespace : kubernetes-dashboard Create both objects with the following declarative command: $ kubectl create -f admin-user-serviceaccount.yaml serviceaccount/admin-user created $ kubectl create -f admin-user-clusterrolebinding.yaml clusterrolebinding.rbac.authorization.k8s.io/admin-user created Y ou can now create the bearer token of the admin user with the following command.


Service account for restricted permissions apiVersion : v1 kind: ServiceAccount metadata :   name: developer-user   namespace : kubernetes-dashboard The ClusterRole in Example 2-11  only allows getting, listing, and watching resources.


ClusterRole for restricted permissions apiVersion : rbac.authorization.k8s.io/v1 kind: ClusterRole metadata :   annotations :     rbac.authorization.kubernetes.io/autoupdate : "true"   name: cluster-developer rules: - apiGroups :   - '*'   resources : Protecting GUI Elements | 35    - '*'   verbs:   - get   - list   - watch - nonResourceURLs :   - '*'   verbs:   - get   - list   - watch Last, map the ServiceAccount to the ClusterRole in the file restricted-user- clusterrolebinding.yaml , as shown in Example 2-12 .


ClusterRoleBinding for restricted permissions apiVersion : rbac.authorization.k8s.io/v1 kind: ClusterRoleBinding metadata :   name: developer-user roleRef:   apiGroup : rbac.authorization.k8s.io   kind: ClusterRole   name: cluster-developer subjects : - kind: ServiceAccount   name: developer-user   namespace : kubernetes-dashboard Create all objects with the following declarative command: $ kubectl create -f restricted-user-serviceaccount.yaml serviceaccount/restricted-user created $ kubectl create -f restricted-user-clusterrole.yaml clusterrole.rbac.authorization.k8s.io/cluster-developer created $ kubectl create -f restricted-user-clusterrolebinding.yaml clusterrolebinding.rbac.authorization.k8s.io/developer-user created Generate the bearer token of the restricted user with the following command: $ kubectl create token developer-user -n kubernetes-dashboard eyJhbGciOiJSUzI1NiIsImtpZCI6...


The following list shows example URLs for platform binaries compati‐ ble with Linux AMD64: •kubectl : https://dl.k8s.io/v1.26.1/bin/linux/amd64/kubectl.sha256 • 38 | Chapter 2: Cluster Setup  •kubeadm : https://dl.k8s.io/v1.26.1/bin/linux/amd64/kubeadm.sha256 • •kubelet : https://dl.k8s.io/v1.26.1/bin/linux/amd64/kubelet.sha256 • •kube-apiserver : https://dl.k8s.io/v1.26.1/bin/linux/amd64/kube-apiserver.sha256 • Y ou’ll have to use an operating system-specific hash code validation tool to check the validity of a binary.


The following commands show the usage of the tool for different operating systems, as explained in the Kubernetes documentation : •Linux: echo "$(cat kubectl.sha256) kubectl" | sha256sum --check • •MacOSX: echo "$(cat kubectl.sha256) kubectl" | shasum -a 256 --check • •Windows with Powershell: $($(CertUtil -hashfile .\kubectl.exe SHA256) • [1] -replace " ", "") -eq $(type .\kubectl.exe.sha256) The following commands demonstrate downloading the kubeadm  binary for version 1.26.1 and its corresponding SHA256 hash file: $ curl -LO "https://dl.k8s.io/v1.26.1/bin/linux/amd64/kubeadm" $ curl -LO "https://dl.k8s.io/v1.26.1/bin/linux/amd64/kubeadm.sha256" The validation tool shasum  can verify if the checksum matches: $ echo "$(cat kubeadm.sha256)  kubeadm" | shasum -a 256 --check kubeadm: OK The previous command returned with an “OK” message.


_Chapter length: 7989 words; sentences considered: 332._


---

## CHAPTER 3

**Cluster Hardening**


### Extractive Summary


At a high level, this chapter covers the following concepts: •Restricting access to the Kubernetes API• •Configuring role-based access control (RBAC) to minimize exposure• •Exercising caution in using service accounts• •Updating Kubernetes frequently• Interacting with the Kubernetes API The API server is the gateway to the Kubernetes cluster.


Any human user, client (e.g., kubectl ), cluster component, or service account will access the API server by making a RESTful API call via HTTPS.


For a detailed discussion on the inner workings of the API server and the usage of the Kubernetes API, refer to the book Managing Kubernetes  by Brendan Burns and Craig Tracey (O’Reilly).


Connecting to the API Server It’s easy to determine the endpoint for the API server by running the following: $ kubectl cluster-info Kubernetes control plane is running at https://172.28.40.5:6443 ...


44 | Chapter 3: Cluster Hardening  For the given Kubernetes cluster, the API server has been exposed via the URL https://172.28.40.5:6443 .


Configuring  an insecure port for the API server The ability to configure the API server to use an insecure port (e.g., 80) has been deprecated in Kubernetes 1.10.


Using the kubernetes Service Kubernetes makes accessing the API server a little bit more convenient for specific use cases.


Instead of using the IP address and port for the API server, you can simply refer to the Service named kubernetes.default.svc  instead.


Y ou can easily find the Service with the following command: $ kubectl get service kubernetes NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   32s Upon inspection of the endpoints of this Service, you will see that it points to the IP address and port of the API server, as demonstrated by executing the following command: $ kubectl get endpoints kubernetes NAME         ENDPOINTS          AGE kubernetes   172.28.40.5:6443   4m3s The IP address and port of the Service is also exposed to the Pod via environment variables.


To render the environment, simply access the environment variables using the env command in a temporary Pod: $ kubectl run kubernetes-envs --image=alpine:3.16.2 -it --rm --restart=Never  \   -- env KUBERNETES_SERVICE_HOST=10.96.0.1 KUBERNETES_SERVICE_PORT=443 Interacting with the Kubernetes API | 45  We will use the kubernetes  Service in the section “Minimizing Permissions for a Service Account” on page 53 .


The option -k avoids verifying the server’s TLS certificate: $ curl https://172.28.40.5:6443/api/v1/namespaces -k {   "kind": "Status",   "apiVersion": "v1",   "metadata": {},   "status": "Failure",   "message": "namespaces is forbidden: User \"system:anonymous\" cannot list \               resource \"namespaces\" in API group \"\" at the cluster scope",   "reason": "Forbidden",   "details": {     "kind": "namespaces"   },   "code": 403 } As you can see from the JSON-formatted HTTP response body, anonymous calls are accepted by the API server but do not have the appropriate permissions for the operation.


The following command lists all available users, including their client certificate and key: $ kubectl config view --raw apiVersion: v1 clusters: - cluster:     certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tL...      server: https://172.28.132.5:6443   name: kubernetes contexts: - context:     cluster: kubernetes     user: kubernetes-admin 46 | Chapter 3: Cluster Hardening    name: kubernetes-admin@kubernetes current-context: kubernetes-admin@kubernetes kind: Config preferences: {} users: - name: kubernetes-admin    user:     client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tL...      client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktL...


The base64-encoded value of the certificate authority The user entry with administrator permissions created by default The base64-encoded value of the user’s client certificate The base64-encoded value of the user’s private key For making a call using the user kubernetes-admin , we’ll need to extract the base64- encoded values for the CA, client certificate, and private key into files as a base64- decoded value.


The CA value will be stored in the file ca, the client certificate value in kubernetes-admin.crt , and the private key in kubernetes-admin.key : $ echo LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tL... | base64 -d > ca $ echo LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tL... | base64 -d > kubernetes-admin.crt $ echo LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktL... | base64 -  \ > kubernetes-admin.key Y ou can now point the curl  command to those files with the relevant command line option.


The request to the API server should properly authenticate and return all existing namespaces, as the kubernetes-admin  has the appropriated permissions: $ curl --cacert ca --cert kubernetes-admin.crt --key kubernetes-admin.key  \   https://172.28.132.5:6443/api/v1/namespaces {   "kind": "NamespaceList",   "apiVersion": "v1",   "metadata": {     "resourceVersion": "2387"   },   "items": [     ...   ] } Interacting with the Kubernetes API | 47  Restricting Access to the API Server If you’re exposing the API server to the internet, ask yourself if it is necessary.


Restricting User Permissions We’ve seen that we can use the credentials of the kubernetes-admin  user to make calls to the Kubernetes API.


There are quite a few fields but you can leave some blank For some fields there will be a default value, If you enter '.', the field will be left blank. ----- Country Name (2 letter code) []: State or Province Name (full name) []: Locality Name (eg, city) []: Organization Name (eg, company) []: Organizational Unit Name (eg, section) []: Common Name (eg, fully qualified host name) []:johndoe Email Address []: Restricting Access to the API Server | 49  Please enter the following 'extra' attributes to be sent with your certificate request A challenge password []: Retrieve the base64-encoded value of the CSR file content with the following com‐ mand.


A CertificateSigning‐ Request resource  is used to request that a certificate be signed by a denoted signer: $ cat <<EOF | kubectl apply -f - apiVersion: certificates.k8s.io/v1 kind: CertificateSigningRequest metadata:   name: johndoe spec:   request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tL...   signerName: kubernetes.io/kube-apiserver-client   expirationSeconds: 86400   usages:   - client auth EOF certificatesigningrequest.certificates.k8s.io/johndoe created The value for kubernetes.io/kube-apiserver-client  for the attribute spec.signer Name  signs certificates that will be honored as client certificates by the API server.


As a result, the condition changes to “ Approved,Issued”: 50 | Chapter 3: Cluster Hardening  $ kubectl certificate approve johndoe certificatesigningrequest.certificates.k8s.io/johndoe approved $ kubectl get csr johndoe NAME        AGE   SIGNERNAME                            REQUESTOR     \   REQUESTEDDURATION   CONDITION johndoe     17s   kubernetes.io/kube-apiserver-client   minikube-user \   24h                 Approved,Issued Finally, export the issued certificate from the approved CertificateSigningRequest object: $ kubectl get csr johndoe -o jsonpath= {.status.certificate} | base64  \   -d > johndoe.crt Creating a Role and a RoleBinding It’s time to assign RBAC permissions.


Use the imperative command create rolebinding  to achieve that: $ kubectl create rolebinding developer-binding-johndoe --role=developer  \   --user=johndoe rolebinding.rbac.authorization.k8s.io/developer-binding-johndoe created Adding the user to the kubeconfig  file In this last step, you will need to add the user to the kubeconfig file and create the context for a user.


Be aware that the cluster name is minikube  in the following command, as we are trying this out in a minikube installation: $ kubectl config set-credentials johndoe --client-key=johndoe.key  \   --client-certificate=johndoe.crt --embed-certs=true User "johndoe" set. $ kubectl config set-context johndoe --cluster=minikube --user=johndoe Context "johndoe" created.


Restricting Access to the API Server | 51  Using kubectl  as the client that makes calls to the API server, we’ll verify that the operation should be allowed.


Executing the relevant kubectl  command will return with an error message: $ kubectl get namespaces Error from server (Forbidden): namespaces is forbidden: User "johndoe" cannot \ list resource "namespaces" in API group "" at the cluster scope Once you are done with verifying permissions, you may want to switch back to the context with admin permissions: $ kubectl config use-context minikube Switched to context "minikube".


Scenario: An Attacker Can Call the API Server from a Service Account A user represents a real person who commonly interacts with the Kubernetes cluster using the kubectl  executable or the UI dashboard.


Kubernetes uses a service account to authenticate the Helm service process with the API server through an authentication token.


An attacker uses a service account to call the API server 52 | Chapter 3: Cluster Hardening  Minimizing Permissions for a Service Account It’s important to limit the permissions to only those service accounts that are really necessary for the application to function.


Binding the service account to a Pod As a starting point, we are going to a set up a Pod that lists all Pods and Deployments in the namespace k97 by calling the Kubernetes API.


The default behavior of a service account is to auto-mount API credentials on the path /var/run/secrets/kubernetes.io/service account/token .


YAML manifest for assigning a service account to a Pod apiVersion : v1 kind: Namespace metadata :   name: k97 --- apiVersion : v1 kind: ServiceAccount metadata :   name: sa-api   namespace : k97 --- apiVersion : v1 kind: Pod metadata :   name: list-objects   namespace : k97 spec:   serviceAccountName : sa-api   containers :   - name: pods     image: alpine/curl:3.14 Restricting Access to the API Server | 53      command: ['sh', '-c', 'while true; do curl -s -k -m 5 -H \               "Authorization:  Bearer $(cat /var/run/secrets/kubernetes.io/  \               serviceaccount/token)"  https://kubernetes.default.svc.cluster.  \               local/api/v1/namespaces/k97/pods;  sleep 10; done']   - name: deployments     image: alpine/curl:3.14     command: ['sh', '-c', 'while true; do curl -s -k -m 5 -H \               "Authorization:  Bearer $(cat /var/run/secrets/kubernetes.io/  \               serviceaccount/token)"  https://kubernetes.default.svc.cluster.  \               local/apis/apps/v1/namespaces/k97/deployments;  sleep 10; done'] Create the objects from the YAML file with the following command: $ kubectl apply -f setup.yaml namespace/k97 created serviceaccount/sa-api created pod/list-objects created Verifying the default permissions The Pod named list-objects  makes a call to the API server to retrieve the list of Pods and Deployments in dedicated containers.


The logs of the containers pods  and deployments  return an error message indicating that the service account sa-api  is not authorized to list the resources: $ kubectl logs list-objects -c pods -n k97 {   "kind": "Status",   "apiVersion": "v1",   "metadata": {},   "status": "Failure",   "message": "pods is forbidden: User \"system:serviceaccount:k97:sa-api\" \               cannot list resource \"pods\" in API group \"\" in the \               namespace \"k97\"",   "reason": "Forbidden",   "details": {     "kind": "pods"   },   "code": 403 } $ kubectl logs list-objects -c deployments -n k97 {   "kind": "Status",   "apiVersion": "v1",   "metadata": {},   "status": "Failure", 54 | Chapter 3: Cluster Hardening    "message": "deployments.apps is forbidden: User \               \"system:serviceaccount:k97:sa-api\" cannot list resource \               \"deployments\" in API group \"apps\" in the namespace \               \"k97\"",   "reason": "Forbidden",   "details": {     "group": "apps",     "kind": "deployments"   },   "code": 403 } Next up, we’ll stand up a ClusterRole and RoleBinding object with the required API permissions to perform the necessary calls.


YAML manifest for a ClusterRole that allows listing Pods apiVersion : rbac.authorization.k8s.io/v1 kind: ClusterRole metadata :   name: list-pods-clusterrole rules: - apiGroups : [""]   resources : ["pods"]   verbs: ["list"] Create the object by pointing to its corresponding YAML manifest file: $ kubectl apply -f clusterrole.yaml clusterrole.rbac.authorization.k8s.io/list-pods-clusterrole created Creating the RoleBinding Example 3-3  defines the YAML manifest for the RoleBinding in the file rolebind ing.yaml .


The RoleBinding maps the ClusterRole list-pods-clusterrole  to the service account named sa-pod-api  and only applies to the namespace k97.


YAML manifest for a RoleBinding attached to a service account apiVersion : rbac.authorization.k8s.io/v1 kind: RoleBinding metadata :   name: serviceaccount-pod-rolebinding   namespace : k97 Restricting Access to the API Server | 55  subjects : - kind: ServiceAccount   name: sa-api roleRef:   kind: ClusterRole   name: list-pods-clusterrole   apiGroup : rbac.authorization.k8s.io Create both the RoleBinding object using the apply  command: $ kubectl apply -f rolebinding.yaml rolebinding.rbac.authorization.k8s.io/serviceaccount-pod-rolebinding created Verifying the granted permissions With the granted list  permissions, the service account can now properly retrieve all the Pods in the k97 namespace.


The curl  command in the pods  container succeeds, as shown in the following output: $ kubectl logs list-objects -c pods -n k97 {   "kind": "PodList",   "apiVersion": "v1",   "metadata": {     "resourceVersion": "628"   },   "items": [       {         "metadata": {           "name": "list-objects",           "namespace": "k97",           ...       }   ] } We did not grant any permissions to the service account for other resources.


The following output shows the response from the curl  command in the deployments  namespace: $ kubectl logs list-objects -c deployments -n k97 {   "kind": "Status",   "apiVersion": "v1",   "metadata": {},   "status": "Failure",   "message": "deployments.apps is forbidden: User \               \"system:serviceaccount:k97:sa-api\" cannot list resource \               \"deployments\" in API group \"apps\" in the namespace \               \"k97\"",   "reason": "Forbidden",   "details": { 56 | Chapter 3: Cluster Hardening      "group": "apps",     "kind": "deployments"   },   "code": 403 } Feel free to modify the ClusterRole object to allow listing Deployment objects as well.


Disabling automounting of a service account token The Pod described in the previous section used the service account’s token as a means to authenticate against the API server.


Opting out of a service account’s token automount behavior apiVersion : v1 kind: ServiceAccount metadata :   name: sa-api   namespace : k97 automountServiceAccountToken : false If you want to disable the automount behavior for individual Pods, use the attribute spec.automountServiceAccountToken  in the Pod definition.


Disabling token automounting for a service account in a Pod apiVersion : v1 kind: Pod metadata :   name: list-objects   namespace : k97 spec:   serviceAccountName : sa-api   automountServiceAccountToken : false   ...


Restricting Access to the API Server | 57  Generating a service account token There are a variety of use cases that speak for wanting to create a service account that disables  token automounting.


The object also doesn’t contain the secrets  attribute anymore in the YAML representation: $ kubectl get serviceaccount sa-api -n k97 NAME     SECRETS   AGE sa-api   0         42m Y ou can either generate the token using the create token  command, as described in “Generating a service account token”  on page 58, or manually create a corresponding Secret.


Creating a Secret for a service account manually apiVersion : v1 kind: Secret metadata : 58 | Chapter 3: Cluster Hardening    name: sa-api-secret   namespace : k97   annotations :     kubernetes.io/service-account.name : sa-api type: kubernetes.io/service-account-token To assign the service account to the Secret, add the annotation with the key kuber netes.io/service-account.name .


The following command creates the Secret object: $ kubectl create -f secret.yaml secret/sa-api-secret created Y ou can find the token in the “Data” section when describing the Secret object: $ kubectl describe secret sa-api-secret -n k97 ...


Process for a cluster version upgrade Updating Kubernetes Frequently | 61  Summary Users, clients applications (such as kubectl  or curl ), Pods using service accounts, and cluster components all communicate with the API server to manage objects.


For every user or service account, restrict the permissions to execute operations against the Kubernetes API to the bare minimum using RBAC rules.


Create and attach the service account api-call .


_Chapter length: 5628 words; sentences considered: 237._


---

## CHAPTER 4

**System Hardening**


### Extractive Summary


System Hardening The domain “system hardening” deals with security aspects relevant to the underlying host system running the Kubernetes cluster nodes.


The following systemctl  command lists all running services: $ systemctl | grep running ... snapd.service   loaded active running   Snap Daemon One of the services we will not need for operating a cluster node is the package manager snapd.


For more details on the service, retrieve the status for it with the status  subcommand: 66 | Chapter 4: System Hardening  $ systemctl status snapd ● snapd.service - Snap Daemon      Loaded: loaded (/lib/systemd/system/snapd.service; enabled; vendor \      preset: enabled)      Active: active (running) since Mon 2022-09-19 22:49:56 UTC; 30min ago TriggeredBy: ● snapd.socket    Main PID: 704 (snapd)       Tasks: 12 (limit: 2339)      Memory: 45.9M      CGroup: /system.slice/snapd.service              └─704 /usr/lib/snapd/snapd Y ou can stop service using the systemctl  subcommand stop : $ sudo systemctl stop snapd Warning: Stopping snapd.service, but it can still be activated by:   snapd.socket Execute the disable  subcommand to prevent the service from being started again upon a system restart: $ sudo systemctl disable snapd Removed /etc/systemd/system/multi-user.target.wants/snapd.service.


The service has now been stopped and disabled: $ systemctl status snapd ● snapd.service - Snap Daemon      Loaded: loaded (/lib/systemd/system/snapd.service; disabled; vendor \      preset: enabled)      Active: inactive (dead) since Mon 2022-09-19 23:22:22 UTC; 4min 4s ago TriggeredBy: ● snapd.socket    Main PID: 704 (code=exited, status=0/SUCCESS) Removing Unwanted Packages Now that the service has been disabled, there’s no more point in keeping the package around.


The following command creates the user ben: $ sudo adduser ben Adding user ‘ben’ ...


Adding new user ‘ben’ (1001) with group ‘ben’ ...


The user entry has been added to the file /etc/passwd : $ cat /etc/passwd ... ben:x:1001:1001:,,,:/home/ben:/bin/bash Switching to a user Y ou can change the user in a shell by using the su command.


To create a new environment, add the hyphen with the su command: $ su - ben ben@controlplane:~$ pwd /home/ben Another way to temporarily switch the user is by using the sudo  command.


Therefore, the sudo command is equivalent to “run this command as administrator”: $ sudo -u ben pwd /root Deleting a user Team members, represented by users in the system, transition to other teams or may simply leave the company.


The following command deletes the user, including the user’s home directory: $ sudo userdel -r ben Understanding Group Management It’s more convenient for a system administrator to group users with similar access requirements to control permissions on an individual user level.


The following example adds the group kube-developers : $ sudo groupadd kube-developers The group will now be listed in the file /etc/group .


Notice that the group identifier is 1004: $ cat /etc/group ... kube-developers:x:1004: Assigning a user to a group To assign a group to a user, use the usermod  command.


The following command adds the user ben to the group kube-developers : $ sudo usermod -g kube-developers ben The group identifier 1004 acts as a stand-in for the group kube-developers : $ cat /etc/passwd | grep ben ben:x:1001:1004:,,,:/home/ben:/bin/bash Deleting a group Sometimes you want to get rid of a group entirely.


Y ou will receive an error message if the members are still part of the group: $ sudo groupdel kube-developers groupdel: cannot remove the primary group of user ben Minimizing IAM Roles | 71  Before deleting a group, you should reassign group members to a different group using the usermod  command.


Assume that the group kube-admins  has been created before: $ sudo usermod -g kube-admins ben $ sudo groupdel kube-developers Understanding File Permissions and Ownership Assigning the file permissions with as minimal access as possible is crucial to maxi‐ mizing security.


The following command creates a file with the name my-file  in the current directory: $ touch my-file To see the contents of a directory in the “long” format, use the ls command.


Changing file ownership Use the chown  command to change the user and group assignment for a file or direc‐ tory.


The following command changes the ownership of the file to the user ben but does not reassign a group.


The user executing the chown  command needs to have write permissions: 72 | Chapter 4: System Hardening  $ chown ben my-file $ ls -l total 0 -rw-r--r-- 1 ben  root 0 Sep 26 17:53 my-file Changing file permissions Y ou can add or remove permissions with the chmod  command in a variety of nota‐ tions.


For example, use the following command to remove write permissions for the file owner: $ chmod -w file1 $ ls -l total 0 -r--r--r-- 1 ben  root 0 Sep 26 17:53 my-file Minimizing External Access to the Network External access to your cluster nodes should only be allowed for the ports necessary to operate Kubernetes.


Let’s say we installed the Apache 2 HTTP web server  on a control plane node with the following commands: $ sudo apt update $ sudo apt install apache2 Update about netstat command The netstat  command has been deprecated in favor of the faster, more human-readable ss command.


Y ou can review the status of a service with the systemctl status  command: $ sudo systemctl status apache2 ● apache2.service - The Apache HTTP Server      Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor \      preset: enabled)      Active: active (running) since Tue 2022-09-20 22:25:25 UTC; 39s ago        Docs: https://httpd.apache.org/docs/2.4/    Main PID: 18432 (apache2)       Tasks: 55 (limit: 2339)      Memory: 5.6M      CGroup: /system.slice/apache2.service              ├─18432 /usr/sbin/apache2 -k start              ├─18434 /usr/sbin/apache2 -k start              └─18435 /usr/sbin/apache2 -k start Apache 2 is not needed by Kubernetes.


Executing: /lib/systemd/systemd-sysv-install disable apache2 Removed /etc/systemd/system/multi-user.target.wants/apache2.service. $ sudo apt purge --auto-remove apache2 Verify that the port isn’t used anymore.


The following commands demonstrate the steps to achieve that: $ sudo ufw allow ssh Rules updated Rules updated (v6) $ sudo ufw default deny outgoing Default outgoing policy changed to deny (be sure to update your rules accordingly) $ sudo ufw default deny incoming Default incoming policy changed to deny (be sure to update your rules accordingly) $ sudo ufw enable Command may disrupt existing ssh connections.


Using Kernel Hardening Tools Applications or processes running inside of a container can make system calls.


Using AppArmor AppArmor  provides access control to programs running on a Linux system.


Example 4-1  defines a custom profile in the file k8s-deny-write  for restricting file write access.


An AppArmor profile  for restricting file write access #include <tunables/global> profile k8s-deny-write flags=(attach_disconnected) {    #include <abstractions/base> 76 | Chapter 4: System Hardening    file,    deny /** w,  } The identifier after the profile  keyword is the name of the profile.


Setting a custom profile To load the profile into AppArmor, run the following command on the worker node: $ sudo apparmor_parser /etc/apparmor.d/k8s-deny-write The command uses the enforce mode by default.


Y ou can manually install the package using the following commands if you want to use them: $ sudo apt-get update $ sudo apt-get install apparmor-utils Once installed, you can use the command aa-enforce  to load a profile in enforce mode, and aa-complain  to load a profile in complain mode.


A Pod applying an AppArmor profile  to a container apiVersion : v1 kind: Pod metadata :   name: hello-apparmor   annotations :     container.apparmor.security.beta.kubernetes.io/hello : \      localhost/k8s-deny-write   spec:   containers :   - name: hello      image: busybox:1.28     command: ["sh", "-c", "echo 'Hello AppArmor!'  && sleep 1h"] The annotation key that consists of a hard-coded prefix and the container name separated by a slash character.


Wait until the Pod transitions into the “Running” status: $ kubectl apply -f pod.yaml pod/hello-apparmor created $ kubectl get pod hello-apparmor NAME             READY   STATUS    RESTARTS   AGE hello-apparmor   1/1     Running   0          4s Y ou can now shell into the container and perform a file write operation: $ kubectl exec -it hello-apparmor -- /bin/sh / # touch test.txt touch: test.txt: Permission denied AppArmor will prevent writing a file to the container’s filesystem.


78 | Chapter 4: System Hardening  Using seccomp Seccomp, short for “Secure Computing Mode, ” is another Linux kernel feature that can restrict the calls made from the userspace into the kernel.


Applying the default container runtime profile  to a container Container runtimes, such as Docker Engine or containerd, ship with a default sec‐ comp profile.


A Pod applying the default seccomp profile  provided by the container runtime profile apiVersion : v1 kind: Pod metadata :   name: hello-seccomp spec:   securityContext :     seccompProfile :       type: RuntimeDefault     containers :   - name: hello     image: busybox:1.28     command: ["sh", "-c", "echo 'Hello seccomp!'  && sleep 1h"] Applies the default container runtime profile.


The Pod should transition into the “Running” status: $ kubectl apply -f pod.yaml pod/hello-seccomp created $ kubectl get pod hello-seccomp NAME            READY   STATUS    RESTARTS   AGE hello-seccomp   1/1     Running   0          4s Using Kernel Hardening Tools | 79  The echo  command executed in the container is considered unproblematic from a security perspective by the default seccomp profile.


The following command inspects the logs of the container: $ kubectl logs hello-seccomp Hello seccomp!


Setting a custom profile Y ou can create and set your own custom profile in addition to the default container runtime profile.


Create the directory if it doesn’t exist yet: $ sudo mkdir -p /var/lib/kubelet/seccomp/profiles We decide to create our custom profile in the file mkdir-violation.json  in the profile directory.


Applying the custom profile  to a container Applying a custom profile follows a similar pattern to applying the default container runtime profile, with minor differences.


A Pod applying a custom seccomp profile  prevents a mkdir  syscall apiVersion : v1 kind: Pod metadata :   name: hello-seccomp spec:   securityContext :     seccompProfile :       type: Localhost         localhostProfile : profiles/mkdir-violation.json     containers :   - name: hello     image: busybox:1.28     command: ["sh", "-c", "echo 'Hello seccomp!'  && sleep 1h"]     securityContext :       allowPrivilegeEscalation : false Refers to a profile on the current node.


Wait until the Pod transitions into the “Running” status: $ kubectl apply -f pod.yaml pod/hello-seccomp created $ kubectl get pod hello-seccomp NAME            READY   STATUS    RESTARTS   AGE hello-seccomp   1/1     Running   0          4s Using Kernel Hardening Tools | 81  Shell into the container to verify that seccomp properly enforced the applied rules: $ kubectl exec -it hello-seccomp -- /bin/sh / # mkdir test mkdir: can't create directory test: Operation not permitted As you can see in output, the operation renders an error message when trying to execute the mkdir  command.


AppArmor and seccomp are just some kernel hardening tools that can be inte‐ grated with Kubernetes to restrict system calls made from a container.


Create  an  AppArmor  profile  named  network-deny .


Create a seccomp profile file named audit.json  that logs all syscalls in the standard seccomp directory.


_Chapter length: 5460 words; sentences considered: 283._


---

## CHAPTER 5

**Minimizing Microservice Vulnerabilities**


### Extractive Summary


At a high level, this chapter covers the following concepts: •Setting up appropriate OS-level security domains with security contexts, Pod• Security Admission (PSA), and Open Policy Agent Gatekeeper •Managing Secrets• •Using container runtime sandboxes, such as gVisor and Kata Containers• •Implementing Pod-to-Pod communication encryption via mutual Transport• Layer Security (TLS) Setting Appropriate OS-Level Security Domains Both core Kubernetes and the Kubernetes ecosystem offer solutions for defining, enforcing, and governing security settings on the Pod and container level.


This sec‐ tion will discuss security contexts, Pod Security Admission, and Open Policy Agent Gatekeeper.


An attacker misuses root user container access For that reason, running a container with the default root user is a bad idea.


Understanding Security Contexts Kubernetes, as the container orchestration engine, can apply additional configuration to increase container security.


A security context defines privilege and access control settings for a Pod or a container.


The following list provides some examples: •The user ID that should be used to run the Pod and/or container• •The group ID that should be used for filesystem access• •Granting a running process inside the container some privileges of the root user• but not all of them The security context is not a Kubernetes primitive.


Security settings defined on the Pod level apply to all containers running in the Pod; however, 86 | Chapter 5: Minimizing Microservice Vulnerabilities  container-level settings take precedence.


The YAML manifest file container-non-root-user-error.yaml  shown in Example 5-1  defines the security configuration specifically for a container.


Enforcing a non-root user on an image that needs to run with the root user apiVersion : v1 kind: Pod metadata :   name: non-root-error spec:   containers :   - image: nginx:1.23.1     name: nginx     securityContext :       runAsNonRoot : true The container fails during the startup process with the status CreateContainer ConfigError .


The configured security context does not allow it: $ kubectl apply -f container-non-root-user-error.yaml pod/non-root-error created $ kubectl get pod non-root-error NAME             READY   STATUS                       RESTARTS   AGE non-root-error   0/1     CreateContainerConfigError   0          9s $ kubectl describe pod non-root-error ...


Events:   Type     Reason     Age               From               Message   ----     ------     ----              ----               -------   Normal   Scheduled  24s               default-scheduler  Successfully \   assigned default/non-root to minikube   Normal   Pulling    24s               kubelet            Pulling image \   "nginx:1.23.1"   Normal   Pulled     16s               kubelet            Successfully \   pulled image "nginx:1.23.1" in 7.775950615s Setting Appropriate OS-Level Security Domains | 87    Warning  Failed     4s (x3 over 16s)  kubelet            Error: container \   has runAsNonRoot and image will run as root (pod: "non-root-error_default \   (6ed9ed71-1002-4dc2-8cb1-3423f86bd144)", container: secured-container)   Normal   Pulled     4s (x2 over 16s)  kubelet            Container image \   "nginx:1.23.1" already present on machine There are alternative nginx container images available that are not required to run with the root  user.


Enforcing a non-root user on an image that supports running with a user ID apiVersion : v1 kind: Pod metadata :   name: non-root-success spec:   containers :   - image: bitnami/nginx:1.23.1     name: nginx     securityContext :       runAsNonRoot : true Starting the container with the runAsNonRoot  directive will work just fine.


The container transitions into the “Running” status: $ kubectl apply -f container-non-root-user-success.yaml pod/non-root-success created $ kubectl get pod non-root-success NAME               READY   STATUS    RESTARTS   AGE non-root-success   1/1     Running   0          7s Let’s quickly check which user ID the container runs with.


The image bitnami/nginx  sets the user ID to 1001 with the help of an instruction when the container image is built: $ kubectl exec non-root-success -it -- /bin/sh $ id uid=1001 gid=0(root) groups=0(root) $ exit Setting a Specific  User and Group ID Many container images do not set an explicit user ID or group ID.


Running the container with a specific  user and group ID apiVersion : v1 kind: Pod metadata :   name: user-id spec:   containers :   - image: busybox:1.35.0     name: busybox     command: ["sh", "-c", "sleep 1h"]     securityContext :       runAsUser : 1000       runAsGroup : 3000 Creating the Pod will work without issues.


The container transitions into the “Run‐ ning” status: $ kubectl apply -f container-user-id.yaml pod/user-id created $ kubectl get pods user-id NAME      READY   STATUS    RESTARTS   AGE user-id   1/1     Running   0          6s Y ou can inspect the user ID and group ID after shelling into the container.


Assume the following implications when using a privileged container: •Processes within a container almost have the same privileges as processes on the• host. •The container has access to all devices on the host.• Setting Appropriate OS-Level Security Domains | 89  •The root user in the container has similar privileges to the root  user on the host. • •All directories on the host’s filesystem can be mounted in the container.• •Kernel settings can be changed, e.g., by using the sysctl  command . • Using containers in privileged mode Configuring a container to use privileged mode should be a rare occasion.


No security context has been set on the Pod or container level.


A Pod with a container in non-privileged mode apiVersion : v1 kind: Pod metadata :   name: non-privileged spec:   containers :   - image: busybox:1.35.0     name: busybox     command: ["sh", "-c", "sleep 1h"] Create the Pod and ensure that it comes up properly: $ kubectl apply -f non-privileged.yaml pod/non-privileged created $ kubectl get pods NAME             READY   STATUS    RESTARTS   AGE non-privileged   1/1     Running   0          6s To demonstrate the isolation between the container namespace and host’s namespace, we’ll try to use the sysctl  to change the hostname.


As you can see in the output of the command, the container will clearly enforce the restricted privileges: $ kubectl exec non-privileged -it -- /bin/sh / # sysctl kernel.hostname=test sysctl: error setting key 'kernel.hostname': Read-only file system / # exit 90 | Chapter 5: Minimizing Microservice Vulnerabilities  To make a container privileged, simply assign the value true  to the security context attribute privileged .


A Pod with a container configured  to run in privileged mode apiVersion : v1 kind: Pod metadata :   name: privileged spec:   containers :   - image: busybox:1.35.0     name: busybox     command: ["sh", "-c", "sleep 1h"]     securityContext :       privileged : true Create the Pod as usual.


The Pod should transition into the “Running” status: $ kubectl apply -f privileged.yaml pod/privileged created $ kubectl get pod privileged NAME         READY   STATUS    RESTARTS   AGE privileged   1/1     Running   0          6s Y ou can now see that the same sysctl  will allow you to change the hostname: $ kubectl exec privileged -it -- /bin/sh / # sysctl kernel.hostname=test kernel.hostname = test / # exit A container security context configuration related to privileged mode is the attribute allowPrivilegeEscalation .


The next section explores the Kubernetes core feature named Pod Security Admission.


Understanding Pod Security Admission (PSA) Older versions of Kubernetes shipped with a feature called Pod Security Policies (PSP).


Pod Security Policies are a concept that help with enforcing security standards for Pod objects.


Kubernetes 1.21 deprecated Pod Security Policies and introduced the replacement functionality Pod Security Admission.


Pod Security Admission modes Mode Behavior enforce Violations will cause the Pod to be rejected. audit Pod creation will be allowed.


Enforcing Pod Security Standards for a Namespace Let’s apply a PSA to a Pod in the namespace psa.


A namespace enforcing the highest level of security standards apiVersion : v1 kind: Namespace metadata :   name: psa   labels:     pod-security.kubernetes.io/enforce : restricted Make sure that the Pod is created in the namespace psa.


A Pod violating the PSA restrictions apiVersion : v1 kind: Pod metadata :   name: busybox   namespace : psa Setting Appropriate OS-Level Security Domains | 93  spec:   containers :   - image: busybox:1.35.0     name: busybox     command: ["sh", "-c", "sleep 1h"] Violations will be rendered in the console upon running a command to create a Pod in the namespace.


As you can see in the following, the Pod wasn’t allowed to be created: $ kubectl create -f psa-namespace.yaml namespace/psa created $ kubectl apply -f psa-violating-pod.yaml Error from server (Forbidden): error when creating "psa-pod.yaml": pods \ "busybox" is forbidden: violates PodSecurity "restricted:latest": \ allowPrivilegeEscalation != false (container "busybox" must set \ securityContext.allowPrivilegeEscalation=false), unrestricted \ capabilities (container "busybox" must set securityContext. \ capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container \ "busybox" must set securityContext.runAsNonRoot=true), seccompProfile \ (pod or container "busybox" must set securityContext.seccompProfile. \ type to "RuntimeDefault" or "Localhost") $ kubectl get pod -n psa No resources found in psa namespace.


Example 5-8  shows an exemplary Pod definition that does not violate the Pod Security Standard.


A Pod following the PSS apiVersion : v1 kind: Pod metadata :   name: busybox   namespace : psa spec:   containers :   - image: busybox:1.35.0     name: busybox     command: ["sh", "-c", "sleep 1h"]     securityContext :       allowPrivilegeEscalation : false       capabilities :         drop: ["ALL"]       runAsNonRoot : true       runAsUser : 2000       runAsGroup : 3000       seccompProfile :         type: RuntimeDefault 94 | Chapter 5: Minimizing Microservice Vulnerabilities  Creating the Pod object now works as expected: $ kubectl apply -f psa-non-violating-pod.yaml pod/busybox created $ kubectl get pod busybox -n psa NAME      READY   STATUS    RESTARTS   AGE busybox   1/1     Running   0          10s PSA is a built-in, enabled-by-default feature in Kubernetes version 1.23 or higher.


Assume that the constraint template was written to the file constraint-template-labels.yaml  and the constraint to the file constraint- ns-labels.yaml : $ kubectl apply -f constraint-template-labels.yaml constrainttemplate.templates.gatekeeper.sh/k8srequiredlabels created $ kubectl apply -f constraint-ns-labels.yaml k8srequiredlabels.constraints.gatekeeper.sh/ns-must-have-app-label-key created Y ou can verify the validation behavior with a quick-to-run imperative command.


YAML manifest for namespace with a label assignment apiVersion : v1 kind: Namespace metadata :   labels:     app: orion   name: governed-ns The following command creates the object from the YAML manifest file named namespace-app-label.yaml : $ kubectl apply -f namespace-app-label.yaml namespace/governed-ns created This simple example demonstrated the usage of OPA Gatekeeper.


Add the parameter --encryption-provider-config , and define the Volume and its mountpath for the configuration file as the following shows: $ sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml apiVersion: v1 kind: Pod metadata:   annotations:     kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: \     192.168.56.10:6443   creationTimestamp: null   labels:     component: kube-apiserver     tier: control-plane   name: kube-apiserver   namespace: kube-system spec:   containers:   - command:     - kube-apiserver     - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml     volumeMounts:     ...     - name: enc       mountPath: /etc/kubernetes/enc       readonly: true   volumes:   ...   - name: enc     hostPath:       path: /etc/kubernetes/enc       type: DirectoryOrCreate ...


Understanding Container Runtime Sandboxes Containers run in a container runtime isolated from the host environment.


After instantiating a container from the image, the malicious code running in the kernel group of container 1 can access the process running in container 2.


YAML manifest for a Pod using a runtime class apiVersion : v1 kind: Pod metadata :   name: nginx spec:   runtimeClassName : gvisor   containers : 106 | Chapter 5: Minimizing Microservice Vulnerabilities    - name: nginx     image: nginx:1.23.2 Create the runtime class and Pod object using the apply  command: $ kubectl apply -f runtimeclass.yaml runtimeclass.node.k8s.io/gvisor created $ kubectl apply -f pod.yaml pod/nginx created Y ou can verify that the container is running with the container runtime sandbox.


Understanding Pod-to-Pod Encryption with mTLS In “Using Network Policies to Restrict Pod-to-Pod Communication”  on page 11, we talked about Pod-to-Pod communication.


Understanding Pod-to-Pod Encryption with mTLS | 107  Scenario: An Attacker Listens to the Communication Between Two Pods An attacker can use the default, unencrypted Pod-to-Pod network communication behavior to their advantage.


The Pod Security Admission is a Kubernetes feature that takes Pod security settings one step further.


Pod-to-Pod communication is unencrypted and unauthenticated by default.


1.Create a Pod named busybox-security-context  with the container image busy 1. box:1.28  that runs the command sh -c sleep 1h .


2.Create a Pod Security Admission (PSA) rule.


_Chapter length: 8364 words; sentences considered: 369._


---

## CHAPTER 6

**Supply Chain Security**


### Extractive Summary


At a high level, this chapter covers the following concepts: •Minimizing base image footprint• •Securing the supply chain• •Using static analysis of user workload• •Scanning images for known vulnerabilities• Minimizing the Base Image Footprint The process for building a container image looks straightforward on the surface level; however, the devil is often in the details.


An attacker exploits container image vulnerabilities It is recommended to use a base image with a minimal set of functionality and dependencies.


As you can see in the following output, the downloaded alpine  container image with the tag 3.17.0  only has a size of 7.05MB: $ docker pull alpine:3.17.0 ... $ docker image ls alpine REPOSITORY   TAG       IMAGE ID       CREATED       SIZE alpine       3.17.0    49176f190c7e   3 weeks ago   7.05MB The alpine  container image comes with an sh shell you can use to troubleshoot the process running inside of the container.


Y ou can further reduce the container image size and the attack surface by using a distroless image  offered by Google.


The size of the container image is only 2.34MB: $ docker pull gcr.io/distroless/static-debian11 ... $ docker image ls gcr.io/distroless/static-debian11:latest REPOSITORY                          TAG       IMAGE ID       CREATED      \   SIZE gcr.io/distroless/static-debian11   latest    901590160d4d   53 years ago \   2.34MB A distroless container image does not ship with any shell, which you can observe by running the following command: $ docker run -it gcr.io/distroless/static-debian11:latest /bin/sh docker: Error response from daemon: failed to create shim task: OCI runtime \ create failed: runc create failed: unable to start container process: exec: \ "/bin/sh": stat /bin/sh: no such file or directory: unknown.


Minimizing the Base Image Footprint | 117  The resulting container image size is significantly smaller when using the alpine base image, only 12MB.


Y ou can further reduce the size of the container image by incorporating a distroless base image instead of the alpine  base image.


The more layers you add to the container image, the slower will be the build execution time and/or the bigger will be the size of the container image.


Signing Container Images Y ou can sign a container image before pushing it to a container registry.


Signing can be achieved with the docker trust sign  command, which adds a signature to the container image, the so-called image digest.


An image digest is derived from the contents of the container image and commonly represented in the form of SHA256.


When consuming the container image, Kubernetes can compare the image digest with the contents of the image to ensure that it hasn’t been tampered with.


Scenario: An Attacker Injects Malicious Code into a Container Image The Kubernetes component that verifies the image digest is the kubelet.


If you configured the image pull policy  to Always , the kubelet will query for the image digest from the container registry even though it may have downloaded and verified the container image before.


An attacker injects malicious code into a container image Image checksum validation is not automatic Image digest validation is an opt-in functionality in Kubernetes.


Validating Container Images In Kubernetes, you’re able to append the SHA256 image digest to the speci‐ fication of a container.


For example, Figure 6-3  shows the image digest for the container image alpine:3.17.0  on Docker Hub .


The image digest of the alpine:3.17.0  container image on Docker Hub Let’s see the image digest in action.


Instead of using the tag, Example 6-5  specifies the container image by appending the image digest.


A Pod using a valid container image digest apiVersion : v1 kind: Pod metadata :   name: alpine-valid spec:   containers :   - name: alpine     image: alpine@sha256:c0d488a800e4127c334ad20d61d7bc21b40 \            97540327217dfab52262adc02380c     command: ["/bin/sh" ]     args: ["-c", "while true; do echo hello; sleep 10; done"] Creating the Pod will work as expected.


The image digest will be verified and the container transitions into the “Running” status: $ kubectl apply -f pod-valid-image-digest.yaml pod/alpine-valid created $ kubectl get pod alpine-valid NAME           READY   STATUS    RESTARTS   AGE alpine-valid   1/1     Running   0          6s Example 6-6  shows the same Pod definition; however, the image digest has been changed so that it does not match with the contents of the container image.


A Pod using an invalid container image digest apiVersion : v1 kind: Pod metadata :   name: alpine-invalid spec:   containers :   - name: alpine     image: alpine@sha256:d006a643bccb6e9adbabaae668533c7f2e5 \            111572fffb5c61cb7fcba7ef4150b Securing the Supply Chain | 121      command: ["/bin/sh" ]     args: ["-c", "while true; do echo hello; sleep 10; done"] Y ou will see that Kubernetes can still create the Pod object but it can’t properly validate the hash of the container image.


Events:   Type     Reason     Age   From               Message   ----     ------     ----  ----               -------   Normal   Scheduled  13s   default-scheduler  Successfully assigned default \   /alpine-invalid to minikube   Normal   Pulling    13s   kubelet            Pulling image "alpine@sha256: \   d006a643bccb6e9adbabaae668533c7f2e5111572fffb5c61cb7fcba7ef4150b"   Warning  Failed     11s   kubelet            Failed to pull image \   "alpine@sha256:d006a643bccb6e9adbabaae668533c7f2e5111572fffb5c61cb7fcba7ef4 \   150b": rpc error: code = Unknown desc = Error response from daemon: manifest \   for alpine@sha256:d006a643bccb6e9adbabaae668533c7f2e5111572fffb5c61cb7fcba7e \   f4150b not found: manifest unknown: manifest unknown   Warning  Failed     11s   kubelet            Error: ErrImagePull   Normal   BackOff    11s   kubelet            Back-off pulling image \   "alpine@sha256:d006a643bccb6e9adbabaae668533c7f2e5111572fffb5c61cb7fcba7ef415 \   0b"   Warning  Failed     11s   kubelet            Error: ImagePullBackOff Using Public Image Registries Whenever a Pod is created, the container runtime engine will download the declared container image from a container registry if it isn’t available locally yet.


The prefix in the image name declares the domain name of the registry; e.g., gcr.io/ google-containers/debian-base:v1.0.1  refers to the container image google- containers/debian-base:v1.0.1  in the Google Cloud container registry , denoted by gcr.io .


The container runtime will try to resolve it from docker.io , the Docker Hub container registry  if you leave off the domain name in the container image declaration.


Scenario: An Attacker Uploads a Malicious Container Image While it is convenient to resolve container images from public container registries, it doesn’t come without risks.


Any container referencing the container image from that registry will automatically run the malicious code.


An attacker uploads a malicious container image On an enterprise level, you need to control which container registries you trust.


Any consumer of container images should only be allowed to pull images from your whitelisted container registry.


An OPA Gatekeeper constraint template for enforcing container registries apiVersion : templates.gatekeeper.sh/v1 kind: ConstraintTemplate metadata :   name: k8sallowedrepos   annotations :     metadata.gatekeeper.sh/title : "Allowed  Repositories"     metadata.gatekeeper.sh/version : 1.0.0     description : >-       Requires container images to begin with a string from the specified list. spec:   crd:     spec:       names:         kind: K8sAllowedRepos       validation :         openAPIV3Schema :           type: object           properties :             repos:               description : The list of prefixes a container image is allowed to have.               type: array               items:                 type: string   targets:     - target: admission.k8s.gatekeeper.sh       rego: |         package k8sallowedrepos         violation[{"msg": msg}] {           container := input.review.object.spec.containers[_]           satisfied := [good | repo = input.parameters.repos[_] ; \           good = startswith(container.image, repo)]           not any(satisfied)           msg := sprintf("container <%v> has an invalid image repo <%v>, allowed \           repos are %v", [container.name, container.image, input.parameters.repos])         }         violation[{"msg": msg}] {           container := input.review.object.spec.initContainers[_]           satisfied := [good | repo = input.parameters.repos[_] ; \           good = startswith(container.image, repo)]           not any(satisfied)           msg := sprintf("initContainer <%v> has an invalid image repo <%v>, \           allowed repos are %v", [container.name, container.image, \           input.parameters.repos])         } 124 | Chapter 6: Supply Chain Security          violation[{"msg": msg}] {           container := input.review.object.spec.ephemeralContainers[_]           satisfied := [good | repo = input.parameters.repos[_] ; \           good = startswith(container.image, repo)]           not any(satisfied)           msg := sprintf("ephemeralContainer <%v> has an invalid image repo <%v>, \           allowed repos are %v", [container.name, container.image, \           input.parameters.repos])         } The constraint shown in Example 6-8  is in charge of defining which container registries we want to allow.


The following command tries to create a Pod using the nginx  container image from Docker Hub.


The creation of the Pod is denied with an appropriate error message: $ kubectl run nginx --image=nginx:1.23.3 Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" \ denied the request: [repo-is-gcr] container <nginx> has an invalid image \ repo <nginx:1.23.3>, allowed repos are ["gcr.io/"] Securing the Supply Chain | 125  The next command creates a Pod with a container image from the Google Cloud container registry.


The operation is permitted and the Pod object is created: $ kubectl run busybox --image=gcr.io/google-containers/busybox:1.27.2 pod/busybox created $ kubectl get pods NAME      READY   STATUS      RESTARTS     AGE busybox   0/1     Completed   1 (2s ago)   3s Whitelisting Allowed Image Registries with the ImagePolicyWebhook Admission Controller Plugin Another way to validate the use of allowed image registries is to intercept a call to the API server when a Pod is about to be created.


As you can see from the JSON response, the image is denied: $ curl -X POST -H "Content-Type: application/json" -k -d \'{"apiVersion":  \ "imagepolicy.k8s.io/v1alpha1", "kind": "ImageReview", "spec":  \ {"containers": [{"image": "nginx:1.19.0"}]}}' https://localhost:8080/validate {"apiVersion": "imagepolicy.k8s.io/v1alpha1", "kind": "ImageReview", \ "status": {"allowed": false, "reason": "Denied request: [container 1 \ has an invalid image repo nginx:1.19.0, allowed repos are [gcr.io/]]"}} The following curl  command calls the validation logic for the container image gcr.io/nginx:1.19.0 .


The image policy configuration  file apiVersion : v1 kind: Config preferences : {} clusters :   - name: image-validation-webhook     cluster:       certificate-authority : /etc/kubernetes/admission-control/ca.crt       server: https://image-validation-webhook:8080/validate   contexts : - context:     cluster: image-validation-webhook     user: api-server-client   name: image-validation-webhook current-context : image-validation-webhook users:   - name: api-server-client     user:       client-certificate : /etc/kubernetes/admission-control/api-server-client.crt       client-key : /etc/kubernetes/admission-control/api-server-client.key 128 | Chapter 6: Supply Chain Security  The URL to the backend service.


The API server configuration  file ... spec:   containers :   - command:     - kube-apiserver     - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook     - --admission-control-config-file=/etc/kubernetes/admission-control/ \       image-policy-webhook-admission-configuration.yaml     ...     volumeMounts :     ...     - name: admission-control       mountPath : /etc/kubernetes/admission-control       readonly : true   volumes:   ...   - name: admission-control     hostPath :       path: /etc/kubernetes/admission-control       type: DirectoryOrCreate ...


WARNING: NOT PRODUCTION \                      READY"         },         {           "selector": "containers[] .resources .requests .cpu",           "reason": "Enforcing CPU requests aids a fair balancing of \                      resources across the cluster"         },         {           "selector": ".metadata .annotations .\"container.seccomp.security. \                        alpha.kubernetes.io/pod\"",           "reason": "Seccomp profiles set minimum privilege and secure against \                      unknown threats"         },         {           "selector": "containers[] .resources .limits .memory",           "reason": "Enforcing memory limits prevents DOS via resource \                      exhaustion"         },         { 132 | Chapter 6: Supply Chain Security            "selector": "containers[] .resources .limits .cpu",           "reason": "Enforcing CPU limits prevents DOS via resource exhaustion"         },         {           "selector": "containers[] .securityContext .runAsNonRoot == true",           "reason": "Force the running image to run as a non-root user to \                      ensure least privilege"         },         {           "selector": "containers[] .resources .requests .memory",           "reason": "Enforcing memory requests aids a fair balancing of \                      resources across the cluster"         },         {           "selector": "containers[] .securityContext .capabilities .drop",           "reason": "Reducing kernel capabilities available to a container \                      limits its attack surface"         },         {           "selector": "containers[] .securityContext .runAsUser -gt 10000",           "reason": "Run as a high-UID user to avoid conflicts with the \                      host's user table"         },         {           "selector": "containers[] .securityContext .capabilities .drop | \                        index(\"ALL\")",           "reason": "Drop all capabilities and add only those required to \                      reduce syscall attack surface"         }       ]     }   } ] A touched-up version of the original YAML manifest can be found in Example 6-15 .


A Pod YAML manifest using improved security settings apiVersion : v1 kind: Pod metadata :   name: kubesec-demo spec:   containers :   - name: kubesec-demo     image: gcr.io/google-samples/node-hello:1.0     resources :       requests :         memory: "64Mi"         cpu: "250m"       limits: Static Analysis of Workload | 133          memory: "128Mi"         cpu: "500m"     securityContext :       readOnlyRootFilesystem : true       runAsNonRoot : true       runAsUser : 20000       capabilities :         drop: ["ALL"] Executing the same Docker command against the changed Pod YAML manifest will render an improved score and reduce the number of advised messages: $ docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin  \   < pod-improved-kubesec-test.yaml [   {     "object": "Pod/kubesec-demo.default",     "valid": true,     "message": "Passed with a score of 9 points",     "score": 9,     "scoring": {       "advise": [         {           "selector": ".metadata .annotations .\"container.seccomp.security. \                        alpha.kubernetes.io/pod\"",           "reason": "Seccomp profiles set minimum privilege and secure against \                      unknown threats"         },         {           "selector": ".spec .serviceAccountName",           "reason": "Service accounts restrict Kubernetes API access and should \                      be configured with least privilege"         },         {           "selector": ".metadata .annotations .\"container.apparmor.security. \                        beta.kubernetes.io/nginx\"",           "reason": "Well defined AppArmor policies may provide greater \                      protection from unknown threats.


When consuming the container image in a Pod, make sure to only pull the container image from a trusted registry.


Given that you can’t modify the container image easily, you will likely be asked to flag Pods that run container images with known vulnerabilities.


Create another Pod using the container image busybox:1.27.2 .


3.Define a Pod using the container image nginx:1.23.3-alpine  in the YAML 3. manifest pod-validate-image.yaml .


Retrieve the digest of the container image from Docker Hub.


Validate the container image contents using the SHA256 hash.


Kubernetes should be able to successfully pull the container image.


_Chapter length: 7360 words; sentences considered: 315._


---

## CHAPTER 7

**Monitoring, Logging, and Runtime Security**


### Extractive Summary


Understanding Falco Falco helps with detecting threats by observing host- and container-level activity.


Here are a few examples of events Falco could watch for: 142 | Chapter 7: Monitoring, Logging, and Runtime Security  •Reading or writing files at specific locations in the filesystem• •Opening a shell binary for a container, such as /bin/bash  to open a bash shell • •An attempt to make a network call to undesired URLs• Falco deploys a set of sensors that listen for the configured events and conditions.


First, you need to trust the Falco GPG key, configure the Falco-specific apt repository, and update the package list: $ curl -s https://falco.org/repo/falcosecurity-packages.asc | apt-key add - $ echo "deb https://download.falco.org/packages/deb stable main" | tee -a  \   /etc/apt/sources.list.d/falcosecurity.list $ apt-get update -y Y ou then install the kernel header with the following command: $ apt-get -y install linux-headers-$(uname -r) Last, you need to install the Falco apt package with version 0.33.1: $ apt-get install -y falco=0.33.1 Falco has been installed successfully and is running as a systemd service in the background.


Run the following command to check on the status of the Falco service: $ sudo systemctl status falco ● falco.service - Falco: Container Native Runtime Security      Loaded: loaded (/lib/systemd/system/falco.service; enabled; vendor preset: \              enabled)      Active: active (running) since Tue 2023-01-24 15:42:31 UTC; 43min ago        Docs: https://falco.org/docs/    Main PID: 8718 (falco)       Tasks: 12 (limit: 1131)      Memory: 30.2M      CGroup: /system.slice/falco.service              └─8718 /usr/bin/falco --pidfile=/var/run/falco.pid The Falco service should be in the “active” status.


Configuring  Falco The Falco service provides an operational environment for monitoring the system with a set of default rules.


The list of files and subdirectories in /etc/falco  is as follows: $ tree /etc/falco /etc/falco ├── aws_cloudtrail_rules.yaml ├── falco.yaml ├── falco_rules.local.yaml ├── falco_rules.yaml ├── k8s_audit_rules.yaml ├── rules.available │   └── application_rules.yaml └── rules.d 144 | Chapter 7: Monitoring, Logging, and Runtime Security  Of those files, I want to describe the high-level purpose of the most important ones.


Falco configuration  file The file named falco.yaml  is the configuration file for the Falco process.


Kubernetes-specific  rules The file k8s_audit_rules.yaml  defines Kubernetes-specific rules  in addition to log‐ ging system call events.


Y ou need to restart the Falco service, as demonstrated by the following command: $ sudo systemctl restart falco Next up, we’ll trigger some of the events covered by Falco’s default rules.


Performing Behavior Analytics | 145  Generating Events and Inspecting Falco Logs Let’s see Falco alerts in action.


To achieve that, create a new Pod named nginx , open a bash shell to the container, and then exit out of the container: $ kubectl run nginx --image=nginx:1.23.3 pod/nginx created $ kubectl exec -it nginx -- bash root@nginx:/# exit Identify the cluster node the Pod runs on by inspecting its runtime details: $ kubectl get pod nginx -o jsonpath='{.spec.nodeName}' kube-worker-1 This Pod is running on the cluster node named kube-worker-1 .


Jan 24 18:03:37 kube-worker-1 falco[8718]: 18:03:14.632368639: Notice A shell \ was spawned in a container with an attached terminal (user=root user_loginuid=0 \ nginx (id=18b247adb3ca) shell=bash parent=runc cmdline=bash pid=47773 \ terminal=34816 container_id=18b247adb3ca image=docker.io/library/nginx) Y ou will find that additional rules will kick in if you try to modify the container state.


Say you’ d installed the Git package using apt in the nginx  container: root@nginx:/# apt update root@nginx:/# apt install git Falco added log entries for those system-level operations.


The following output renders the alerts: $ sudo journalctl -fu falco Jan 24 18:55:48 ubuntu-focal falco[8718]: 18:55:05.173895727: Error Package \ management process launched in container (user=root user_loginuid=0 \ command=apt update pid=60538 container_id=18b247adb3ca container_name=nginx \ image=docker.io/library/nginx:1.23.3) Jan 24 18:55:48 ubuntu-focal falco[8718]: 18:55:11.050925982: Error Package \ management process launched in container (user=root user_loginuid=0 \ command=apt install git-all pid=60823 container_id=18b247adb3ca \ container_name=nginx image=docker.io/library/nginx:1.23.3) ...


146 | Chapter 7: Monitoring, Logging, and Runtime Security  Understanding Falco Rule File Basics A Falco rules file usually consists of three elements defined in YAML: rules, macros, and lists.


Crafting your own Falco rules During the exam, you will likely not have to craft your own Falco rules.


A Falco rule that monitors camera access - rule: access_camera   desc: a process other than skype/webex tries to access the camera   condition : evt.type = open and fd.name = /dev/video0 and not proc.name in \              (skype, webex)   output: Unexpected process opening camera video device (command=%proc.cmdline)   priority : WARNING Macro A macro  is a reusable rule condition that helps with avoiding copy-pasting similar logic across multiple rules.


A Falco macro that uses a list - macro: camera_process_access   condition : evt.type = open and fd.name = /dev/video0 and not proc.name in \              (video_conferencing_software) Dissecting an existing rule The reason why Falco ships with default rules is to shorten the timespan to hit the ground running for a production cluster.


The rules file /etc/falco/falco_rules.yaml  shipped with it contains a rule named “Terminal shell in container. ” It observes the event of opening a shell to a container.


A Falco rule that monitors shell activity to a container - macro: spawned_process     condition : (evt.type in (execve, execveat) and evt.dir=<) - macro: container     condition : (container.id != host) - macro: container_entrypoint     condition : (not proc.pname exists or proc.pname in (runc:[0:PARENT], \               runc:[1:CHILD], runc, docker-runc, exe, docker-runc-cur)) - macro: user_expected_terminal_shell_in_container_conditions     condition : (never_true) - rule: Terminal shell in container     desc: A shell was used as the entrypoint/exec point into a container with an \         attached terminal.   condition : >      spawned_process and container     and shell_procs and proc.tty != 0     and container_entrypoint     and not user_expected_terminal_shell_in_container_conditions   output: >      A shell was spawned in a container with an attached terminal (user=%user.name \     user_loginuid=%user.loginuid %container.info     shell=%proc.name parent=%proc.pname cmdline=%proc.cmdline pid=%proc.pid \     terminal=%proc.tty container_id=%container.id image=%container.image.repository)   priority : NOTICE    tags: [container , shell, mitre_execution ]  Defines a macro, a condition reusable across multiple rules referenced by name.


Performing Behavior Analytics | 149  Overriding Existing Rules Instead of modifying the rule definition directly in /etc/falco/falco_rules.yaml , I’ d suggest you redefine the rule in /etc/falco/falco_rules.local.yaml .


The modified  rule that monitors shell activity to a container - rule: Terminal shell in container   desc: A shell was used as the entrypoint/exec point into a container with an \         attached terminal.   condition : >     spawned_process and container     and shell_procs and proc.tty != 0     and container_entrypoint     and not user_expected_terminal_shell_in_container_conditions   output: >     Opened shell: %evt.time,%user.name,%container.name    priority : ALERT    tags: [container , shell, mitre_execution ] Simplifies the log output rendered for a violation.


Restart the Falco service with the following command: $ sudo systemctl restart falco As a result, any attempt that shells into a container will be logged with a different output format and priority, as the following shows: $ sudo journalctl -fu falco ...


Jan 24 21:19:13 kube-worker-1 falco[100017]: 21:19:13.961970887: Alert Opened \ shell: 21:19:13.961970887,<NA>,nginx In addition to overriding existing Falco rules, you can also define your own custom rules in /etc/falco/falco_rules.local.yaml .


Configuring  a Read-Only Container Root Filesystem Another aspect of container immutability is to prevent write access to the container’s filesystem.


A container disallowing write access to the root filesystem apiVersion : v1 kind: Pod metadata :   name: nginx spec:   containers :   - name: nginx     image: nginx:1.21.6     securityContext :       readOnlyRootFilesystem : true     volumeMounts :     - name: nginx-run       mountPath : /var/run     - name: nginx-cache       mountPath : /var/cache/nginx     - name: nginx-data       mountPath : /usr/local/nginx   volumes:   - name: nginx-run     emptyDir : {}   - name: nginx-data     emptyDir : {}   - name: nginx-cache     emptyDir : {} Identify the filesystem read/write requirements of your application before creating a Pod.


The audit backend  is responsible for storing the recorded audit events, as defined by the audit policy.


The high-level audit log architecture Let’s have a deeper look at the audit policy file and its configuration options.


Creating the Audit Policy File The audit policy file is effectively a YAML manifest for a Policy  resource.


Using Audit Logs to Monitor Access | 155  Example 7-9  shows an exemplary audit policy.


Contents of an audit policy file apiVersion : audit.k8s.io/v1 kind: Policy omitStages :   - "RequestReceived"   rules:   - level: RequestResponse       resources :     - group: ""       resources : ["pods"]   - level: Metadata       resources :     - group: ""       resources : ["pods/log" , "pods/status" ] Prevents generating logs for all requests in the RequestReceived  stage Logs Pod changes at RequestResponse  level Logs specialized Pod events, e.g., log and status requests, at the Metadata  level The previous audit policy isn’t very extensive but should give you an impression of its format.


Add the flag --audit-policy-file  to the API server process in the file /etc/ kubernetes/manifests/kube-apiserver.yaml .


Configuring  a Log Backend To set up a file-based log backend, you will need to add three pieces of configuration to the file /etc/kubernetes/manifests/kube-apiserver.yaml .


The following list summarizes the configuration: 1.Provide two flags to the API server process: the flag --audit-policy-file  points 1. to the audit policy file; the flag --audit-log-path  points to the log output file.


156 | Chapter 7: Monitoring, Logging, and Runtime Security  2.Add a Volume mountpath for the audit log policy file and the log output2. directory.


Configuring  the audit policy file and audit log file ... spec:   containers :   - command:     - kube-apiserver     - --audit-policy-file=/etc/kubernetes/audit-policy.yaml       - --audit-log-path=/var/log/kubernetes/audit/audit.log       ...     volumeMounts :     - mountPath : /etc/kubernetes/audit-policy.yaml         name: audit       readOnly : true     - mountPath : /var/log/kubernetes/audit/         name: audit-log       readOnly : false   ...   volumes:   - name: audit      hostPath :       path: /etc/kubernetes/audit-policy.yaml       type: File   - name: audit-log       hostPath :       path: /var/log/kubernetes/audit/       type: DirectoryOrCreate Provides the location of the policy file and log file to the API server process.


Defines the Volumes for the policy file and the audit log directory.


The following kubectl  command sends a request to the API server for creating a Pod named nginx : $ kubectl run nginx --image=nginx:1.21.6 pod/nginx created In the previous step, we configured the audit log file at /var/log/kubernetes/audit/ audit.log .


The following command finds relevant log entries, one for the RequestResponse  level, and another for the Metadata  level: $ sudo grep 'audit.k8s.io/v1' /var/log/kubernetes/audit/audit.log ... {"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"RequestResponse", \ "auditID":"285f4b99-951e-405b-b5de-6b66295074f4","stage":"ResponseComplete", \ "requestURI":"/api/v1/namespaces/default/pods/nginx","verb":"get", \ "user":{"username":"system:node:node01","groups":["system:nodes", \ "system:authenticated"]},"sourceIPs":["172.28.116.6"],"userAgent": \ "kubelet/v1.26.0 (linux/amd64) kubernetes/b46a3f8","objectRef": \ {"resource":"pods","namespace":"default","name":"nginx","apiVersion":"v1"}, \ "responseStatus":{"metadata":{},"code":200},"responseObject":{"kind":"Pod", \ "apiVersion":"v1","metadata":{"name":"nginx","namespace":"default", \ ... {"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Metadata","auditID": \ "5c8e5ecc-0ce0-49e0-8ab2-368284f2f785","stage":"ResponseComplete", \ "requestURI":"/api/v1/namespaces/default/pods/nginx/status","verb":"patch", \ "user":{"username":"system:node:node01","groups":["system:nodes", \ "system:authenticated"]},"sourceIPs":["172.28.116.6"],"userAgent": \ "kubelet/v1.26.0 (linux/amd64) kubernetes/b46a3f8","objectRef": \ {"resource":"pods","namespace":"default","name":"nginx","apiVersion":"v1", \ "subresource":"status"},"responseStatus":{"metadata":{},"code":200}, \ ...


Add the flag --audit-webhook-config-file  to the API server process in the file /etc/kubernetes/manifests/kube-apiserver.yaml , and point it to the location of the kubeconfig file.


Y ou will still have to assign the flag --audit-policy-file  to point to the audit policy file.


Reconfigure Falco to write logs to the file at /var/logs/falco.log .


Ensure that Falco appends new messages to the log file.


Edit the existing audit policy file at /etc/kubernetes/audit/rules/audit- policy.yaml .


Logs should be written to the file /var/log/kubernetes/audit/logs/apiserver.log .


_Chapter length: 5865 words; sentences considered: 276._


---

## Chapter 2, “Cluster Setup”

**1.Create a file with the name deny-egress-external.yaml  for defining the net‐ 1.**


### Extractive Summary


The namespace selector for the egress policy needs to use {} to select all namespaces: apiVersion : networking.k8s.io/v1 kind: NetworkPolicy metadata :   name: deny-egress-external spec:   podSelector :     matchLabels :       app: backend   policyTypes :   - Egress   egress:   - to:     - namespaceSelector : {}     ports:     - port: 53       protocol : UDP     - port: 53       protocol : TCP Run the apply  command to instantiate the network policy object from the YAML file: $ kubectl apply -f deny-egress-external.yaml 161  2.A Pod that does not match the label selection of the network policy can make2. a call to a URL outside of the cluster.


In this case, the label assignment is app=frontend : $ kubectl run web --image=busybox:1.36.0 -l app=frontend --port=80 -it  \   --rm --restart=Never -- wget http://google.com --timeout=5 --tries=1 Connecting to google.com (142.250.69.238:80) Connecting to www.google.com (142.250.72.4:80) saving to /'index.html' index.html           100% |**| 13987 \ 0:00:00 ETA /'index.html' saved pod "web" deleted 3.A Pod that does match the label selection of the network policy cannot make3. a call to a URL outside of the cluster.


In this case, the label assignment is app=backend : $ kubectl run web --image=busybox:1.36.0 -l app=backend --port=80 -it  \   --rm --restart=Never -- wget http://google.com --timeout=5 --tries=1 wget: download timed out pod "web" deleted pod default/web terminated (Error) 4.First, see if the Dashboard is already installed.


Dashboard usually creates: $ kubectl get ns kubernetes-dashboard NAME                   STATUS   AGE kubernetes-dashboard   Active   109s If the namespace does not exist, you can assume that the Dashboard has not been installed yet.


The following YAML manifest has been saved in the file dashboard-observer-user.yaml : apiVersion : v1 kind: ServiceAccount metadata :   name: observer-user   namespace : kubernetes-dashboard --- apiVersion : rbac.authorization.k8s.io/v1 kind: ClusterRole metadata :   annotations :     rbac.authorization.kubernetes.io/autoupdate : "true" 162 | Answers to Review Questions    name: cluster-observer rules: - apiGroups :   - 'apps'   resources :   - 'deployments'   verbs:   - list --- apiVersion : rbac.authorization.k8s.io/v1 kind: ClusterRoleBinding metadata :   name: observer-user roleRef:   apiGroup : rbac.authorization.k8s.io   kind: ClusterRole   name: cluster-observer subjects : - kind: ServiceAccount   name: observer-user   namespace : kubernetes-dashboard Create the objects with the following command: $ kubectl apply -f dashboard-observer-user.yaml 5.Run the following command to create a token for the ServiceAccount.


Run the proxy command and open the link http://localhost:8001/api/v1/namespa ces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy  in a browser: $ kubectl proxy Select the “Token” authentication method and paste the token you copied before.


_Chapter length: 642 words; sentences considered: 21._


---

## Chapter 3, “Cluster Hardening”

**1.Create a private key using the openssl  executable. Provide an expressive file 1.**


### Extractive Summary


The user does not have the appropriate permissions: $ kubectl get nodes Error from server (Forbidden): nodes is forbidden: User "jill" cannot \ list resource "nodes" in API group "" at the cluster scope Switch back to the admin context: $ kubectl config use-context minikube 4.Create the namespace t23: 4. $ kubectl create namespace t23 Create the service account api-call  in the namespace: $ kubectl create serviceaccount api-call -n t23 Define a YAML manifest file with the name pod.yaml .


The contents of the file define a Pod that makes an HTTPS GET call to the API server to retrieve the list of Services in the default  namespace: apiVersion : v1 kind: Pod metadata :   name: service-list   namespace : t23 spec:   serviceAccountName : api-call   containers :   - name: service-list     image: alpine/curl:3.14     command: ['sh', '-c', 'while true; do curl -s -k -m 5 \               -H "Authorization:  Bearer $(cat /var/run/secrets/\               kubernetes.io/serviceaccount/token)"  https://kubernetes.\               default.svc.cluster.local/api/v1/namespaces/default/\               services;  sleep 10; done'] Create the Pod with the following command: $ kubectl apply -f pod.yaml Check the logs of the Pod.


The API call is not authorized, as shown in the following log output: $ kubectl logs service-list -n t23 { 166 | Answers to Review Questions    "kind": "Status",   "apiVersion": "v1",   "metadata": {},   "status": "Failure",   "message": "services is forbidden: User \"system:serviceaccount:t23 \               :api-call\" cannot list resource \"services\" in API \               group \"\" in the namespace \"default\"",   "reason": "Forbidden",   "details": {     "kind": "services"   },   "code": 403 } 5.Create the YAML manifest in the file clusterrole.yaml , as shown in the 5. following: apiVersion : rbac.authorization.k8s.io/v1 kind: ClusterRole metadata :   name: list-services-clusterrole rules: - apiGroups : [""]   resources : ["services" ]   verbs: ["list"] Reference the ClusterRole in a RoleBinding defined in the file rolebind ing.yaml .


The subject should list the service account api-call  in the namespace t23: apiVersion : rbac.authorization.k8s.io/v1 kind: RoleBinding metadata :   name: serviceaccount-service-rolebinding subjects : - kind: ServiceAccount   name: api-call   namespace : t23 roleRef:   kind: ClusterRole   name: list-services-clusterrole   apiGroup : rbac.authorization.k8s.io Create both objects from the YAML manifests: $ kubectl apply -f clusterrole.yaml $ kubectl apply -f rolebinding.yaml The API call running inside of the container should now be authorized and be allowed to list the Service objects in the default  namespace.


Open an interactive shell to the control plane node using Vagrant: $ vagrant ssh kube-control-plane Upgrade kubeadm  to version 1.26.1 and apply it: $ sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get  \   install -y kubeadm=1.26.1-00 && sudo apt-mark hold kubeadm $ sudo kubeadm upgrade apply v1.26.1 Drain the node, upgrade the kubelet and kubectl , restart the kubelet, and uncor‐ don the node: $ kubectl drain kube-control-plane --ignore-daemonsets $ sudo apt-get update && sudo apt-get install -y  \   --allow-change-held-packages kubelet=1.26.1-00 kubectl=1.26.1-00 $ sudo systemctl daemon-reload $ sudo systemctl restart kubelet $ kubectl uncordon kube-control-plane The version of the node should now say v1.26.1.


Repeat all of the following steps for the worker node: $ vagrant ssh kube-worker-1 Upgrade kubeadm  to version 1.26.1 and apply it to the node: $ sudo apt-get update && sudo apt-get install -y  \   --allow-change-held-packages kubeadm=1.26.1-00 $ sudo kubeadm upgrade node Drain the node, upgrade the kubelet and kubectl , restart the kubelet, and uncor‐ don the node: $ kubectl drain kube-worker-1 --ignore-daemonsets $ sudo apt-get update && sudo apt-get install -y  \   --allow-change-held-packages kubelet=1.26.1-00 kubectl=1.26.1-00 $ sudo systemctl daemon-reload $ sudo systemctl restart kubelet $ kubectl uncordon kube-worker-1 The version of the node should now say v1.26.1.


_Chapter length: 1183 words; sentences considered: 23._


---

## Chapter 4, “System Hardening”

**1.Shell into the worker node with the following command:1.**


### Extractive Summary


The command that exposes the port is vsftpd : $ sudo lsof -i :21 COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME vsftpd  10178 root    3u  IPv6  56850      0t0  TCP *:ftp (LISTEN) Alternatively, you could also use the ss command, as shown in the following: $ sudo ss -at -pn '( dport = :21 or sport = :21 )' State   Recv-Q   Send-Q   Local Address:Port \    Peer Address:Port   Process LISTEN  0   32   *:21 \    *:*   users:(("vsftpd",pid=10178,fd=3)) The process vsftpd  has been started as a service: $ sudo systemctl status vsftpd ● vsftpd.service - vsftpd FTP server      Loaded: loaded (/lib/systemd/system/vsftpd.service; enabled; \              vendor preset: enabled)      Active: active (running) since Thu 2022-10-06 14:39:12 UTC; \ 170 | Answers to Review Questions               11min ago    Main PID: 10178 (vsftpd)       Tasks: 1 (limit: 1131)      Memory: 604.0K      CGroup: /system.slice/vsftpd.service              └─10178 /usr/sbin/vsftpd /etc/vsftpd.conf Oct 06 14:39:12 kube-worker-1 systemd[1]: Starting vsftpd FTP server...


Write the definition of the Pod to a file: $ kubectl get pod -o yaml > pod.yaml $ kubectl delete pod network-call Edit the pod.yaml  file to add the AppArmor annotation.


The final content could look as follows after a little bit of cleanup: apiVersion : v1 kind: Pod metadata :   name: network-call   annotations :     container.apparmor.security.beta.kubernetes.io/network-call : \     localhost/network-deny spec:   containers :   - name: network-call     image: alpine/curl:3.14     command: ["sh", "-c", "while true; do ping -c 1 google.com;  \               sleep 5; done"] Create the Pod from the manifest.


After a couple of seconds, the Pod should transition into the “Running” status: $ kubectl create -f pod.yaml $ kubectl get pod network-call NAME           READY   STATUS    RESTARTS   AGE network-call   1/1     Running   0          27s AppArmor prevents the Pod from making a network call.


Write the definition of the Pod to a file: 172 | Answers to Review Questions  $ kubectl get pod -o yaml > pod.yaml $ kubectl delete pod network-call Edit the pod.yaml  file.


After a couple of seconds, the Pod should transition into the “Running” status: $ kubectl create -f pod.yaml $ kubectl get pod network-call NAME           READY   STATUS    RESTARTS   AGE network-call   1/1     Running   0          27s Y ou should be able to find log entries for syscalls, e.g., for the sleep  command: $ sudo cat /var/log/syslog Oct  6 16:25:06 ubuntu-focal kernel: [ 2114.894122] audit: type=1326 \ audit(1665073506.099:23761): auid=4294967295 uid=0 gid=0 \ ses=4294967295 pid=19226 comm="sleep" exe="/bin/busybox" \ sig=0 arch=c000003e syscall=231 compat=0 ip=0x7fc026adbf0b \ code=0x7ffc0000 Exit out of the node: $ exit Create the Pod definition in the file pod.yaml : apiVersion : v1 kind: Pod metadata :   name: sysctl-pod spec:   securityContext :     sysctls:     - name: net.core.somaxconn Answers to Review Questions | 173        value: "1024"     - name: debug.iotrace       value: "1"   containers :   - name: nginx     image: nginx:1.23.1 Create the Pod and then check on the status.


_Chapter length: 898 words; sentences considered: 20._


---

## Chapter 5, “Minimize Microservice Vulnerabilities”

**1.Define the Pod with the security settings in the file busybox-security- 1.**


### Extractive Summary


Y ou can find the content of the following YAML manifest: apiVersion : v1 kind: Pod metadata :   name: busybox-security-context spec:   securityContext :     runAsUser : 1000     runAsGroup : 3000     fsGroup: 2000   volumes:   - name: vol     emptyDir : {}   containers :   - name: busybox     image: busybox:1.28     command: ["sh", "-c", "sleep 1h"]     volumeMounts :     - name: vol 174 | Answers to Review Questions        mountPath : /data/test     securityContext :       allowPrivilegeEscalation : false Create the Pod with the following command: $ kubectl apply -f busybox-security-context.yaml $ kubectl get pod busybox-security-context NAME                       READY   STATUS    RESTARTS   AGE busybox-security-context   1/1     Running   0          54s Shell into the container and create the file.


PSA label with baseline  level and the warn  mode: apiVersion : v1 kind: Namespace metadata :   name: audited   labels:     pod-security.kubernetes.io/warn : baseline Create the namespace from the YAML manifest: $ kubectl apply -f psa-namespace.yaml Y ou can produce an error by using the following Pod configuration in the file psa-pod.yaml .


Y ou can prevent the creation of the Pod by configuring the PSA with the restricted  level: $ kubectl apply -f psa-pod.yaml Warning: would violate PodSecurity "baseline:latest": host namespaces \ (hostNetwork=true) pod/busybox created $ kubectl get pod busybox -n audited NAME      READY   STATUS    RESTARTS   AGE busybox   1/1     Running   0          2m21s 3.Y ou can install Gatekeeper with the following command:3. $ kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/ \ gatekeeper/master/deploy/gatekeeper.yaml The Gatekeeper library describes a ConstraintTemplate for defining replica lim‐ its.


Apply the manifest with the following command: $ kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/ \ gatekeeper-library/master/library/general/replicalimits/template.yaml Now, define the Constraint with the YAML manifest in the file named replica- limits-constraint.yaml : apiVersion : constraints.gatekeeper.sh/v1beta1 kind: K8sReplicaLimits metadata :   name: replica-limits spec:   match:     kinds:       - apiGroups : ["apps"]         kinds: ["Deployment" ]   parameters :     ranges:     - min_replicas : 3       max_replicas : 10 Create the Constraint with the following command: $ kubectl apply -f replica-limits-constraint.yaml Y ou can see that a Deployment can only be created if the provided number of replicas falls within the range of the Constraint: $ kubectl create deployment nginx --image=nginx:1.23.2 --replicas=15 error: failed to create deployment: admission webhook \ "validation.gatekeeper.sh" denied the request: [replica-limits] \ The provided number of replicas is not allowed for deployment: nginx. \ Allowed ranges: {"ranges": [{"max_replicas": 10, "min_replicas": 3}]} 176 | Answers to Review Questions  $ kubectl create deployment nginx --image=nginx:1.23.2 --replicas=7 deployment.apps/nginx created 4.Configure encryption for etcd, as described in “Encrypting etcd Data”  on page 4.


The nginx Pod has been defined in the file pod.yaml : apiVersion : v1 kind: Pod metadata :   name: nginx spec:   runtimeClassName : container-runtime-sandbox   containers :   - name: nginx     image: nginx:1.23.2 Create the Pod object.


The Pod will transition into the status “Running”: $ kubectl apply -f pod.yaml $ kubectl get pod nginx NAME    READY   STATUS    RESTARTS   AGE nginx   1/1     Running   0          2m21s Exit out of the node: $ exit Answers to Review Questions | 177


_Chapter length: 737 words; sentences considered: 13._


---

## Chapter 6, “Supply Chain Security”

**1.The initial container image built with the provided Dockerfile has a size of1.**


### Extractive Summary


Make sure to assign the value Enforce  to the attribute spec.validationFailureAction : apiVersion : kyverno.io/v1 kind: ClusterPolicy metadata :   name: restrict-image-registries   annotations :     policies.kyverno.io/title : Restrict Image Registries     policies.kyverno.io/category : Best Practices, EKS Best Practices     policies.kyverno.io/severity : medium     policies.kyverno.io/minversion : 1.6.0     policies.kyverno.io/subject : Pod 178 | Answers to Review Questions      policies.kyverno.io/description : >-       Images from unknown, public registries can be of dubious quality \       and may not be scanned and secured, representing a high degree of \       risk.


Use of this policy requires \       customization to define your allowable registries. spec:   validationFailureAction : Enforce   background : true   rules:   - name: validate-registries     match:       any:       - resources :           kinds:           - Pod     validate :       message: "Unknown  image registry."       pattern:         spec:           containers :           - image: "gcr.io/*" Apply the manifest with the following command: $ kubectl apply -f restrict-image-registries.yaml Run the following commands to verify that the policy has become active.


Any container image definition that doesn’t use the prefix gcr.io/  will be denied: $ kubectl run nginx --image=nginx:1.23.3 Error from server: admission webhook "validate.kyverno.svc-fail" \ denied the request: policy Pod/default/nginx for resource violation: restrict-image-registries:   validate-registries: 'validation error: Unknown image registry. \   rule validate-registries     failed at path /spec/containers/0/image/' $ kubectl run busybox --image=gcr.io/google-containers/busybox:1.27.2 pod/busybox created 3.Find the SHA256 hash for the image nginx:1.23.3-alpine  with the search 3. functionality  of Docker Hub.


The result is the fol‐ lowing YAML manifest: Answers to Review Questions | 179  apiVersion : v1 kind: Pod metadata :   name: nginx spec:   containers :   - name: nginx     image: nginx@sha256:c1b9fe3c0c015486cf1e4a0ecabe78d05864475e279638 \            e9713eb55f013f907f The creation of the Pod should work: $ kubectl apply -f pod-validate-image.yaml pod/nginx created $ kubectl get pods nginx NAME    READY   STATUS    RESTARTS   AGE nginx   1/1     Running   0          29s If you modify the SHA256 hash in any form and try to recreate the Pod, then Kubernetes would not allow you to pull the image.


4.Running Kubesec in a Docker container results in a whole bunch of suggestions,4. as shown in the following output: $ docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < pod.yaml [   {     "object": "Pod/hello-world.default",     "valid": true,     "message": "Passed with a score of 0 points",     "score": 0,     "scoring": {       "advise": [         {           "selector": "containers[] .securityContext .capabilities \                        .drop | index(\"ALL\")",           "reason": "Drop all capabilities and add only those \                      required to reduce syscall attack surface"         },         {           "selector": "containers[] .resources .requests .cpu",           "reason": "Enforcing CPU requests aids a fair balancing \                      of resources across the cluster"         },         {           "selector": "containers[] .securityContext .runAsNonRoot \                        == true",           "reason": "Force the running image to run as a non-root \                      user to ensure least privilege"         },         {           "selector": "containers[] .resources .limits .cpu", 180 | Answers to Review Questions            "reason": "Enforcing CPU limits prevents DOS via resource \                      exhaustion"         },         {           "selector": "containers[] .securityContext .capabilities \                        .drop",           "reason": "Reducing kernel capabilities available to a \                      container limits its attack surface"         },         {           "selector": "containers[] .resources .requests .memory",           "reason": "Enforcing memory requests aids a fair balancing \                      of resources across the cluster"         },         {           "selector": "containers[] .resources .limits .memory",           "reason": "Enforcing memory limits prevents DOS via resource \                      exhaustion"         },         {           "selector": "containers[] .securityContext \                        .readOnlyRootFilesystem == true",           "reason": "An immutable root filesystem can prevent malicious \                      binaries being added to PATH and increase attack \                      cost"         },         {           "selector": ".metadata .annotations .\"container.seccomp. \                        security.alpha.kubernetes.io/pod\"",           "reason": "Seccomp profiles set minimum privilege and secure \                      against unknown threats"         },         {           "selector": ".metadata .annotations .\"container.apparmor. \                        security.beta.kubernetes.io/nginx\"",           "reason": "Well defined AppArmor policies may provide greater \                      protection from unknown threats.


WARNING: NOT \                      PRODUCTION READY"         },         {           "selector": "containers[] .securityContext .runAsUser -gt \                        10000",           "reason": "Run as a high-UID user to avoid conflicts with \                      the host's user table"         },         {           "selector": ".spec .serviceAccountName",           "reason": "Service accounts restrict Kubernetes API access \                      and should be configured with least privilege"         } Answers to Review Questions | 181        ]     }   } ] The fixed-up YAML manifest could look like this: apiVersion : v1 kind: Pod metadata :   name: hello-world spec:   serviceAccountName : default   containers :   - name: linux     image: hello-world:linux     resources :       requests :         memory: "64Mi"         cpu: "250m"       limits:         memory: "128Mi"         cpu: "500m"     securityContext :       readOnlyRootFilesystem : true       runAsNonRoot : true       runAsUser : 20000       capabilities :         drop: ["ALL"] 5.Executing the kubectl apply  command against the existing setup.yaml  mani‐ 5. fest will create the Pods named backend , loop , and logstash  in the namespace r61: $ kubectl apply -f setup.yaml namespace/r61 created pod/backend created pod/loop created pod/logstash created Y ou can check on them with the following command: $ kubectl get pods -n r61 NAME       READY   STATUS    RESTARTS   AGE backend    1/1     Running   0          115s logstash   1/1     Running   0          115s loop       1/1     Running   0          115s Check the images of each Pod in the namespace r61 using the kubectl describe command.


_Chapter length: 1193 words; sentences considered: 25._


---

## Chapter 7, “Monitoring, Logging, and Runtime Security”

**1.Shell into the worker node with the following command:1.**


### Extractive Summary


Find the rule that produces the message in /etc/falco/falco_rules.yaml  by searching for the string “etc opened for writing. ” The rule looks as follows: - rule: Write below etc   desc: an attempt to write to any file below /etc   condition : write_etc_common   output: "File below /etc opened for writing (user=%user.name  \            user_loginuid=%user.loginuid  command=%proc.cmdline  \            pid=%proc.pid  parent=%proc.pname  pcmdline=%proc.pcmdline  \            file=%fd.name  program=%proc.name  gparent=%proc.aname[2]  \            ggparent=%proc.aname[3]  gggparent=%proc.aname[4]  \            container_id=%container.id  image=%container.image.repository)"   priority : ERROR   tags: [filesystem , mitre_persistence ] Copy the rule to the file /etc/falco/falco_rules.local.yaml  and modify the output definition, as follows: - rule: Write below etc   desc: an attempt to write to any file below /etc   condition : write_etc_common   output: "%evt.time,%user.name,%container.id"   priority : ERROR   tags: [filesystem , mitre_persistence ] Restart the Falco service, and find the changed output in the Falco logs: $ sudo systemctl restart falco $ sudo journalctl -fu falco Jan 24 23:48:18 kube-worker-1 falco[17488]: 23:48:18.516903001: \ Error 23:48:18.516903001,<NA>,e72a6dbb63b8 ...


The resulting configuration will look like the following: file_output :   enabled: true   keep_alive : false   filename : /var/log/falco.log stdout_output :   enabled: false The log file will now append Falco log: 184 | Answers to Review Questions  $ sudo tail -f /var/log/falco.log 00:10:30.425084165: Error 00:10:30.425084165,<NA>,e72a6dbb63b8 ...


The command running 2. in its container appends a hash to a file at /var/config/hash.txt  in an infinite loop: $ kubectl apply -f setup.yaml pod/hash created $ kubectl get pod hash NAME   READY   STATUS    RESTARTS   AGE hash   1/1     Running   0          27s $ kubectl exec -it hash -- /bin/sh / # ls /var/config/hash.txt /var/config/hash.txt To make the container immutable, you will have to add configuration to the existing Pod definition.


The resulting YAML manifest could look as follows: apiVersion : v1 kind: Pod metadata :   name: hash spec:   containers :   - name: hash     image: alpine:3.17.1     securityContext :       readOnlyRootFilesystem : true     volumeMounts :     - name: hash-vol       mountPath : /var/config     command: ["sh", "-c", "if [ ! -d /var/config  ]; then mkdir -p \               /var/config;  fi; while true; do echo $RANDOM | md5sum \               | head -c 20 >> /var/config/hash.txt;  sleep 20; done"]   volumes:   - name: hash-vol     emptyDir : {} 3.Shell into the control plane node with the following command:3. $ vagrant ssh kube-control-plane Answers to Review Questions | 185  Edit the existing audit policy file at /etc/kubernetes/audit/rules/audit- policy.yaml .


The content of the final audit policy file could look as follows: apiVersion : audit.k8s.io/v1 kind: Policy omitStages :   - "RequestReceived" rules:   - level: RequestResponse     resources :     - group: ""       resources : ["pods"]   - level: Metadata     resources :     - group: ""       resources : ["secrets" , "configmaps" ]   - level: Request     resources :     - group: ""       resources : ["services" ] Configure the API server to consume the audit policy file by editing the file /etc/kubernetes/manifests/kube-apiserver.yaml .


The relevant configuration needed is as follows: ... spec:   containers :   - command:     - kube-apiserver     - --audit-policy-file=/etc/kubernetes/audit/rules/audit-policy.yaml     - --audit-log-path=/var/log/kubernetes/audit/logs/apiserver.log     - --audit-log-maxage=5     ...     volumeMounts :     - mountPath : /etc/kubernetes/audit/rules/audit-policy.yaml       name: audit       readOnly : true     - mountPath : /var/log/kubernetes/audit/logs/       name: audit-log       readOnly : false   ...   volumes:   - name: audit     hostPath :       path: /etc/kubernetes/audit/rules/audit-policy.yaml       type: File   - name: audit-log     hostPath : 186 | Answers to Review Questions        path: /var/log/kubernetes/audit/logs/       type: DirectoryOrCreate One of the logged resources is a ConfigMap on the Metadata  level.


The following command creates an exemplary ConfigMap object: $ kubectl create configmap db-user --from-literal=username=tom configmap/db-user created The audit log file will now contain an entry for the event: $ sudo cat /var/log/kubernetes/audit/logs/apiserver.log {"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Metadata", \ "auditID":"1fbb409a-3815-4da8-8a5e-d71c728b98b1","stage": \ "ResponseComplete","requestURI":"/api/v1/namespaces/default/configmaps? \ fieldManager=kubectl-create\u0026fieldValidation=Strict","verb": \ "create","user":{"username":"kubernetes-admin","groups": \ ["system:masters","system:authenticated"]},"sourceIPs": \ ["192.168.56.10"], "userAgent":"kubectl/v1.24.4 (linux/amd64) \ kubernetes/95ee5ab", "objectRef":{"resource":"configmaps", \ "namespace":"default", "name":"db-user","apiVersion":"v1"}, \ "responseStatus":{"metadata": {},"code":201}, \ "requestReceivedTimestamp":"2023-01-25T18:57:51.367219Z", \ "stageTimestamp":"2023-01-25T18:57:51.372094Z","annotations": \ {"authorization.k8s.io/decision":"allow", \ "authorization.k8s.io/reason":""}} Exit out of the VM: $ exit Answers to Review Questions | 187  Index A aa-complain command, 77 aa-enforce command, 77 aa-status command, 76 access monitoring using audit logs, 154-158 restricting to API Server, 48-59 adduser command, 69 administration privileges, creating users with, 33 admission control, as stage in request process‐ ing, 44 AKS Application Gateway Ingress Controller, 23 anonymous access, 46 answers to review questions behavior analytics, 183 cluster hardening, 164-170 cluster setup, 161-164 microservice vulnerabilities, 174-177 supply chain security, 178-183 system hardening, 170-174 API server connecting to, 44-47 restricting access to, 48-59 AppArmor, 7, 75-78 apply command, 56, 79, 125 apt purge command, 67 attack surface, reducing, 118 audit backend, 155 audit logs, 6, 154-158 audit mode, 93 audit policy, 155authentication, as stage in request processing, 44 authorization, as stage in request processing, 44 automounting, disabling for service account tokens, 57 B base images minimizing footprint for, 113-119 selecting, 114 baseline level, 93 behavior analytics answers to review questions, 183 defined, 141 ensuring container immutability, 151 performing, 142-150 sample exercises, 159 using audit logs to monitor access, 154-158 binaries, verifying against hash, 38 blog (Kubernetes), 7 Burns, Brendan, Managing Kubernetes, 43 C CA (certificate authority), 108 Calico, 108 calling Ingress, 28 candidate skills, 8 certificate approve command, 50 CertificateSigningRequest, creating and approving, 50 certification, learning path for, 1 Certified Kubernetes Administrator (CKA) Study Guide (Muschko), x, 8, 12, 22, 60, 99 chmod command, 73 189  chown command, 72 Cilium, 108 CIS (Center for Internet Security), 18 CIS benchmark, for Ubuntu Linux, 66 CKA (Certified Kubernetes Administrator), ix, 2 CKAD (Certified Kubernetes Application Developer), ix, 2 CKS (Certified Kubernetes Security Specialist), ix, 2 client certificates, access with, 46 cluster hardening, 43-63 about, 4, 43 answers to review questions, 164-170 interacting with Kubernetes API, 43-47 restricting access to API server, 48-59 sample exercises, 63 updating Kubernetes, 59-62 cluster setup, 11-41 about, 4, 11 answers to review questions, 161-164 applying Kubernetes component best secu‐ rity practices, 18-22 creating ingress with TLS termination, 22-28 protecting GUI elements, 31-37 protecting node metadata and endpoints, 28-31 restricting pod-to-pod communication using network policies, 11-18 sample exercises, 41 verifying Kubernetes platform binaries, 37 ClusterIP Service type, 31 ClusterRole, 35, 55 ClusterRoleBinding object, 33 CMD command, 118 CNCF (Cloud Native Computing Foundation), 3 CNI (Container Network Interface) plugin, 11 commands aa-complain, 77 aa-enforce, 77 aa-status, 76 adduser, 69 apply, 56, 79, 125 apt purge, 67 certificate approve, 50 chmod, 73 chown, 72CMD, 118 COPY, 118 create ingress, 26 create rolebinding, 51 create token, 58 curl, 46, 56, 127 disable, 67 docker build, 116 docker trust sign, 119 echo, 80 etcdctl, 100, 103 FROM, 118 get all, 24 go build, 117 groupadd, 71 groupdel, 71 journalctl, 146 kubectl, 96, 158 kubectl apply, 14 kubectl logs, 19 ls, 72 mkdir, 82 netstat, 73 OpenSSL, 25 RUN, 118 ss, 73 status, 66 su, 70 sudo, 70 sudo systemctl restart kubelet, 129 sysctl, 90 systemctl, 66 systemctl status, 74 touch, 72 usermod, 72 wget, 16 Complain profile mode, 76 component security best practices, applying, 18-22 ConfigMap, 151, 152 configuration file (Falco), 145 configuring containers with ConfigMap, 152 containers with Secrets, 152 Falco, 144 gVisor, 105 ImagePolicyWebhook Admission Controller plugin, 127-130 log backend, 156 190 | Index  ports for API server, 45 read-only container root filesystems, 153 webhook backend, 158 connecting to API server, 44-47 constraint template, 7, 96, 123 container images optimization tools for, 119 signing, 119 using a multi-stage approach for building, 116 validating, 120 container runtime sandboxes, 103-107 Container Security (Rice), 119 containerd, 79 containers applying custom profiles to, 81 applying profiles to, 77 configuring with ConfigMap or Secrets, 152 ensuring immutability, 151 using in privileged mode, 89 Continuous Delivery (Humble and Farley), 130 COPY command, 118 CRDs (Custom Resource Definitions), 7 create ingress command, 26 create rolebinding command, 51 create token command, 58 CSR (certificate signing request), 49, 108 curl command, 46, 56, 127 curriculum, 3 custom profiles applying to containers, 81 setting, 77, 80 custom rules, for Falco, 145 CVE (Common Vulnerabilities and Exposures) database, 59 CVE Details, 134 D default behavior, observing, 13 default container runtime profile, applying to containers, 79 default namespace, 14, 19, 52 default permissions, verifying, 54 default rules, for Falco, 145 Degioanni, Loris, Practical Cloud Native Secu‐ rity with Falco, 143 deny-all network policy, 16 deprecation policy (Kubernetes), 60 directional network traffic, 15disable command, 67 disabling automounting for service account tokens, 57 open ports, 73 distroless image, 115, 152 Dive, 119 docker build command, 116 Docker Engine, 79 Docker Hub, 114, 122 docker trust sign command, 119 Docker, multi-stage build in, 116 Dockerfiles, 114, 116, 130 DockerSlim, 119 documentation AWS, 30 Docker, 114 EKS, 48 Falco, 143, 147 GKE, 48 Kubernetes, x, 7, 12, 15, 22, 39, 44, 49, 54, 79, 99, 103, 108, 115, 127, 153, 156, 157 OpenSSL, 25 Trivy, 135 E echo command, 80 EKS (Amazon Elastic Kubernetes Service), 18 encrypting etcd data, 101 Pod-to-Pod, 107 endpoints, protecting, 28-31 enforce mode, 93 Enforce profile mode, 76 etcd data accessing, 100 encrypting, 101 etcdctl command, 100, 103 events, generating in Falco, 146 exam objectives, 3 execution arguments, 37 external access, minimizing to network, 73 external tools, 7 F F5 NGINX Ingress Controller, 23 Falco about, 6, 7, 141, 142 configuration file, 145 Index | 191  configuring, 144 custom rules for, 145 default rules for, 145 generating events in, 146 inspecting logs, 146 installing, 143 overriding existing rules, 150 rule file basics, 147 Falco 101 video course, 143 falco.yaml file, 145 falco_rules.local.yaml file, 145 falco_rules.yaml file, 145 Farley, David, Continuous Delivery, 130 feature gate, 79 file ownership, 72 file permissions, 72, 73 fine-grained incoming traffic, allowing, 16 firewalls, setting up rules for, 74 FROM command, 118 FTP servers, 73 G get all command, 24 GitHub, 7, 119, 127 GKE (Google Kubernetes Engine), 18 go build command, 117 Go runtime, 116 Google Cloud container registry, 122 Google distroless image, 115 granted permissions, verifying, 56 Grasso, Leonardo, Practical Cloud Native Secu‐ rity with Falco, 143 group ID, setting, 88 group management, 70 groupadd command, 71 groupdel command, 71 groups, 71 GUIs (graphical user interfaces), 4, 31 gVisor about, 5, 7, 105 configuring, 105 installing, 105 H hadolint (see Haskell Dockerfile Linter) hash, verifying binaries against, 38 Haskell Dockerfile Linter, 130 Helm package manager, 52 help option, 26host OS footprint, minimizing, 65-68 Humble, Jez, Continuous Delivery, 130 I identity and access management (IAM) roles, minimizing, 68-73 image digest validation, 120 image pull policy, 119, 122 image registries whitelisting with ImagePolicyWebhook Admission Controller plugin, 126 whitelisting with OPA Gatekeeper, 123-126 ImagePolicyWebhook Admission Controller plugin configuring, 127-130 whitelisting allowed image registries with, 126 images base, 114 container, 116, 119, 120 distroless, 115, 152 scanning for known vulnerabilities, 135 immutability, ensuring for containers, 151 imperative method, 26 inbound control node ports, 29 ingress, creating with TLS termination, 22-28 insecure configuration arguments, avoiding, 37 installing Falco, 143 Gatekeeper, 96 gVisor, 105 Kubernetes Dashboard, 32 options for, 8 J JFrog Artifactory, 123 journalctl command, 146 JSON Lines format, 154 K k8s_audit_rules.yaml file, 145 Kata Containers, 5, 7, 105 KCNA (Kubernetes and Cloud Native Asso‐ ciate), 2 KCSA (Kubernetes and Cloud Native Security Associate), 2 kernel hardening tools, 75-82 Killer Shell, 8 192 | Index  known vulnerabilities, scanning images for, 135 kube-bench, 7, 18, 19 kubeadm, 37 kubeconfig file, 51, 158 kubectl apply command, 14 kubectl command, 96, 158 kubectl logs command, 19 kubectl tool, 31, 37, 52, 131 Kubernetes release notes, 3 updating, 59-62 using mTLS in, 108 Kubernetes API, interacting with, 43-47 Kubernetes CIS Benchmark, 18 Kubernetes Dashboard about, 31 accessing, 32 installing, 32 Kubernetes Manifests, analyzing using Kubesec, 131-134 Kubernetes primitives (see primitives) Kubernetes Service, 45 Kubernetes-specific rules, 145 Kubesec, 130, 131-134 Kyverno, 98 L layers, reducing number of, 118 listing groups, 71 listing users, 69 lists (Falco), 148 log backend, 155, 156 logging, 6, 141-159 (see also behavior analytics) logs, inspecting in Falco, 146 ls command, 72 LTS (Long-Term Support), 59 M macros (Falco), 147 Managing Kubernetes (Burns and Tracey), 43 MD5, 38 Metadata audit level, 155 metadata server access, protecting with net‐ work policies, 30 microservice vulnerabilities, 85-110 about, 5, 85 answers to review questions, 174-177 container runtime sandboxes, 103-107managing Secrets, 99-103 Pod-to-Pod encryption with mTLS, 107 sample exercises, 110 setting OS-level security domains, 85-98 Minikube, 8 mkdir command, 82 mode, 92 monitoring, 6, 141-159, 154-158 (see also behavior analytics) mTLS Pod-to-Pod encryption, 5, 107 multi-stage approach, using for building con‐ tainer images, 116 Muschko, Benjamin Certified Kubernetes Administrator (CKA) Study Guide, x, 8, 22, 60, 99 Certified Kubernetes Application Developer (CKAD) Study Guide, 12 N namespaces, enforcing pod security standards for, 93 NAT (Network Address Translation), 11 netstat command, 73 network policies protecting metadata server access with, 30 using to restrict pod-to-pod communica‐ tion, 11 networkpolicy.io, 12 networks, minimizing external access to, 73 nginx, 153 node metadata, protecting, 28 NodePort Service type, 31 non-root users, enforcing usage of, 87 None audit level, 155 O OCI (Open Container Initiative) runtime, 105 OPA (Open Policy Agent), 95 OPA (Open Policy Agent) Gatekeeper about, 7, 85, 95 installing, 96 Library, 98 whitelisting allowed image registries with, 123-126 OpenSSL command, 25 optimization tools, for container images, 119 O’Reilly learning platform, 8 Index | 193  P packages, removing unwanted, 67 permissions minimizing for Service Account, 53-59 verifying, 51 platform binaries, verifying, 37 Pod Security Admission, 85 pod-to-pod communication, restricting using network policies, 11-18 Pod-to-Pod encryption, with mTLS, 107 Pods binding service account to, 53 enforcing security standards for namespa‐ ces, 93 PodSecurityContext API, 86 policies (OPA), 96 Portainer, 31 ports configuring for API server, 45 disabling open, 73 identifying open, 73 open, 73 port 10250, 29 port 10257, 29 port 10259, 29 port 2379-2380, 29 port 30000-32767, 29 port 6443, 29 Practical Cloud Native Security with Falco (Degioanni and Grasso), 143 practice exams, 8 prefix, 92 primitives, 6 private keys, creating, 49 privileged containers, avoiding, 89 privileged level, 93 profiles AppArmor, 76 applying to containers, 77 custom, 77, 80, 81 PSA (Pod Security Admission), 92 PSP (Pod Security Policies), 92 PSP (PodSecurityPolicy) admission controller, 60 PSS (Pod Security Standard), 92 public image registries, 122 R RBAC (role-based access control), 5read-only container root filesystems, configur‐ ing, 153 reducing attack surface/number of payers, 118 reference manual, for exam, 7 registries, public image, 122 Rego, 95, 123 release cadence, 60 release notes, 3 Request audit level, 155 RequestResponse audit level, 155 requests, processing, 44 restricted level, 93 restricted privileges, creating users with, 35 restricting access to API server, 48-59 pod-to-pod communication using network policies, 11-18 user permissions, 48-52 Rice, Liz, Container Security, 119 RoleBinding, creating, 51, 55 roles creating, 51 identity and access management (IAM), 68-73 rule argument, 26 rules Falco, 147 for firewalls, 74 overriding existing, 150 rules files (Falco), 147 RUN command, 118 runsc, 105 runtime class, creating, 106 runtime security, 6, 141-159 (see also behavior analytics) S sample exercises behavior analytics, 159 cluster hardening, 63 cluster setup, 41 microservice vulnerabilities, 110 supply chain security, 138 system hardening, 83 sandboxes, container runtime, 103-107 scanning images, for known vulnerabilities, 135 scenarios administrator can monitor malicious events in real time, 154 194 | Index  attacker can call API Server from Internet, 48 attacker can call API Server from Service Account, 52 attacker exploits container vulnerabilities, 114 attacker exploits package vulnerabilities, 66 attacker gains access to another container, 104 attacker gains access to Dashboard func‐ tionality, 31 attacker gains access to node running etcd, 99 attacker gains access to pods, 12 attacker injects malicious code into binary, 37 attacker injects malicious code into con‐ tainer images, 119 attacker installs malicious software, 151 attacker listens to communication between two pods, 108 attacker misuses root user container access, 86 attacker uploads malicious container images, 122 attacker uses credentials to gain file access, 68 compromised Pod accessing metadata servers, 29 developer doesn't follow pod security best practices, 91 Kubernetes administrator can observe actions taken by attackers, 142 seccomp, 7, 79-82 Secrets about, 151 configuring containers with, 152 creating for service accounts, 58 managing, 99-103 security enforcing standards for namespaces, 93 fixing issues with, 20 of supply chain, 5 (see also supply chain security) runtime, 6 setting OS-level domains, 85-98 security contexts, 86 SecurityContext API, 86 SELinux (Security-Enhanced Linux), 75semantic versioning scheme, 59 service account binding to Pods, 53 creating Secrets for, 58 disabling automounting for tokens, 57 expiration of token, 34 generating tokens, 58 minimizing permissions for, 53-59 ServiceAccount, 33 services, disabling, 66 SHA, 38 SHA256, 39, 120 signing container images, 119 size, of base images, 114 snapd package manager, 66 ss command, 73 static analysis, of workload, 130-134 status command, 66 Study4exam, 8 su command, 70 sudo command, 70 sudo systemctl restart kubelet command, 129 supply chain security, 113-138 about, 5, 113 answers to review questions, 178-183 minimizing base image footprint, 113-119 sample exercises, 138 scanning images for known vulnerabilities, 135 securing supply chain, 119-130 static analysis of workload, 130-134 sysctl command, 90 system hardening, 65-83 about, 5, 65 answers to review questions, 170-174 minimizing external access to networks, 73 minimizing host OS footprint, 65-68 minimizing IAM roles, 68-73 sample exercises, 83 using kernel hardening tools, 75-82 systemctl command, 66 systemctl status command, 74 T Tetragon, 142 TLS (Transport Layer Security) creating an ingress with termination, 22-28 creating TLS certificate and key, 25 termination of, 4 Index | 195  TLS Secret, 25 TLS-typed Secret, creating, 25 tokens, service account, 57 tools external, 7 kernel hardening, 75-82 optimization, 119 touch command, 72 Tracee, 142 Tracey, Craig, Managing Kubernetes, 43 Trivy, 5, 7, 135 TTL (time to live), 34 U Ubuntu Linux, CIS benchmark for, 66 UFW (Uncomplicated Firewall), 74 updating Kubernetes, 59-62 user ID, setting, 88 user management, 69 user permissions, restricting, 48-52 usermod command, 72 users adding, 69 adding to groups, 71 adding to kubeconfig file, 51 creating with administration privileges, 33 creating with restricted privileges, 35 deleting, 70 listing, 69 switching to, 70 V Vagrant, 8validating as stage in request processing, 44 container images, 120 verifying binaries against hash, 38 default permissions, 54 granted permissions, 56 Kubernetes platform binaries, 37 permissions, 51 platform binaries, 37 versioning scheme, 59 VirtualBox, 8 VPN (Virtual Private Network), 108 vulnerabilities, scanning images for known, 135 W warn mode, 93 webhook backend, 155, 158 wget command, 16 whitelisting allowed image registries with ImagePolicy‐ Webhook Admission Controller plugin, 126 allowed image registries with OPA Gate‐ keeper, 123-126 WireGuard, 108 workload, static analysis of, 130-134 Y YAML manifest, 13 196 | Index  About the Author Benjamin Muschko  is a software engineer, consultant, and trainer with more than 20 years of experience in the industry.


_Chapter length: 3601 words; sentences considered: 39._


---


_This document was automatically generated by creating extractive summaries (top ranked sentences by word frequency) from the uploaded PDF. It is intended as a concise study/reference sheet. For full details, refer to the original book and its exercises. _
