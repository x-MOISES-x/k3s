This is a personal project to deploy a kubernetes cluster using k3s on Oracle Cloud Infrastructure (OCI) Always Free tier in a mostly automated way. It is meant to be used as a template to quickly deploy a k3s cluster on OCI and test applications.

Before using this, you must have already setup your OCI environment as explained here: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm in order to use terraform. The structure is kept flat to make things simpler.

For the compute instances and networking the OCI Terraform modules were used.

Terraform will create:
- A virtual cloud network (VCN) (vcn.tf)
- A public subnet (vcn.tf)
- A network load balancer (NLB), along with the required backend sets, backends and listeners. (nlb.tf)
- 4 compute instances (1 master, 3 workers) (instance.tf)
- NSGs for the compute instances and the NLB (security.tf)
- A local file Inventory for Ansible.
- The k3s-server.sh script on the master is executed during terraform apply. This installs k3s, creates an NFS share and NFS CSI driver, installs Cilium, Helm and creates a self-signed certificate for the Gateway API to use for TLS termination.

The k3s deployment options are not the default ones. Traefik, ServiceLB and Kube-Proxy are disabled. Instead, Cilium is used as CNI with Gateway API enabled, kube-proxy replacement and handling of LoadBalancer services. If you wish to edit the cluster configuration, you can do so by editing the `k3s-master.sh` and `k3s-worker.sh` scripts which run as user-data during instance creation and create two scripts `k3s-server.sh` and `k3s-agent.sh` which contain the actual k3s installation commands and reside in the `/home/opc` directory on the compute instances. Only the `k3s-server.sh` is executed during terraform apply as defined in the `deploy-k3s.tf` file, this needs Ansible to be installed on your local machine. 

A tfvars is included as an example, it must be edited to include the OCI values for your environment. The manifests folder contains a Gateway API example, an HTTPRoute to expose ArgoCD and edits to the ArgoCD ConfigMap if you choose to use ArgoCD as GitOps tool for the cluster.

You can: ```bash tail /var/log/cloud-init-output.log``` to check the progress of the user-data scripts, and get the K3s server private IP and Token.

To run the `k3s-agent.sh` with Ansible:

```bash
ansible nodes -i inventory.yaml -m shell -a 'printf "TYPEK3SSERVERPRIVATEIP\nPASTETOKENSTRING\n"| /home/opc/k3s-agent.sh'
```
There are two scripts which can be used to deploy kubernetes using kubeadm:
- `k8s-install.sh` - This script will install kubeadm, kubectl, kubelet and kubeadm. It will also install containerd and configure it to use overlayfs as the storage driver. It will also install Cilium as CNI with Gateway API enabled, kube-proxy replacement and handling of LoadBalancer services. When using a LoadBalancer service, the External IP might show as pending, delete the `node.kubernetes.io/exclude-from-external-load-balancers` label from the node for nodeIPAM to work properly.
- `k8s-node.sh` - This script will install kubeadm, kubelet and containerd.

Substitute the values in the user_data field of master and nodes modules with the flavor of your choice.

A tfvars is included as an example, it must be edited to include the OCI values for your environment. The manifests folder contains a Gateway API example, an HTTPRoute to expose ArgoCD and edits to the ArgoCD ConfigMap if you choose to use ArgoCD as GitOps tool for the cluster.

A 409 error might happen during `terraform destroy`, run it again to finish destroying the resources.


