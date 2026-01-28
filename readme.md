This is a personal project to deploy a kubernetes cluster using k3s on Oracle Cloud Infrastructure (OCI) Always Free tier in a mostly automated way.
For the compute instances and networking the OCI Terraform modules were used.

Terraform will create:
- A virtual cloud network (VCN) (vcn.tf)
- A public subnet (vcn.tf)
- A network load balancer (NLB), along with the required backend sets, backends and listeners. (nlb.tf)
- 4 compute instances (1 master, 3 workers) (instance.tf)
- NSGs for the compute instances and the NLB (security.tf)
- A local file Inventory for Ansible.
- The k3s-master.sh script on the master is executed as user-data during instance creation. This installs k3s, creates an NFS share and NFS CSI driver, installs Cilium, Helm and creates a self-signed certificate for the Gateway API to use for TLS termination.

The k3s deployment options disable Traefik, ServiceLB and Kube-Proxy. Cilium is installed as CNI with Gateway API enabled, kube-proxy replacement and handling of LoadBalancer services. If you wish to edit the cluster configuration, you can do so by editing the `k3s-master.sh` and `k3s-node.sh` scripts which run as user-data during instance creation. Another script `k3s-agent.sh` is generated in the nodes with the k3s installation commands and reside in the `/home/opc` directory on the compute instances.

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


