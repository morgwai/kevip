# KEVIP
### Kubernetes external VIP iptables proxy

Kevip is a simple [UCarp](https://github.com/jedisct1/UCarp) / [Keepalived](https://www.keepalived.org/) based L2 VIP + iptables proxy.

It can be used to provide a single static egress (source) virtual IP for a set of processes running on several machines (such as Kubernetes pods) if NAT is not possible for whatever reason. This mode will be refereed hereinafter as *egress mode*. **Note: if you do have access to administrative settings of your subnet's network, then setting up a subnet-wide NAT is definitely a preferred solution over Kevip, which should be considered the last resort.**

On k8s clusters with kube-proxy in `IPVS` mode, Kevip can be also used to expose a k8s service on a single (public) virtual IP, if external load-balancers are not available. There are however some serious [caveats and limitations](#caveats-and-limitations) in this mode (refereed hereinafter as *k8s service ingress mode*).

----


## Usage

Kevip requires 3 parameters that can be passed via command line flags or env variables:

`--vip` / `VIP` virtual IP address to be created.
In egress mode this is the IP that 3rd party external service (specified by `TARGET` below) will see as the source IP of the traffic incoming from your pods. This is also the IP that your pods should be sending the traffic intended for the given external service.
In k8s service ingress mode this is the public IP on which your service will be exposed to external clients. VIP may be any unassigned IP from a subnet where the machine running Kevip is located. It should be outside of the DHCP pool, so that no other machine will ever get it assigned.

`--target` / `TARGET` IP address where the traffic sent to the VIP should be redirected.
In egress mode this will be the IP of the 3rd party external service to which you want to present your service's traffic as coming from the VIP.
In k8s service ingress mode this will be the cluster-IP of the service that you want to expose.

`--password` / `PASSWORD` this can be any hard to guess string that will be used for internal communication between Kevip replicas.

In addition, Kevip recognizes the following non-mandatory parameters:

`--global-masquerade` / `GLOBAL_MASQUERADE` a boolean that tells Kevip to setup a host-wide iptables `MASQUERADE` (ie: `iptables -t nat -A POSTROUTING -j MASQUERADE`) instead of targeted `SNAT` rule. This is necessary if the `TARGET` is also a VIP on the same machine. So in particular it is necessary for k8s service ingress mode. This may affect other services running on this machine though. In particular it breaks Kevip running in egress mode.

`--vip-id` / `VIP_ID` CARP/VRRP protocols assign each VIP an 8 bit long ID (1-255), that is used for communication between replicas. Kevip by default uses the last of the 4 parts of the VIP as its ID (for example 87 for 17.45.28.87). This param can be used to override this behaviour if needed.

It is possible to mix command line flags and env variables. If both are defined for any param, then command line takes precedence.

For high availability reasons, 2-3 replicas of Kevip should be started for each VIP. At any given moment only 1 of the replicas will be holding the VIP and if this replica goes down for whatever reason, 1 of the remaining ones will take over by the means of CARP/VRRP protocols.

Kevip must be granted permissions to setup a VIP and manipulate iptables. On Kubernetes this requires `NET_ADMIN` and `NET_RAW` capabilities and running on host network.

----

## Caveats and Limitations

In egress mode Kevip can be running anywhere where cluster's nodes can reach it, but it's recommended to run it on the cluster itself to reduce network latency.

k8s service ingress mode works *only* if kube-proxy is configured to use `IPVS` (default since k8s-1.10 if `ip_vs` kernel modules are pre-loaded).

In k8s service ingress mode Kevip *must* be running on a given cluster's nodes (either as a cluster deployment or started from node machines level), so that it can reach cluster-IP of its target service.

As explained before, in k8s service ingress mode, due to the fact how iptables/ipvs work and that the target cluster-IP is also a VIP itself, `--global-masquerade` flag that can affect other services is required. An ugly workaround is to dedicate few nodes only for Kevip in k8s service ingress mode.

Due to the fact that CARP/VRRP protocols use 8 bit long IDs for VIPs, it is possible to create only up to 255 VIPs on a single (V)LAN. If more VIPs are needed, then the cluster's network must be divided into several smaller VLANs or subnets.

----


## Releases

Releases are provided as docker images at [docker hub](https://hub.docker.com/r/morgwai/kevip/tags)

----


## Example Kubernetes deployment

```json
{
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "name": "kevip-89.16.122.41"
    },
    "spec": {
        "replicas": 3,
        "selector": {
            "matchLabels": {
                "app": "kevip-89.16.122.41"
            }
        },
        "template": {
            "metadata": {
                "labels": {
                    "app": "kevip-89.16.122.41"
                }
            },
            "spec": {
                "hostNetwork": true,
                "containers": [{
                    "name": "kevip",
                    "image": "morgwai/kevip:0.99.3",
                    "securityContext": {
                        "capabilities": {
                            "add": ["NET_ADMIN", "NET_RAW"]
                        }
                    },
                    "env": [
                        {
                            "name": "VIP",
                            "value": "89.16.122.41"
                        },
                        {
                            "name": "TARGET",
                            "value": "54.111.118.99"
                        },
                        {
                            "name": "PASSWORD",
                            "valueFrom": {
                                "secretKeyRef": {
                                    "name": "kevip",
                                    "key": "password"
                                }
                            }
                        }
                    ]
                }]
            }
        }
    }
}
```
