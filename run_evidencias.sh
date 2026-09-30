#!/bin/bash
# Script que ejecuta todos los procedimientos del examen P1-P7
set -e

echo "=== P1 - Puertos (R1) ==="
docker compose ps | tee evidencias/P1_puertos.txt

echo ""
echo "=== P2 - Credenciales (R2) ==="
grep -n "PASSWORD" docker-compose.yml | tee evidencias/P2_credenciales.txt

echo ""
echo "=== P3 - Roles/Superusuarios (R3) ==="
docker exec sr_bd psql -U postgres -d core -c "\du" | tee evidencias/P3_roles.txt

echo ""
echo "=== P4a - Cuentas de cesados (R4) ==="
docker exec sr_bd psql -U postgres -d core -c "SELECT u.usuario, e.nombre, e.fecha_cese FROM usuarios u JOIN empleados e ON e.documento = u.documento WHERE u.estado = 'activo' AND e.fecha_cese IS NOT NULL ORDER BY e.fecha_cese" | tee evidencias/P4_cesados.txt

echo ""
echo "=== P4b - Cuentas sin documento/responsable (R4) ==="
docker exec sr_bd psql -U postgres -d core -c "SELECT usuario, perfil FROM usuarios WHERE documento IS NULL AND estado = 'activo' ORDER BY perfil, usuario" | tee evidencias/P4_genericas.txt

echo ""
echo "=== P5 - Segregacion de funciones (R5) ==="
docker exec sr_bd psql -U postgres -d core -c "SELECT count(*) AS casos, sum(monto) AS monto_total, count(DISTINCT usuario_registra) AS usuarios FROM desembolsos WHERE usuario_registra = usuario_aprueba AND monto > umbral_aprobacion" | tee evidencias/P5_segregacion.txt
docker exec sr_bd psql -U postgres -d core -c "SELECT id, fecha, monto, usuario_registra FROM desembolsos WHERE usuario_registra = usuario_aprueba AND monto > umbral_aprobacion ORDER BY monto DESC" | tee -a evidencias/P5_segregacion.txt

echo ""
echo "=== P6 - Registro de conexiones y modificaciones (R6) ==="
docker exec sr_bd psql -U postgres -d core -c "SHOW log_connections" -c "SHOW log_statement" | tee evidencias/P6_registro.txt

echo ""
echo "=== P7a - Respaldos existentes (R7) ==="
ls respaldos/ | tee evidencias/P7_respaldos.txt
tail -n 5 respaldos/respaldo.log | tee -a evidencias/P7_respaldos.txt

echo ""
echo "=== P7b - Restauracion (R7) ==="
docker exec sr_bd psql -U postgres -c "DROP DATABASE IF EXISTS restauracion"
docker exec sr_bd psql -U postgres -c "CREATE DATABASE restauracion"
docker exec -i sr_bd psql -U postgres -d restauracion < respaldos/core_2025-11-14.sql
docker exec sr_bd psql -U postgres -d restauracion -c "\dt" | tee evidencias/P7_restauracion.txt

echo ""
echo "=== LISTO: todas las evidencias generadas ==="
ls -la evidencias/
