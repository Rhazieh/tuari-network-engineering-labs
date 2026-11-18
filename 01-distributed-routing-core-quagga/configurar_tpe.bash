#!/bin/bash
# ==============================================================================
# SUPERSCRIPT DE CONFIGURACIÓN AUTOMÁTICA - TPE DISEÑO DE REDES DISTRIBUIDAS
# Adaptado exactamente para TPE-4 DRD.xml (detecta /tmp/pycore.2 automáticamente)
#
# Uso en Lubuntu:
#   chmod +x configurar_tpe.bash
#   sudo ./configurar_tpe.bash todo       # Configura Parte 1, 2, 3 y 4 completas
#   sudo ./configurar_tpe.bash verificar  # Ejecuta pruebas de ping/traceroute/BGP
#   sudo ./configurar_tpe.bash parte1     # Deja el laboratorio en Parte 1 pura
#   sudo ./configurar_tpe.bash parte2     # Deja el laboratorio en Parte 1 + Parte 2
#   sudo ./configurar_tpe.bash parte3     # Deja el laboratorio en Parte 1 + 2 + 3
#   sudo ./configurar_tpe.bash parte4     # Activa Parte 4 (ADSL, SIT, RPDB, DNS, UDP)
# ==============================================================================

MODO=${1:-todo}

# 1. Buscar la sesión de CORE que realmente tenga sockets activos (ej. /tmp/pycore.2)
SESSION=""
for dir in $(ls -td /tmp/pycore.* 2>/dev/null); do
  if [ -n "$(find "$dir" -maxdepth 1 -type s 2>/dev/null)" ]; then
    SESSION="$dir"
    break
  fi
done

if [ -z "$SESSION" ]; then
  echo "[ERROR] No hay ninguna sesión de CORE con nodos activos."
  echo "Abrí TPE-4 DRD.xml en CORE y apretá el botón verde (Start)."
  exit 1
fi

echo "[OK] Sesión activa detectada en: $SESSION"

run_node() {
  local node=$1
  shift
  if [ -S "$SESSION/$node" ]; then
    vcmd -c "$SESSION/$node" -- "$@"
  else
    echo "[AVISO] El nodo $node no existe en $SESSION."
  fi
}

limpiar_router() {
  local node=$1
  run_node "$node" sh -c "
    killall ospf6d 2>/dev/null || true
    sysctl -w net.ipv4.ip_forward=1 >/dev/null
    sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null
    for f in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > \$f; done
  "
}

