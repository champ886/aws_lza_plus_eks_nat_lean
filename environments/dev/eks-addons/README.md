# EKS Add-ons Module

Manages AWS EKS managed add-ons separately from the cluster.

## Add-ons Included

- **VPC CNI**: Pod networking
- **CoreDNS**: DNS resolution for services
- **kube-proxy**: Network proxy on nodes
- **Pod Identity Agent**: IRSA v2 (Pod Identity)

## Usage

```hcl
module "eks_addons" {
  source = "../../../modules/eks-addons"

  cluster_name = "dev-eks-cluster"
  environment  = "dev"
  
  # Optional: Override versions
  addon_version_vpc_cni    = "v1.18.1-eksbuild.1"
  addon_version_coredns    = "v1.11.1-eksbuild.4"
  addon_version_kube_proxy = "v1.29.0-eksbuild.1"
  
  # Optional: Disable specific add-ons
  enable_pod_identity = false
}
```

## Inputs

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Description</th>
      <th>Type</th>
      <th>Default</th>
      <th align="center">Required</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>cluster_name</code></td>
      <td>Name of the EKS cluster</td>
      <td><code>string</code></td>
      <td>n/a</td>
      <td align="center">yes</td>
    </tr>
    <tr>
      <td><code>environment</code></td>
      <td>Environment name (dev, staging, prod)</td>
      <td><code>string</code></td>
      <td><code>"dev"</code></td>
      <td align="center">no</td>
    </tr>
    <tr>
      <td><code>addon_version_vpc_cni</code></td>
      <td>Version of the VPC CNI add-on</td>
      <td><code>string</code></td>
      <td><code>"v1.18.0-eksbuild.1"</code></td>
      <td align="center">no</td>
    </tr>
    <tr>
      <td><code>addon_version_coredns</code></td>
      <td>Version of the CoreDNS add-on</td>
      <td><code>string</code></td>
      <td><code>"v1.11.1-eksbuild.4"</code></td>
      <td align="center">no</td>
    </tr>
    <tr>
      <td><code>addon_version_kube_proxy</code></td>
      <td>Version of the kube-proxy add-on</td>
      <td><code>string</code></td>
      <td><code>"v1.29.0-eksbuild.1"</code></td>
      <td align="center">no</td>
    </tr>
    <tr>
      <td><code>enable_vpc_cni</code></td>
      <td>Enable VPC CNI add-on</td>
      <td><code>bool</code></td>
      <td><code>true</code></td>
      <td align="center">no</td>
    </tr>
    <tr>
      <td><code>enable_coredns</code></td>
      <td>Enable CoreDNS add-on</td>
      <td><code>bool</code></td>
      <td><code>true</code></td>
      <td align="center">no</td>
    </tr>
    <tr>
      <td><code>enable_kube_proxy</code></td>
      <td>Enable kube-proxy add-on</td>
      <td><code>bool</code></td>
      <td><code>true</code></td>
      <td align="center">no</td>
    </tr>
    <tr>
      <td><code>enable_pod_identity</code></td>
      <td>Enable Pod Identity Agent add-on</td>
      <td><code>bool</code></td>
      <td><code>true</code></td>
      <td align="center">no</td>
    </tr>
  </tbody>
</table>

## Outputs

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>vpc_cni_version</code></td>
      <td>Deployed VPC CNI add-on version</td>
    </tr>
    <tr>
      <td><code>vpc_cni_arn</code></td>
      <td>ARN of the VPC CNI add-on</td>
    </tr>
    <tr>
      <td><code>coredns_version</code></td>
      <td>Deployed CoreDNS add-on version</td>
    </tr>
    <tr>
      <td><code>coredns_arn</code></td>
      <td>ARN of the CoreDNS add-on</td>
    </tr>
    <tr>
      <td><code>kube_proxy_version</code></td>
      <td>Deployed kube-proxy add-on version</td>
    </tr>
    <tr>
      <td><code>kube_proxy_arn</code></td>
      <td>ARN of the kube-proxy add-on</td>
    </tr>
    <tr>
      <td><code>pod_identity_arn</code></td>
      <td>ARN of the Pod Identity Agent add-on</td>
    </tr>
    <tr>
      <td><code>all_addon_versions</code></td>
      <td>Map of all deployed add-on versions</td>
    </tr>
  </tbody>
</table>

## Notes

- Add-ons are deployed with `OVERWRITE` on create and `PRESERVE` on update
- CoreDNS depends on VPC CNI being deployed first
- All add-ons are managed by AWS and automatically updated
- Use `enable_*` variables to selectively disable add-ons if needed

## Version Compatibility

<table>
  <thead>
    <tr>
      <th>EKS Version</th>
      <th>VPC CNI</th>
      <th>CoreDNS</th>
      <th>kube-proxy</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1.32</td>
      <td>v1.18.0+</td>
      <td>v1.11.1+</td>
      <td>v1.29.0+</td>
    </tr>
    <tr>
      <td>1.31</td>
      <td>v1.18.0+</td>
      <td>v1.11.1+</td>
      <td>v1.29.0+</td>
    </tr>
    <tr>
      <td>1.30</td>
      <td>v1.16.0+</td>
      <td>v1.11.1+</td>
      <td>v1.28.0+</td>
    </tr>
  </tbody>
</table>

## Example: Upgrading Add-on Versions

```hcl
module "eks_addons" {
  source = "../../../modules/eks-addons"

  cluster_name = "dev-eks-cluster"
  environment  = "dev"
  
  # Upgrade VPC CNI to latest
  addon_version_vpc_cni = "v1.18.1-eksbuild.1"
  
  # Keep others at default
}
```

After applying:
```bash
terraform apply
# CoreDNS and kube-proxy remain unchanged
# VPC CNI upgrades to v1.18.1
```

## Troubleshooting

<table>
  <thead>
    <tr>
      <th>Issue</th>
      <th>Solution</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Add-on stuck in <code>DEGRADED</code> state</td>
      <td>Check pod logs: <code>kubectl logs -n kube-system &lt;pod-name&gt;</code></td>
    </tr>
    <tr>
      <td>Version conflict on update</td>
      <td>Set <code>resolve_conflicts_on_update = "OVERWRITE"</code> (already default)</td>
    </tr>
    <tr>
      <td>CoreDNS fails to deploy</td>
      <td>Ensure VPC CNI is deployed first (automatic via <code>depends_on</code>)</td>
    </tr>
    <tr>
      <td>Pods can't reach internet</td>
      <td>Check VPC CNI is active and VPC peering is configured</td>
    </tr>
  </tbody>
</table>

## References

- [AWS EKS Add-ons Documentation](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)
- [VPC CNI Plugin](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html)
- [CoreDNS Add-on](https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html)
- [kube-proxy Add-on](https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html)
- [Pod Identity Agent](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)