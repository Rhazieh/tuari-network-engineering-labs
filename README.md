# TUARI Network Engineering Labs (UNICEN)

Collection of enterprise and distributed network architectures, routing policies, firewalling labs, and infrastructure audits developed during the **Associate Degree in IT Network Administration (TUARI)** at **UNICEN (Facultad de Ciencias Exactas)**, Tandil, Argentina.

---

## Projects & Labs

| Directory | Project / Scope | Core Technologies & Protocols | Key Artifacts |
| :--- | :--- | :--- | :--- |
| [`01-distributed-routing-core-quagga/`](./01-distributed-routing-core-quagga/README.md) | **Multi-Domain Distributed Network (Inter-AS Routing, IPv6 Tunnels & Policy Routing)** | CORE Emulator, Quagga/Zebra, **eBGP**, **iBGP** (full-mesh over Loopbacks), **OSPFv2**, **RIPv2**, **IPv6** (`/60` → `/64` + ULA), **`sit` Tunnel** (IPv6-over-IPv4), **`iproute2` PBR** (RPDB tables & `ip rule`), **`iptables` mangle (`fwmark`)**, `unreachable` vs `blackhole` routes | CORE XML topologies (`TPE-Parte2-DRD.xml`, `TPE-Parte4-DRD.xml`), automation/capture bash scripts (`configurar_tpe.bash`, `capturas_tpe.bash`), defense notes |
| [`02-corporate-mikrotik-vlans/`](./02-corporate-mikrotik-vlans/README.md) | **Multi-Branch Corporate Network & WAN Failover** | **VLANs (IEEE 802.1Q)**, **MikroTik RouterOS** (automatic WAN failover), **Squid Proxy**, **LDAP**, structured cabling (Cat.6) & fiber optic uplinks, rack design | [`Diagrama-Redes-Corporativas.drawio`](./02-corporate-mikrotik-vlans/Diagrama-Redes-Corporativas.drawio), [`Informe_Redes_Corporativas.pdf`](./02-corporate-mikrotik-vlans/Informe_Redes_Corporativas.pdf) |
| [`03-vlsm-iptables-perimeter/`](./03-vlsm-iptables-perimeter/README.md) | **Campus / Institutional Network Design & Perimeter Firewall** | **IPv4 VLSM** subnetting (`/16` allocation & `/30` P2P links), multi-router static routing tables, **`iptables` / Netfilter** default-deny perimeter policies | [`TrabajoIntegrador.drawio.png`](./03-vlsm-iptables-perimeter/TrabajoIntegrador.drawio.png), [`Trabajo Integrador - Colegio San Martín.pdf`](./03-vlsm-iptables-perimeter/Trabajo%20Integrador%20-%20Colegio%20San%20Mart%C3%ADn.pdf), [`clase-iptables.imn`](./03-vlsm-iptables-perimeter/clase-iptables.imn) |
| [`04-tia942-audit-and-unifi-survey/`](./04-tia942-audit-and-unifi-survey/README.md) | **Data Center Infrastructure Audit, Outdoor Wi-Fi Survey & System Assessment** | **ANSI/TIA-942** (electrical, mechanical, telecom & architectural subsystems), **Ubiquiti UniFi Mesh** (RSSI & coverage mapping), functional software/infra assessment | [`UNICEN-Campus-WiFi-UniFi-Mesh-Report.pdf`](./04-tia942-audit-and-unifi-survey/UNICEN-Campus-WiFi-UniFi-Mesh-Report.pdf), [`Booking-Scheduler-vs-phpScheduleIt-Functional-Analysis.pdf`](./04-tia942-audit-and-unifi-survey/Booking-Scheduler-vs-phpScheduleIt-Functional-Analysis.pdf) |

---

## Skills Demonstrated

- **Dynamic & Policy Routing:** Multi-AS BGP (`AS_PATH`, `next-hop-self`, `update-source lo`), OSPF Area 0, RIPv2, bidirectional protocol redistribution, and Linux Policy-Based Routing (`iproute2` + `iptables` packet marking).
- **IPv4 & IPv6 Transition:** Zero-waste VLSM addressing, IPv6 prefix planning, and IPv6-in-IPv4 encapsulation via `sit` interfaces (IP protocol 41).
- **Network Security & Services:** Stateful/stateless packet filtering (`iptables`), HTTP proxying (Squid), centralized authentication (LDAP), and traffic differentiation (`unreachable` vs `blackhole`).
- **Physical Layer & Standards:** Structured cabling (ANSI/TIA-568), fiber optics (OS2/OM3), Data Center redundancy evaluation (TIA-942), and enterprise wireless surveys.
