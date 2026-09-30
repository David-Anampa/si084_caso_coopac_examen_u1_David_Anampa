#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "=== Sellando evidencias con SHA256 ==="
sha256sum evidencias/*.txt > evidencias/SHA256SUMS.txt
cat evidencias/SHA256SUMS.txt

echo ""
echo "=== Iniciando repositorio git ==="
git init -b main

echo ""
echo "=== Agregando todos los archivos ==="
git add .
git status

echo ""
echo "=== Commit inicial ==="
git commit -m "Caso COOPAC · examen practico U1"

echo ""
echo "=== Configurando remote origin ==="
git remote add origin https://github.com/David-Anampa/si084_caso_coopac_examen_u1_David_Anampa.git

echo ""
echo "=== Push a main ==="
git push -u origin main

echo ""
echo "=== Creando tag examen-u1 ==="
git tag examen-u1
git push origin examen-u1

echo ""
echo "=== LISTO: repositorio subido con tag examen-u1 ==="