# ==============================================================================
# FUNCIÓN PARTE 1: OSPF EN AS6200 + RIP Y OSPF EN AS6100
# ==============================================================================
configurar_parte1() {
  echo ">>> Configurando PARTE 1 (OSPF y RIP)..."

  for r in R6101 R6102 R6103 R6104 R6201 R6202 R6203 ADSL; do
    limpiar_router "$r"
  done

  # En Parte 1, 2 o 3 apagamos temporalmente el enlace ADSL y su OSPF por defecto
  # para que las redes 210.0.0.0/24 y 220.0.1.0/24 no ensucien las tablas previas
  run_node ADSL sh -c "
    killall ospfd ospf6d 2>/dev/null || true
    ip link set eth0 down 2>/dev/null || true
    ip link set eth1 down 2>/dev/null || true
  "
  run_node R6101 sh -c "
    ip rule del prio 90 2>/dev/null || true
    ip rule del prio 100 2>/dev/null || true
    ip rule del prio 110 2>/dev/null || true
    iptables -t mangle -F PREROUTING 2>/dev/null || true
    ip route del unreachable 8.8.8.8/32 2>/dev/null || true
    ip route del unreachable 8.8.4.4/32 2>/dev/null || true
    ip link set eth2 down 2>/dev/null || true
  "
  run_node R6201 sh -c "
    ip route del blackhole 8.8.8.8/32 2>/dev/null || true
    ip route del blackhole 8.8.4.4/32 2>/dev/null || true
    ip link set eth2 down 2>/dev/null || true
  "

  # Asegurar puertas de enlace por defecto en los Hosts
  run_node H6202 sh -c "ip route replace default via 192.168.9.1"
  run_node H6201 sh -c "ip route replace default via 192.168.10.1"
  run_node H6200 sh -c "ip route replace default via 192.168.11.1"

  # --- AS6200: OSPF en R6201, R6202 y R6203 ---
  run_node R6201 vtysh \
    -c "configure terminal" \
    -c "no router bgp 6200" \
    -c "no router ospf" \
    -c "router ospf" \
    -c "ospf router-id 10.200.7.1" \
    -c "redistribute connected" \
    -c "network 10.200.7.0/24 area 0.0.0.0" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6202 vtysh \
    -c "configure terminal" \
    -c "no router ospf" \
    -c "router ospf" \
    -c "ospf router-id 10.200.7.2" \
    -c "network 10.200.7.0/24 area 0.0.0.0" \
    -c "network 10.200.8.0/24 area 0.0.0.0" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6203 vtysh \
    -c "configure terminal" \
    -c "no router ospf" \
    -c "router ospf" \
    -c "ospf router-id 10.200.8.2" \
    -c "network 10.200.8.0/24 area 0.0.0.0" \
    -c "network 192.168.11.0/24 area 0.0.0.0" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  # --- AS6100: RIP en R6103, R6104 y R6102 ---
  run_node R6103 vtysh \
    -c "configure terminal" \
    -c "no router ospf" \
    -c "no router rip" \
    -c "router rip" \
    -c "redistribute connected" \
    -c "redistribute static" \
    -c "network 10.100.0.0/24" \
    -c "network 192.168.9.0/24" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6104 vtysh \
    -c "configure terminal" \
    -c "no router ospf" \
    -c "no router rip" \
    -c "router rip" \
    -c "redistribute connected" \
    -c "redistribute static" \
    -c "network 10.100.1.0/24" \
    -c "network 192.168.10.0/24" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  # R6102: Router frontera interno (ASBR) entre RIP y OSPF
  run_node R6102 vtysh \
    -c "configure terminal" \
    -c "no router ospf" \
    -c "no router rip" \
    -c "router rip" \
    -c "redistribute connected" \
    -c "redistribute static" \
    -c "redistribute ospf" \
    -c "network 10.100.0.0/24" \
    -c "network 10.100.1.0/24" \
    -c "exit" \
    -c "router ospf" \
    -c "ospf router-id 10.100.2.1" \
    -c "redistribute connected" \
    -c "redistribute rip" \
    -c "network 10.100.2.0/24 area 0.0.0.0" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  # R6101: Router de borde de AS6100 con OSPF
  run_node R6101 vtysh \
    -c "configure terminal" \
    -c "no router bgp 6100" \
    -c "no router ospf" \
    -c "router ospf" \
    -c "ospf router-id 10.100.2.2" \
    -c "redistribute connected" \
    -c "network 10.100.2.0/24 area 0.0.0.0" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  echo "[OK] Parte 1 configurada."
}

