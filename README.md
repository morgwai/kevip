# KEVIP
### Kubernetes external VIP iptables proxy

Kevip is a simple [UCarp](https://github.com/jedisct1/UCarp) / [Keepalived](https://www.keepalived.org/) L2 VIP + iptables proxy.
It can be used to provide a single static egress (source) virtual IP for a set of processes running on several machines (such as Kubernetes pods) if NAT is not possible for whatever reason (refereed hereinafter as *egress mode*).
On clusters where external load-balancers are not available, it can be also used to expose a Kubernetes service on a single (public) virtual IP, although there are some caveats and limitations explained below in this scenario (refereed hereinafter as *ingress mode*).

----


## Usage

Kevip requires 3 parameters that can be passed via command line flags or env variables:

`--vip` / `VIP` virtual IP address to be created.
In egress mode this is the IP that 3rd party external service (specified by `TARGET` below) will see as the source IP of the traffic incoming from your pods. This is also the IP that your pods should be sending the traffic intended for the given external service.
In ingress mode this is the public IP on which your service will be exposed to external clients. VIP may be any unassigned IP from a subnet where the machine running Kevip is located. It should be outside of the dhcp pool, so that no other machine will ever get it assigned.

`--target` / `TARGET` IP address where the traffic sent to the VIP should be redirected.
In egress mode this will be the IP of the 3rd party external service to which you want to present your service's traffic as coming from the VIP.
In ingress mode this will be the cluster-IP of the service that you want to expose.

`--password` / `PASSWORD` this can be any hard to guess string that will be used for internal communication between Kevip replicas.

It is possible to mix command line flags and env variables. If both are defined for any param, then command line takes precedence.

For high availability reasons, you should be running 2-3 replicas of Kevip for each VIP. At any given moment only 1 of the replicas will be holding the VIP and if this replica goes down for whatever reason, 1 of the remaining ones will take over by the means of CARP/VRRP protocols.

Kevip must be granted permissions to setup a VIP and manipulate iptables. On Kubernetes this requires `NET_ADMIN` and `NET_RAW` capabilities and running on host network.

In egress mode Kevip can be running anywhere where your nodes can reach it, but it's recommended to run it on the cluster itself to reduce network latency.

In ingress mode Kevip *must* be running on your cluster's nodes (either as your cluster's deployment or started from the node machine level), so that it can reach cluster-IP of its target service.

Further more, in ingress mode, due to the fact how iptables/ipvs work and that the target cluster-IP is also a VIP itself, the following iptables rule must be added on all nodes where Kevip replicas may be scheduled:
```bash
iptables -t nat -A POSTROUTING -j MASQUERADE
```
This may affect other services running on these nodes though. In particular it breaks Kevip running in egress mode.

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
			"hostNetwork": true,
			"spec": {
				"containers": [
					{
						"name": "kevip",
						"image": "morgwai/kevip:0.99.2",
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
					}
				]
			}
		}
	}
}
```
