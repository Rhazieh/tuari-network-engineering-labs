# TUARI Network Engineering Labs (UNICEN)

Collection of enterprise and distributed network architectures, routing policies, firewalling labs, and infrastructure audits developed during the **Associate Degree in IT Network Administration (TUARI)** at **UNICEN (Facultad de Ciencias Exactas)**, Tandil, Argentina.

---

## Projects & Labs

| Directory | Project / Scope | Core Technologies & Protocols |
| :--- | :--- | :--- |
| [`01-distributed-routing-core-quagga/`](./01-distributed-routing-core-quagga/README.md) | **Multi-Domain Distributed Network (Inter-AS Routing, IPv6 Tunnels & Policy Routing)** | CORE Emulator, Quagga/Zebra, **eBGP**, **iBGP** (full-mesh over Loopbacks), **OSPFv2**, **RIPv2**, **IPv6** (`/60` → `/64` + ULA), **`sit` Tunnel** (IPv6-over-IPv4), **`iproute2` PBR** (RPDB tables & `ip rule`), **`iptables` mangle (`fwmark`)**, `unreachable` vs `blackhole` routes |
| [`02-corporate-mikrotik-vlans/`](./02-corporate-mikrotik-vlans/README.md) | **Multi-Branch Corporate Network & WAN Failover** | **VLANs (IEEE 802.1Q)**, **MikroTik RouterOS** (automatic WAN failover), **Squid Proxy**, **LDAP**, structured cabling (Cat.6) & fiber optic uplinks, rack design |
| [`03-vlsm-iptables-perimeter/`](./03-vlsm-iptables-perimeter/README.md) | **Campus / Institutional Network Design & Perimeter Firewall** | **IPv4 VLSM** subnetting (`/16` allocation & `/30` P2P links), multi-router static routing tables, **`iptables` / Netfilter** default-deny perimeter policies |
| [`04-tia942-audit-and-unifi-survey/`](./04-tia942-audit-and-unifi-survey/README.md) | **Data Center Infrastructure Audit & Outdoor Wi-Fi Survey** | **ANSI/TIA-942** (electrical, mechanical, telecom & architectural subsystems), **Ubiquiti UniFi Mesh** (RSSI & coverage mapping), functional software/infra assessment |

---

## Skills Demonstrated

- **Dynamic & Policy Routing:** Multi-AS BGP (`AS_PATH`, `next-hop-self`, `update-source lo`), OSPF Area 0, RIPv2, bidirectional protocol redistribution, and Linux Policy-Based Routing (`iproute2` + `iptables` packet marking).
- **IPv4 & IPv6 Transition:** Zero-waste VLSM addressing, IPv6 prefix planning, and IPv6-in-IPv4 encapsulation via `sit` interfaces (IP protocol 41).
- **Network Security & Services:** Stateful/stateless packet filtering (`iptables`), HTTP proxying (Squid), centralized authentication (LDAP), and traffic differentiation (`unreachable` vs `blackhole`).
- **Physical Layer & Standards:** Structured cabling (ANSI/TIA-568), fiber optics (OS2/OM3), Data Center redundancy evaluation (TIA-942), and enterprise wireless surveys.