# ==============================================================================
# FUNCIÓN PARTE 2: eBGP, LOOPBACKS + OSPF EN AS6000 E iBGP FULL MESH
# ==============================================================================
configurar_parte2() {
  echo ">>> Configurando PARTE 2 (eBGP, Loopbacks, OSPF en AS6000 e iBGP)..."

  for r in R6001 R6002 R6003; do
    limpiar_router "$r"
  done

  # --- Loopbacks y OSPF Area 0 en AS6000 (R6001, R6002, R6003) ---
  run_node R6001 vtysh \
    -c "configure terminal" \
    -c "interface lo" \
    -c "ip address 4.4.4.4/32" \
    -c "exit" \
    -c "no router ospf" \
    -c "router ospf" \
    -c "ospf router-id 4.4.4.4" \
    -c "network 4.4.4.4/32 area 0.0.0.0" \
    -c "network 100.0.4.0/24 area 0.0.0.0" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6002 vtysh \
    -c "configure terminal" \
    -c "interface lo" \
    -c "ip address 5.5.5.5/32" \
    -c "exit" \
    -c "no router ospf" \
    -c "router ospf" \
    -c "ospf router-id 5.5.5.5" \
    -c "network 5.5.5.5/32 area 0.0.0.0" \
    -c "network 100.0.4.0/24 area 0.0.0.0" \
    -c "network 200.0.5.0/24 area 0.0.0.0" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6003 vtysh \
    -c "configure terminal" \
    -c "interface lo" \
    -c "ip address 6.6.6.6/32" \
    -c "exit" \
    -c "no router ospf" \
    -c "router ospf" \
    -c "ospf router-id 6.6.6.6" \
    -c "network 6.6.6.6/32 area 0.0.0.0" \
    -c "network 200.0.5.0/24 area 0.0.0.0" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  # --- eBGP en R6101 (AS6100) y R6201 (AS6200) + Redistribución BGP -> OSPF ---
  run_node R6101 vtysh \
    -c "configure terminal" \
    -c "no router bgp 6100" \
    -c "router bgp 6100" \
    -c "bgp router-id 100.0.3.1" \
    -c "redistribute connected" \
    -c "redistribute ospf" \
    -c "neighbor 100.0.3.2 remote-as 6000" \
    -c "neighbor 100.0.3.2 next-hop-self" \
    -c "exit" \
    -c "router ospf" \
    -c "redistribute bgp" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6201 vtysh \
    -c "configure terminal" \
    -c "no router bgp 6200" \
    -c "router bgp 6200" \
    -c "bgp router-id 10.200.7.1" \
    -c "redistribute connected" \
    -c "redistribute ospf" \
    -c "neighbor 200.0.6.1 remote-as 6000" \
    -c "neighbor 200.0.6.1 next-hop-self" \
    -c "exit" \
    -c "router ospf" \
    -c "redistribute bgp" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  # --- eBGP + iBGP (Full Mesh con Loopbacks) en AS6000 ---
  run_node R6001 vtysh \
    -c "configure terminal" \
    -c "no router bgp 6000" \
    -c "router bgp 6000" \
    -c "bgp router-id 100.0.3.2" \
    -c "redistribute connected" \
    -c "redistribute ospf" \
    -c "neighbor 100.0.3.1 remote-as 6100" \
    -c "neighbor 100.0.3.1 next-hop-self" \
    -c "neighbor 5.5.5.5 remote-as 6000" \
    -c "neighbor 5.5.5.5 update-source lo" \
    -c "neighbor 5.5.5.5 next-hop-self" \
    -c "neighbor 6.6.6.6 remote-as 6000" \
    -c "neighbor 6.6.6.6 update-source lo" \
    -c "neighbor 6.6.6.6 next-hop-self" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6002 vtysh \
    -c "configure terminal" \
    -c "no router bgp 2" \
    -c "no router bgp 6000" \
    -c "router bgp 6000" \
    -c "bgp router-id 5.5.5.5" \
    -c "redistribute connected" \
    -c "redistribute ospf" \
    -c "neighbor 4.4.4.4 remote-as 6000" \
    -c "neighbor 4.4.4.4 update-source lo" \
    -c "neighbor 4.4.4.4 next-hop-self" \
    -c "neighbor 6.6.6.6 remote-as 6000" \
    -c "neighbor 6.6.6.6 update-source lo" \
    -c "neighbor 6.6.6.6 next-hop-self" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6003 vtysh \
    -c "configure terminal" \
    -c "no router bgp 6000" \
    -c "router bgp 6000" \
    -c "bgp router-id 200.0.6.1" \
    -c "redistribute connected" \
    -c "redistribute ospf" \
    -c "neighbor 200.0.6.2 remote-as 6200" \
    -c "neighbor 200.0.6.2 next-hop-self" \
    -c "neighbor 4.4.4.4 remote-as 6000" \
    -c "neighbor 4.4.4.4 update-source lo" \
    -c "neighbor 4.4.4.4 next-hop-self" \
    -c "neighbor 5.5.5.5 remote-as 6000" \
    -c "neighbor 5.5.5.5 update-source lo" \
    -c "neighbor 5.5.5.5 next-hop-self" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  echo "[OK] Parte 2 configurada."
}

