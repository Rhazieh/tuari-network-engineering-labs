# 01 — Multi-Domain Distributed Network: BGP, OSPF, RIPv2, IPv6 `sit` Tunnel & Policy-Based Routing

Comprehensive distributed networking lab designed and validated in **CORE (Common Open Research Emulator)** with **Quagga/Zebra** routing daemons on top of the Linux kernel (`Diseño de Redes Distribuidas` — TUARI, UNICEN).

---

## Topology Overview

- **Transit Provider (`AS6000`):** Core routers `R6001`, `R6002`, `R6003` interconnected via **OSPFv2 (Area 0)** and full-mesh **iBGP**.
- **Customer `AS6100`:** Border router `R6101`, distribution router `R6102`, access routers `R6103` and `R6104`, serving LANs `192.168.9.0/24` (`H6202`) and `192.168.10.0/24` (`H6201`).
- **Customer `AS6200`:** Border router `R6201`, internal routers `R6202` and `R6203`, serving LAN `192.168.11.0/24` (`H6200`).
- **Alternative WAN Link (Phase 4):** Direct **ADSL** router connecting `R6101` (`210.0.0.0/24`) and `R6201` (`220.0.1.0/24`).

---

## Implementation Phases

### Part 1 — Interior Gateway Protocols (OSPFv2 & RIPv2) and Redistribution
- Configured **OSPFv2 (Area 0)** across `AS6200` (`R6201`, `R6202`, `R6203`) and the core segment of `AS6100` (`R6101`–`R6102`, link `10.100.2.0/24`).
- Excluded external transit interfaces from OSPF `network` statements to prevent outbound `HELLO` leakage, injecting edge subnets via `redistribute connected`.
- Configured **RIPv2** across `R6102`, `R6103`, and `R6104` (`10.100.0.0/24`, `10.100.1.0/24`, `192.168.9.0/24`, `192.168.10.0/24`) with mutual redistribution between OSPF and RIPv2 on `R6102`.
- Verified route selection (`>` selected, `*` FIB installed in kernel) and Administrative Distance / metric interpretation (`[110/20]` OSPF vs `[120/2]` RIP vs AD `0` Connected).

### Part 2 — Inter-AS Routing with eBGP & Full-Mesh iBGP
- Established **eBGP** sessions over TCP/179 between `AS6100` (`R6101`) ↔ `AS6000` (`R6001`) and `AS6000` (`R6003`) ↔ `AS6200` (`R6201`), advertising internal networks with `redistribute connected` / `redistribute ospf` and `next-hop-self`.
- Provisioned `/32` **Loopback** interfaces inside `AS6000` (`4.4.4.4/32`, `5.5.5.5/32`, `6.6.6.6/32`) advertised via OSPFv2 to provide stable endpoints for **full-mesh iBGP** using `update-source lo`.
- Validated BGP peering state (`Established` in `show ip bgp summary` / `show ip bgp neighbors`), recursive IGP resolution for iBGP next-hops (`AD 200`), `AS_PATH` propagation (`6000 6200 ?`, `6000 6100 ?`), and end-to-end reachability (`0%` packet loss from `H6202` to `H6200`).

### Part 3 — IPv6 Subnetting Plan (`/60` → `/64`)
- Partitioned a `/60` IPv6 prefix (`2001:1200::/60`) into ordered `/64` subnets:
  - Subnets `0`–`7` assigned to `AS6100` (`2001:1200::/64` through `2001:1200:0:4::/64` for access LANs and P2P links, plus reserved blocks for growth/BGP).
  - Subnets `8`–`f` assigned to `AS6200` (`P2P-R6201-R6202`, `P2P-R6202-R6203`, `LAN-H6200`).

### Part 4 — ADSL Link, IPv6-over-IPv4 `sit` Tunnel, Policy-Based Routing & Traffic Filtering
1. **Direct ADSL Path:** Added an ADSL router linking `R6101` (`210.0.0.0/24`) and `R6201` (`220.0.1.0/24`) with `ip_forward=1` and static routes.
2. **IPv6 Transition Tunnel (`sit1`):** Configured an IP protocol `41` (`sit`) tunnel between `R6101` (`210.0.0.1` → `220.0.1.2`) and `R6201` (`220.0.1.2` → `210.0.0.1`) carrying `2001:1200:0:5::/64` and ULA `fd00:0:0:5::/64` across the IPv4 transport.
3. **Policy-Based Routing (`iproute2` RPDB):** Created custom routing tables on `R6101` (`table 100` via ADSL `210.0.0.2` and `table 200` via BGP `100.0.3.2`) and `ip rule` selectors so `H6201` (`192.168.10.0/24`) exits via ADSL while `H6202` (`192.168.9.0/24`) exits via BGP, verified via `traceroute`.
4. **Protocol-Aware Routing (`iptables` `mangle` + `fwmark`):** Marked **UDP** traffic originating from `H6201` using `iptables -t mangle -A PREROUTING -s 192.168.10.0/24 -p udp -j MARK --set-mark 5` combined with a higher-priority rule (`ip rule add prio 90 fwmark 5 lookup 200`), keeping ICMP traffic (`traceroute -I`) on ADSL while steering UDP traffic (`traceroute`) through BGP.
5. **Filtering Policy (`unreachable` vs `blackhole`):**
   - Blocked Google DNS (`8.8.8.8/32`, `8.8.4.4/32`) on `R6101` inside tables `100` and `200` with **`unreachable`** routes (returning `Destination Host Unreachable` ICMP feedback to `AS6100`).
   - Blocked the same destinations on `R6201` using **`blackhole`** routes paired with OSPF `default-information originate` (silently dropping packets with `100%` loss and zero ICMP reply to `AS6200`).

---

## Included Technical Artifacts

- [`TPE-Parte2-DRD.xml`](./TPE-Parte2-DRD.xml) — CORE network topology with Quagga OSPFv2, RIPv2, eBGP, and iBGP over Loopbacks (`Part 2`).
- [`TPE-Parte4-DRD.xml`](./TPE-Parte4-DRD.xml) — Final extended CORE topology adding the ADSL WAN path, `sit1` IPv6-in-IPv4 tunnel, PBR tables, `fwmark` mangling, and DNS filtering (`Part 4`).
- [`configurar_tpe.bash`](./configurar_tpe.bash) — Automated Bash/vtysh/`iproute2`/`iptables` configuration script applied across running CORE router namespaces.
- [`capturas_tpe.bash`](./capturas_tpe.bash) — Automated verification script capturing BGP summaries, FIB routing tables, `ip rule` selectors, and `ping`/`traceroute` outputs across nodes.
- [`machete-defensa-drd.txt`](./machete-defensa-drd.txt) — Defense reference cheat-sheet summarizing AD values, Quagga daemon behavior, `sit` tunnel mechanics, RPDB/fwmark flow, and `unreachable` vs `blackhole`.
