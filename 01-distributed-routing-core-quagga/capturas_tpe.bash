#!/bin/bash
# ==============================================================================
# CAPTURAS Y VARIANTE IPTABLES PARA LA REDEFENSA - TPE DRD
# Complemento de configurar_tpe.bash (misma deteccion de sesion CORE).
#
# Uso (en Lubuntu, con el escenario ya configurado con "todo"):
#   sudo ./capturas_tpe.bash tablas     # show ip route / bgp de TODOS los routers (Parte 1 pto 5, Parte 2)
#   sudo ./capturas_tpe.bash ipv6       # ip -6 addr / ip -6 route de TODOS los equipos (Parte 3 pto 3 y 4)
#   sudo ./capturas_tpe.bash parte4     # ip rule, tablas 100/200, mangle, tunel sit, rutas ADSL
#   sudo ./capturas_tpe.bash iptables   # cambia el bloqueo DNS a iptables (REJECT en R6101, DROP en R6201)
#   sudo ./capturas_tpe.bash ipr        # vuelve al bloqueo con ip route (unreachable / blackhole)
#   sudo ./capturas_tpe.bash bgpwait    # espera a que BGP converja (hasta ~4 min) y avisa
#
# Tip: para guardar todo en un archivo y despues abrirlo:
#   sudo ./capturas_tpe.bash tablas > tablas.txt 2>&1
# ==============================================================================

MODO=${1:-tablas}

SESSION=""
for dir in $(ls -td /tmp/pycore.* 2>/dev/null); do
  if [ -n "$(find "$dir" -maxdepth 1 -type s 2>/dev/null)" ]; then
    SESSION="$dir"
    break
  fi
done

if [ -z "$SESSION" ]; then
  echo "[ERROR] No hay ninguna sesion de CORE con nodos activos."
  exit 1
fi

run_node() {
  local node=$1
  shift
  if [ -S "$SESSION/$node" ]; then
    vcmd -c "$SESSION/$node" -- "$@"
  else
    echo "[AVISO] El nodo $node no existe en $SESSION."
  fi
}

titulo() {
  echo ""
  echo "################################################################"
  echo "# $1"
  echo "################################################################"
}

tablas() {
  for r in R6001 R6002 R6003 R6101 R6102 R6103 R6104 R6201 R6202 R6203 ADSL; do
    titulo "$r# show ip route"
    run_node "$r" vtysh -c "show ip route"
  done
  for r in R6001 R6002 R6003 R6101 R6201; do
    titulo "$r# show ip bgp summary"
    run_node "$r" vtysh -c "show ip bgp summary"
  done
  for r in R6101 R6201; do
    titulo "$r# show ip bgp   (columna Path: el origen es ? porque se usa redistribute)"
    run_node "$r" vtysh -c "show ip bgp"
  done
  for h in H6202 H6201 H6200; do
    titulo "$h# ip route"
    run_node "$h" ip route
  done
}

ipv6() {
  for n in H6202 H6201 H6200 R6101 R6102 R6103 R6104 R6201 R6202 R6203; do
    titulo "$n# ip -6 addr"
    run_node "$n" ip -6 addr show scope global
    titulo "$n# ip -6 route"
    run_node "$n" ip -6 route
  done
}

parte4() {
  titulo "R6101# ip rule show"
  run_node R6101 ip rule show
  titulo "R6101# ip route show table 100"
  run_node R6101 ip route show table 100
  titulo "R6101# ip route show table 200"
  run_node R6101 ip route show table 200
  titulo "R6101# ip route show 8.8.8.8"
  run_node R6101 ip route show 8.8.8.8
  titulo "R6101# iptables -t mangle -L PREROUTING -v -n"
  run_node R6101 iptables -t mangle -L PREROUTING -v -n
  titulo "R6101# iptables -L FORWARD -v -n"
  run_node R6101 iptables -L FORWARD -v -n
  titulo "R6101# ip tunnel show / ip -6 route (sit1)"
  run_node R6101 ip tunnel show
  run_node R6101 ip -6 route show dev sit1
  titulo "R6201# ip tunnel show / ip -6 route (sit1)"
  run_node R6201 ip tunnel show
  run_node R6201 ip -6 route show dev sit1
  titulo "R6201# ip route show 8.8.8.8  y  iptables -t raw -L PREROUTING"
  run_node R6201 ip route show 8.8.8.8
  run_node R6201 iptables -t raw -L PREROUTING -v -n
  titulo "ADSL# ip route"
  run_node ADSL ip route
}