# ==============================================================================
# FUNCIÓN PARTE 3: DIRECCIONAMIENTO IPv6 (GUA + ULA) Y RUTEO ESTÁTICO
# ==============================================================================
configurar_parte3() {
  echo ">>> Configurando PARTE 3 (IPv6 GUA 2001:1200::/60, ULA fd00::/48 y Ruteo Estático)..."

  # H6202 (LAN 2001:1200::/64 y fd00::/64)
  run_node H6202 sh -c "
    ip -6 addr replace 2001:1200::10/64 dev eth0
    ip -6 addr replace fd00::10/64 dev eth0
    ip -6 route replace default via 2001:1200::1 dev eth0
    ip -6 route replace fd00::/48 via fd00::1 dev eth0
  "

  # H6201 (LAN 2001:1200:0:1::/64 y fd00:0:0:1::/64)
  run_node H6201 sh -c "
    ip -6 addr replace 2001:1200:0:1::10/64 dev eth0
    ip -6 addr replace fd00:0:0:1::10/64 dev eth0
    ip -6 route replace default via 2001:1200:0:1::1 dev eth0
    ip -6 route replace fd00::/48 via fd00:0:0:1::1 dev eth0
  "

  # R6103 (eth0 -> R6102, eth1 -> H6202)
  run_node R6103 sh -c "
    ip -6 addr replace 2001:1200:0:2::1/64 dev eth0
    ip -6 addr replace fd00:0:0:2::1/64 dev eth0
    ip -6 addr replace 2001:1200::1/64 dev eth1
    ip -6 addr replace fd00::1/64 dev eth1
    ip -6 route replace default via 2001:1200:0:2::2 dev eth0
    ip -6 route replace fd00::/48 via fd00:0:0:2::2 dev eth0
  "

  # R6104 (eth0 -> R6102, eth1 -> H6201)
  run_node R6104 sh -c "
    ip -6 addr replace 2001:1200:0:3::1/64 dev eth0
    ip -6 addr replace fd00:0:0:3::1/64 dev eth0
    ip -6 addr replace 2001:1200:0:1::1/64 dev eth1
    ip -6 addr replace fd00:0:0:1::1/64 dev eth1
    ip -6 route replace default via 2001:1200:0:3::2 dev eth0
    ip -6 route replace fd00::/48 via fd00:0:0:3::2 dev eth0
  "

  # R6102 (eth0 -> R6101, eth1 -> R6103, eth2 -> R6104)
  run_node R6102 sh -c "
    ip -6 addr replace 2001:1200:0:4::1/64 dev eth0
    ip -6 addr replace fd00:0:0:4::1/64 dev eth0
    ip -6 addr replace 2001:1200:0:2::2/64 dev eth1
    ip -6 addr replace fd00:0:0:2::2/64 dev eth1
    ip -6 addr replace 2001:1200:0:3::2/64 dev eth2
    ip -6 addr replace fd00:0:0:3::2/64 dev eth2
    ip -6 route replace 2001:1200::/64 via 2001:1200:0:2::1 dev eth1
    ip -6 route replace fd00::/64 via fd00:0:0:2::1 dev eth1
    ip -6 route replace 2001:1200:0:1::/64 via 2001:1200:0:3::1 dev eth2
    ip -6 route replace fd00:0:0:1::/64 via fd00:0:0:3::1 dev eth2
    ip -6 route replace default via 2001:1200:0:4::2 dev eth0
    ip -6 route replace fd00::/48 via fd00:0:0:4::2 dev eth0
  "

  # R6101 (eth0 -> R6102)
  run_node R6101 sh -c "
    ip -6 addr replace 2001:1200:0:4::2/64 dev eth0
    ip -6 addr replace fd00:0:0:4::2/64 dev eth0
    ip -6 route replace 2001:1200::/64 via 2001:1200:0:4::1 dev eth0
    ip -6 route replace 2001:1200:0:1::/64 via 2001:1200:0:4::1 dev eth0
    ip -6 route replace 2001:1200:0:2::/64 via 2001:1200:0:4::1 dev eth0
    ip -6 route replace 2001:1200:0:3::/64 via 2001:1200:0:4::1 dev eth0
    ip -6 route replace fd00::/64 via fd00:0:0:4::1 dev eth0
    ip -6 route replace fd00:0:0:1::/64 via fd00:0:0:4::1 dev eth0
    ip -6 route replace fd00:0:0:2::/64 via fd00:0:0:4::1 dev eth0
    ip -6 route replace fd00:0:0:3::/64 via fd00:0:0:4::1 dev eth0
  "

  # H6200 (LAN 2001:1200:0:8::/64 y fd00:0:0:8::/64)
  run_node H6200 sh -c "
    ip -6 addr replace 2001:1200:0:8::10/64 dev eth0
    ip -6 addr replace fd00:0:0:8::10/64 dev eth0
    ip -6 route replace default via 2001:1200:0:8::1 dev eth0
    ip -6 route replace fd00::/48 via fd00:0:0:8::1 dev eth0
  "

  # R6203 (eth0 -> R6202, eth1 -> H6200)
  run_node R6203 sh -c "
    ip -6 addr replace 2001:1200:0:9::2/64 dev eth0
    ip -6 addr replace fd00:0:0:9::2/64 dev eth0
    ip -6 addr replace 2001:1200:0:8::1/64 dev eth1
    ip -6 addr replace fd00:0:0:8::1/64 dev eth1
    ip -6 route replace default via 2001:1200:0:9::1 dev eth0
    ip -6 route replace fd00::/48 via fd00:0:0:9::1 dev eth0
  "

  # R6202 (eth0 -> R6201, eth1 -> R6203)
  run_node R6202 sh -c "
    ip -6 addr replace 2001:1200:0:a::2/64 dev eth0
    ip -6 addr replace fd00:0:0:a::2/64 dev eth0
    ip -6 addr replace 2001:1200:0:9::1/64 dev eth1
    ip -6 addr replace fd00:0:0:9::1/64 dev eth1
    ip -6 route replace 2001:1200:0:8::/64 via 2001:1200:0:9::2 dev eth1
    ip -6 route replace fd00:0:0:8::/64 via fd00:0:0:9::2 dev eth1
    ip -6 route replace default via 2001:1200:0:a::1 dev eth0
    ip -6 route replace fd00::/48 via fd00:0:0:a::1 dev eth0
  "

  # R6201 (eth1 -> R6202)
  run_node R6201 sh -c "
    ip -6 addr replace 2001:1200:0:a::1/64 dev eth1
    ip -6 addr replace fd00:0:0:a::1/64 dev eth1
    ip -6 route replace 2001:1200:0:8::/64 via 2001:1200:0:a::2 dev eth1
    ip -6 route replace 2001:1200:0:9::/64 via 2001:1200:0:a::2 dev eth1
    ip -6 route replace fd00:0:0:8::/64 via fd00:0:0:a::2 dev eth1
    ip -6 route replace fd00:0:0:9::/64 via fd00:0:0:a::2 dev eth1
  "

  echo "[OK] Parte 3 configurada."
}

