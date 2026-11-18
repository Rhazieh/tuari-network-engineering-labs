# 03 — Institutional Network Design: VLSM Addressing & `iptables` Perimeter Firewall

End-to-end network architecture and perimeter security project ("Colegio San Martín") built with zero-waste IPv4 addressing and Linux Netfilter rules (`TUARI — UNICEN`).

---

## Key Components

- **VLSM Subnetting:** Partitioned a private `/16` address space to allocate exact subnets for computer labs, faculty/staff, Wi-Fi clients, administrative workstations, and `/30` point-to-point inter-router links without IP waste.
- **Multi-Router Addressing & Static Routing:** Defined complete interface addressing tables and static routing plans across **4 routers**.
- **Linux Perimeter Security (`iptables` / Netfilter):**
  - Default-restrictive (`DROP`) policies across `INPUT`, `OUTPUT`, and `FORWARD` chains.
  - Stateful filtering (`ESTABLISHED,RELATED`), inter-zone access rules isolating administrative segments from lab/guest Wi-Fi traffic, and NAT (`MASQUERADE` / `SNAT` / `DNAT`) policies.

---

## Included Technical Artifacts

- [`TrabajoIntegrador.drawio.png`](./TrabajoIntegrador.drawio.png) — Logical network topology diagram for "Colegio San Martín" (`10.42.0.0/16` VLSM segmentation and 4-router layout).
- [`Trabajo Integrador - Colegio San Martín.pdf`](./Trabajo%20Integrador%20-%20Colegio%20San%20Mart%C3%ADn.pdf) — Complete VLSM subnetting tables (`/30` P2P links and LAN subnets), static routing tables, and documentation.
- [`clase-iptables.imn`](./clase-iptables.imn) — IMUNES/CORE topology configuration file for Unit 3 `iptables` / NAT firewalling lab (`Frontera`, `ISP2`, internal LANs).
