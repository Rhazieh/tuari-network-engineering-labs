# 02 — Multi-Branch Corporate Network Design & WAN Failover

Enterprise network design project covering physical infrastructure, L2/L3 segmentation, WAN resiliency, and centralized network services (`Diseño de Redes Corporativas` — TUARI, UNICEN).

---

## Scope & Architecture

- **Physical Layer & Rack Design:**
  - Logical and physical topology blueprints created in Draw.io.
  - Structured cabling layout (**Cat.6** UTP) and **fiber optic** backbone uplinks connecting branches and distribution racks.
  - Technical bill of materials and telecommunications rack budgeting.
- **L2/L3 Segmentation & Switching:**
  - Traffic isolation across corporate departments and branch sites using **IEEE 802.1Q VLANs**.
- **WAN Redundancy & Routing:**
  - Dual-WAN uplink design with **automatic failover** configured on **MikroTik RouterOS** to ensure business continuity for branch operations.
- **Perimeter & Directory Services:**
  - Web traffic filtering and caching with **Squid Proxy**.
  - Centralized user authentication and directory integration via **LDAP**.

---

## Included Technical Artifacts

- [`Diagrama-Redes-Corporativas.drawio`](./Diagrama-Redes-Corporativas.drawio) — Full physical/logical Draw.io diagram covering central headquarters, branches, VLAN trunks, Cat.6/fiber cabling, and WAN failover links.
- [`Informe_Redes_Corporativas.pdf`](./Informe_Redes_Corporativas.pdf) — Complete architectural specification report (bill of materials, addressing plan, VLAN segmentation, MikroTik failover design, and Squid/LDAP architecture).