# ==============================================================================
# FUNCIÓN PARTE 4: ROUTER ADSL, TÚNEL SIT, RPDB (IP RULE), BLOQUEO DNS Y UDP
# ==============================================================================
configurar_parte4() {
  echo ">>> Configurando PARTE 4 (Router ADSL, Túnel SIT, Policy Routing, DNS y UDP)..."

  limpiar_router ADSL
  run_node ADSL vtysh -c "configure terminal" -c "no router ospf" -c "end" -c "write" >/dev/null 2>&1 || true
  run_node ADSL sh -c "
    killall ospfd ospf6d 2>/dev/null || true
    ip link set eth0 up
    ip link set eth1 up
    ip addr replace 210.0.0.2/24 dev eth0
    ip addr replace 220.0.1.1/24 dev eth1
    ip route replace 192.168.9.0/24 via 210.0.0.1
    ip route replace 192.168.10.0/24 via 210.0.0.1
    ip route replace 10.100.0.0/24 via 210.0.0.1
    ip route replace 10.100.1.0/24 via 210.0.0.1
    ip route replace 10.100.2.0/24 via 210.0.0.1
    ip route replace 192.168.11.0/24 via 220.0.1.2
    ip route replace 10.200.7.0/24 via 220.0.1.2
    ip route replace 10.200.8.0/24 via 220.0.1.2
  "

  run_node R6101 sh -c "
    ip link set eth2 up
    ip addr replace 210.0.0.1/24 dev eth2
    ip route replace 220.0.1.0/24 via 210.0.0.2
  "
  run_node R6101 vtysh \
    -c "configure terminal" \
    -c "router ospf" \
    -c "default-information originate always" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  run_node R6201 sh -c "
    ip link set eth2 up
    ip addr replace 220.0.1.2/24 dev eth2
    ip route replace 210.0.0.0/24 via 220.0.1.1
  "
  run_node R6201 vtysh \
    -c "configure terminal" \
    -c "router ospf" \
    -c "default-information originate always" \
    -c "end" \
    -c "write" >/dev/null 2>&1

  # 2. Configurar Túnel SIT (IPv6 sobre IPv4) entre R6101 y R6201
  run_node R6101 sh -c "
    ip tunnel del sit1 2>/dev/null || true
    ip tunnel add sit1 mode sit local 210.0.0.1 remote 220.0.1.2 ttl 64
    ip link set sit1 up
    ip -6 addr replace 2001:1200:0:5::1/64 dev sit1
    ip -6 addr replace fd00:0:0:5::1/64 dev sit1
    ip -6 route replace 2001:1200:0:8::/64 via 2001:1200:0:5::2 dev sit1
    ip -6 route replace 2001:1200:0:9::/64 via 2001:1200:0:5::2 dev sit1
    ip -6 route replace 2001:1200:0:a::/64 via 2001:1200:0:5::2 dev sit1
    ip -6 route replace fd00:0:0:8::/64 via fd00:0:0:5::2 dev sit1
    ip -6 route replace fd00:0:0:9::/64 via fd00:0:0:5::2 dev sit1
    ip -6 route replace fd00:0:0:a::/64 via fd00:0:0:5::2 dev sit1
  "

  run_node R6201 sh -c "
    ip tunnel del sit1 2>/dev/null || true
    ip tunnel add sit1 mode sit local 220.0.1.2 remote 210.0.0.1 ttl 64
    ip link set sit1 up
    ip -6 addr replace 2001:1200:0:5::2/64 dev sit1
    ip -6 addr replace fd00:0:0:5::2/64 dev sit1
    ip -6 route replace 2001:1200::/64 via 2001:1200:0:5::1 dev sit1
    ip -6 route replace 2001:1200:0:1::/64 via 2001:1200:0:5::1 dev sit1
    ip -6 route replace 2001:1200:0:2::/64 via 2001:1200:0:5::1 dev sit1
    ip -6 route replace 2001:1200:0:3::/64 via 2001:1200:0:5::1 dev sit1
    ip -6 route replace 2001:1200:0:4::/64 via 2001:1200:0:5::1 dev sit1
    ip -6 route replace fd00::/64 via fd00:0:0:5::1 dev sit1
    ip -6 route replace fd00:0:0:1::/64 via fd00:0:0:5::1 dev sit1
    ip -6 route replace fd00:0:0:2::/64 via fd00:0:0:5::1 dev sit1
    ip -6 route replace fd00:0:0:3::/64 via fd00:0:0:5::1 dev sit1
    ip -6 route replace fd00:0:0:4::/64 via fd00:0:0:5::1 dev sit1
  "

  # 3, 4 y 6. Policy Routing (ip rule), Bloqueo DNS con respuesta (unreachable) y UDP por BGP en R6101
  run_node R6101 sh -c "
    ip rule del prio 90 2>/dev/null || true
    ip rule del prio 100 2>/dev/null || true
    ip rule del prio 110 2>/dev/null || true
    ip route flush table 100 2>/dev/null || true
    ip route flush table 200 2>/dev/null || true

    # Punto 4: Bloquear DNS de Google en AS6100 devolviendo respuesta ICMP Unreachable
    ip route replace unreachable 8.8.8.8/32
    ip route replace unreachable 8.8.4.4/32
    ip route replace unreachable 8.8.8.8/32 table 100
    ip route replace unreachable 8.8.4.4/32 table 100
    ip route replace unreachable 8.8.8.8/32 table 200
    ip route replace unreachable 8.8.4.4/32 table 200

    # Rutas locales de AS6100 en tablas 100 y 200
    ip route replace 10.100.2.0/24 dev eth0 table 100
    ip route replace 192.168.9.0/24 via 10.100.2.1 dev eth0 table 100
    ip route replace 192.168.10.0/24 via 10.100.2.1 dev eth0 table 100
    ip route replace 10.100.2.0/24 dev eth0 table 200
    ip route replace 192.168.9.0/24 via 10.100.2.1 dev eth0 table 200
    ip route replace 192.168.10.0/24 via 10.100.2.1 dev eth0 table 200

    # Tabla 100: Salida por ADSL (210.0.0.2) para la red de Host6201 (192.168.10.0/24)
    ip route replace 192.168.11.0/24 via 210.0.0.2 table 100
    ip route replace default via 210.0.0.2 table 100

    # Tabla 200: Salida por BGP (100.0.3.2) para la red de Host6202 (192.168.9.0/24) y UDP de Host6201
    ip route replace 192.168.11.0/24 via 100.0.3.2 table 200
    ip route replace default via 100.0.3.2 table 200

    # Reglas RPDB (Punto 3 y Punto 6)
    ip rule add prio 90 fwmark 5 lookup 200
    ip rule add prio 100 from 192.168.10.0/24 lookup 100
    ip rule add prio 110 from 192.168.9.0/24 lookup 200

    # Punto 6: Marcar tráfico UDP de la red de Host6201 (192.168.10.0/24) con fwmark 5
    iptables -t mangle -F PREROUTING
    iptables -t mangle -A PREROUTING -s 192.168.10.0/24 -p udp -j MARK --set-mark 5
  "

  # 5. Bloqueo silencioso (blackhole) de los DNS de Google en AS6200 (R6201)
  run_node R6201 sh -c "
    ip route replace blackhole 8.8.8.8/32
    ip route replace blackhole 8.8.4.4/32
  "

  echo "[OK] Parte 4 configurada."
}