variante_iptables() {
  echo ">>> Pasando el bloqueo de DNS de Google a iptables..."
  # AS6100 (R6101): respuesta ICMP -> REJECT. Antes hay que sacar la ruta unreachable
  # de main y de las tablas 100/200, si no el paquete ya muere por la ruta.
  run_node R6101 sh -c "
    ip route del unreachable 8.8.8.8/32 2>/dev/null || true
    ip route del unreachable 8.8.4.4/32 2>/dev/null || true
    ip route del unreachable 8.8.8.8/32 table 100 2>/dev/null || true
    ip route del unreachable 8.8.4.4/32 table 100 2>/dev/null || true
    ip route del unreachable 8.8.8.8/32 table 200 2>/dev/null || true
    ip route del unreachable 8.8.4.4/32 table 200 2>/dev/null || true
    iptables -F FORWARD
    iptables -A FORWARD -d 8.8.8.8/32 -j REJECT --reject-with icmp-host-unreachable
    iptables -A FORWARD -d 8.8.4.4/32 -j REJECT --reject-with icmp-host-unreachable
  "
  # AS6200 (R6201): sin respuesta -> DROP. Se usa la tabla raw/PREROUTING porque
  # en FORWARD el kernel ya pudo haber contestado "network unreachable" por falta de ruta.
  run_node R6201 sh -c "
    ip route del blackhole 8.8.8.8/32 2>/dev/null || true
    ip route del blackhole 8.8.4.4/32 2>/dev/null || true
    iptables -t raw -F PREROUTING
    iptables -t raw -A PREROUTING -d 8.8.8.8/32 -j DROP
    iptables -t raw -A PREROUTING -d 8.8.4.4/32 -j DROP
  "
  echo "[OK] Probar: H6202 -> ping 8.8.8.8 (debe responder 'Destination Host Unreachable' desde 10.100.2.2)"
  echo "           H6200 -> ping 8.8.8.8 (100% perdida, sin respuesta)"
}

variante_ip_route() {
  echo ">>> Volviendo al bloqueo con ip route..."
  run_node R6101 sh -c "
    iptables -F FORWARD
    ip route replace unreachable 8.8.8.8/32
    ip route replace unreachable 8.8.4.4/32
    ip route replace unreachable 8.8.8.8/32 table 100
    ip route replace unreachable 8.8.4.4/32 table 100
    ip route replace unreachable 8.8.8.8/32 table 200
    ip route replace unreachable 8.8.4.4/32 table 200
  "
  run_node R6201 sh -c "
    iptables -t raw -F PREROUTING
    ip route replace blackhole 8.8.8.8/32
    ip route replace blackhole 8.8.4.4/32
  "
  echo "[OK] Restaurado."
}

esperar_bgp() {
  echo ">>> Esperando a que las sesiones BGP de R6001, R6002 y R6003 esten Established..."
  local i
  for i in $(seq 1 48); do
    local faltan=0
    for r in R6001 R6002 R6003; do
      # Una sesion no establecida muestra Idle / Active / Connect en State/PfxRcd
      if run_node "$r" vtysh -c "show ip bgp summary" 2>/dev/null | grep -Eq "Idle|Active|Connect|OpenSent|OpenConfirm"; then
        faltan=1
      fi
    done
    if [ "$faltan" -eq 0 ]; then
      echo "[OK] BGP convergio (tardo ~$((i*5)) s). Ya podes correr: sudo ./configurar_tpe.bash verificar"
      return 0
    fi
    sleep 5
  done
  echo "[AVISO] Pasaron 4 minutos y alguna sesion BGP sigue sin establecerse. Revisar con: show ip bgp summary"
  return 1
}

case "$MODO" in
  tablas)   tablas ;;
  ipv6)     ipv6 ;;
  parte4)   parte4 ;;
  iptables) variante_iptables ;;
  ipr)      variante_ip_route ;;
  bgpwait)  esperar_bgp ;;
  *) echo "Modo desconocido: $MODO (usar tablas | ipv6 | parte4 | iptables | ipr | bgpwait)"; exit 1 ;;
esac
