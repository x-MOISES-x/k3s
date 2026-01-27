This is a personal project to deploy a kubernetes cluster using k3s on Oracle Cloud Infrastructure (OCI) Always Free tier in a mostly automated way.
For the compute instances and networking the OCI Terraform modules were used.

Terraform will create:
- A virtual cloud network (VCN) (vcn.tf)
- A public subnet (vcn.tf)
- A network load balancer (NLB), along with the required backend sets, backends and listeners. (nlb.tf)
- 4 compute instances (1 master, 3 workers) (instance.tf)
- NSGs for the compute instances and the NLB (security.tf)
- A local file Inventory for Ansible.
- The k3s-server.sh script on the master is executed during terraform apply. This installs k3s, creates an NFS share and NFS CSI driver, installs Cilium, Helm and creates a self-signed certificate for the Gateway API to use for TLS termination.

The k3s deployment options disable Traefik, ServiceLB and Kube-Proxy. Cilium is installed as CNI with Gateway API enabled, kube-proxy replacement and handling of LoadBalancer services. If you wish to edit the cluster configuration, you can do so by editing the `k3s-master.sh` and `k3s-worker.sh` scripts which run as user-data during instance creation and create two scripts `k3s-server.sh` and `k3s-agent.sh` which contain the actual k3s installation commands and reside in the `/home/opc` directory on the compute instances. Only the `k3s-server.sh` is executed during terraform apply as defined in the `deploy-k3s.tf` file, this needs Ansible to be installed on your local machine. 

To run the `k3s-agent.sh` with Ansible:

```bash
ansible nodes -i inventory.yaml -m shell -a 'printf "TYPEK3SSERVERPRIVATEIP\nPASTETOKENSTRING\n"| /home/opc/k3s-agent.sh'
```
Both the K3s Server Private IP and the Token can be retrieved from the terraform apply output.

A tfvars is included as an example, it must be edited to include the OCI values for your environment. The manifests folder contains a Gateway API example, an HTTPRoute to expose ArgoCD and edits to the ArgoCD ConfigMap if you choose to use ArgoCD as GitOps tool for the cluster.



