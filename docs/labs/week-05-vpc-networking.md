# Week 5: VPC and networking

Status: **Prepared** on 13 September 2026. The Terraform topology and fail-closed
input guards are locally defined; no VPC resources have been created.

## Topology contract

```mermaid
flowchart TB
    Internet((Internet)) --> IGW[Internet Gateway]
    IGW --> PRT[Public route table\n0.0.0.0/0 to IGW]
    subgraph VPC[OrderFlow VPC /16]
      subgraph AZ1[Availability Zone A]
        PUB1[Public subnet /24]
        PRI1[Private subnet /24]
      end
      subgraph AZ2[Availability Zone B]
        PUB2[Public subnet /24]
        PRI2[Private subnet /24]
      end
      PRT --> PUB1
      PRT --> PUB2
      PRI1 --> RT1[Private route table A\nlocal route only]
      PRI2 --> RT2[Private route table B\nlocal route only]
    end
```

The module deliberately creates no NAT Gateway. A subnet is public because its route table has a
route to an Internet Gateway; merely naming it `public` does not make it public. Instances also need
a public IPv4 address or equivalent edge path, security-group permission, and a listening service.

## Packet-path reasoning

Browser to public workload:

1. DNS resolves the public endpoint.
2. Traffic enters through the Internet Gateway.
3. The public route table maps the return path to the Internet Gateway.
4. The workload security group permits only the intended listener and source.
5. The network ACL is stateless and must permit both request and ephemeral return traffic.

Application to private PostgreSQL:

1. The application resolves the private database endpoint inside the VPC.
2. VPC local routing carries the packet between subnets.
3. The database security group permits TCP 5432 from the application security group, not from a CIDR open to the Internet.
4. The database has no public endpoint or Internet Gateway route.

Security groups are stateful and attach to network interfaces. Network ACLs are stateless subnet
guardrails. For routine OrderFlow labs, security groups carry the primary least-privilege rules and
the default network ACL remains unchanged unless the lesson explicitly tests it.

## Fail-closed Terraform checks

Deployment requires:

- exactly two reviewed Availability Zones;
- exactly two public and two private subnet CIDRs;
- every subnet contained by the VPC CIDR;
- four unique, non-overlapping subnet CIDRs;
- exact account and Region matches plus owner and expiry metadata.

The public subnets set `map_public_ip_on_launch = false`; public IPv4 assignment must be an explicit,
cost-reviewed choice for a specific workload.

## Guided manual lab

1. Run the account/role/Region preflight and review the zero-NAT estimate.
2. Create the two-AZ topology manually in the VPC console using reviewed, non-overlapping CIDRs.
3. Verify route-table associations and DNS settings in the rendered console.
4. Compare security-group statefulness with network-ACL statelessness using diagrams and flow-log reasoning.
5. Do not launch an instance merely to prove the VPC exists; that belongs to the EC2 lab.
6. Delete the manual VPC after evidence is sanitized, then independently verify its subnets, route tables, and Internet Gateway are gone.

## Evidence status

- **Confirmed:** source topology contains one VPC, two public subnets, two private subnets, one Internet Gateway, public routing, isolated private route tables, and no NAT Gateway.
- **Partial:** Terraform validation was previously confirmed for the inert root; re-run it after this guard change when WSL access is available.
- **Unverified:** personal-account manual creation, console packet-path inspection, and teardown.