# ==============================================================================
# FUNCIÓN VERIFICAR: PRUEBA TODOS LOS PUNTOS DEL TPE Y MUESTRA SALIDAS
# ==============================================================================
verificar_todo() {
  echo "=== 1. Parte 1 (Punto 3): Rutas RIP en R6103 (debe incluir 100.0.3.0/24) ==="
  run_node R6103 vtysh -c "show ip route rip"

  echo ""
  echo "=== 2. Parte 2 (Punto 3): Resumen BGP en R6001, R6002 y R6003 ==="
  run_node R6001 vtysh -c "show ip bgp summary"
  run_node R6002 vtysh -c "show ip bgp summary"
  run_node R6003 vtysh -c "show ip bgp summary"

  echo ""
  echo "=== 3. Parte 2 (Punto 7): Ping extremo a extremo H6202 -> H6200 (IPv4) ==="
  run_node H6202 ping -c 3 192.168.11.10

  echo ""
  echo "=== 4. Parte 4 (Punto 2): Ping6 por Túnel SIT H6202 -> H6200 (GUA y ULA) ==="
  run_node H6202 ping6 -c 3 2001:1200:0:8::10
  run_node H6202 ping6 -c 3 fd00:0:0:8::10

  echo ""
  echo "=== 5. Parte 4 (Punto 3): Traceroute ICMP desde H6201 (por ADSL 210.0.0.2) ==="
  run_node H6201 traceroute -n -I -m 10 192.168.11.10

  echo ""
  echo "=== 6. Parte 4 (Punto 3): Traceroute ICMP desde H6202 (por BGP 100.0.3.2) ==="
  run_node H6202 traceroute -n -I -m 10 192.168.11.10

  echo ""
  echo "=== 7. Parte 4 (Punto 4 y 5): Ping a 8.8.8.8 desde H6202 (Unreachable de 10.100.2.2) y H6200 (Blackhole) ==="
  run_node H6202 ping -c 2 -W 1 8.8.8.8 || true
  run_node H6200 ping -c 2 -W 1 8.8.8.8 || true

  echo ""
  echo "=== 8. Parte 4 (Punto 6): Traceroute UDP desde H6201 (sale por BGP 100.0.3.2 gracias a fwmark 5) ==="
  run_node H6201 traceroute -n -m 10 192.168.11.10
}

# ==============================================================================
# EJECUCIÓN SEGÚN PARÁMETRO
# ==============================================================================
case "$MODO" in
  parte1)
    configurar_parte1
    ;;
  parte2)
    configurar_parte1
    configurar_parte2
    ;;
  parte3)
    configurar_parte1
    configurar_parte2
    configurar_parte3
    ;;
  parte4)
    configurar_parte4
    ;;
  verificar)
    verificar_todo
    exit 0
    ;;
  todo|*)
    configurar_parte1
    configurar_parte2
    configurar_parte3
    configurar_parte4
    ;;
esac

echo "=============================================================================="
echo "¡Configuración ($MODO) aplicada con éxito en $SESSION!"
echo "Esperá ~10 segundos y ejecutá: sudo ./configurar_tpe.bash verificar"
echo "=============================================================================="