# Informe de auditoría · Core financiero de la COOPAC Santa Rosa

**SI-084 · Auditoría de Sistemas** · Examen práctico de Unidad I

| | |
|---|---|
| **Apellidos y nombres** | Anampa Pancca, David Jordan |
| **Código de estudiante** | 2022074268 |
| **URL del repositorio** | `https://github.com/David-Anampa/si084_caso_coopac_examen_u1_David_Anampa.git` |
| **Fecha** | 2026-09-30 |

## 1. Resultados de los procedimientos

| Regla | Resultado, con cifras | ¿Cumple? | Archivo de evidencia |
|---|---|---|---|
| R1 | El servicio `sr_bd` publica el puerto 5432 en `0.0.0.0:55432`, expuesto a toda la red (IPv4 e IPv6) | No | `evidencias/P1_puertos.txt` |
| R2 | La contraseña del administrador (`POSTGRES_PASSWORD`) está en texto plano en `docker-compose.yml`, línea 10 (`coopac2023`, 10 caracteres — menos de 12) | No | `evidencias/P2_credenciales.txt` |
| R3 | La cuenta `app_core` tiene el atributo `Superuser`, además de `postgres`. Solo `postgres` debería tenerlo | No | `evidencias/P3_roles.txt` |
| R4 | 16 cuentas activas pertenecen a 10 personas cesadas (cese más antiguo: 2015-12-18). Además, 22 cuentas activas no tienen documento (sin responsable), de las cuales 4 tienen perfil ADMIN | No | `evidencias/P4_cesados.txt` · `evidencias/P4_genericas.txt` |
| R5 | 23 desembolsos superan el umbral de S/ 15 000 y fueron registrados y aprobados por el mismo usuario. Monto total: S/ 709 370.47. Usuarios distintos: 21 | No | `evidencias/P5_segregacion.txt` |
| R6 | `log_connections = off` y `log_statement = none` (configurados en el `command` de `docker-compose.yml`). No se registran conexiones ni modificaciones | No | `evidencias/P6_registro.txt` |
| R7 | Último respaldo exitoso: 2025-11-14. Desde 2025-11-15 al 2025-12-31: **47 días consecutivos de error** `No space left on device`. Al restaurar `core_2025-11-14.sql`, la tabla `desembolsos` **no existe** (excluida con `--exclude-table` en `respaldo.sh`) | No | `evidencias/P7_respaldos.txt` · `evidencias/P7_restauracion.txt` |

## 2. Hallazgo 1

| Elemento | Contenido |
|---|---|
| **Título** | 23 desembolsos por S/ 709 370.47 aprobados por quien los registró, sin control de segregación |
| **Condición** | Se identificaron 23 desembolsos que superan el umbral de S/ 15 000 donde `usuario_registra = usuario_aprueba`. Monto acumulado: S/ 709 370.47; 21 usuarios distintos involucrados. Mayor caso: D00680 por S/ 161 160.52. Evidencia: `evidencias/P5_segregacion.txt` |
| **Criterio** | Regla R5 de la Política de Seguridad: *"Un desembolso que supera el umbral de aprobación no puede aprobarlo quien lo registró"*. Control: **A.5.3 – Segregación de funciones** (NTP-ISO/IEC 27001:2022) |
| **Causa** | La base de datos carece de restricción técnica (`CHECK`, trigger o procedimiento almacenado) que impida que `usuario_registra` y `usuario_aprueba` sean iguales cuando el monto supera el umbral. El control dependía solo de disciplina del operador, sin respaldo en el sistema (`01_core.sql`) |
| **Efecto** | Un empleado puede crear y aprobar un desembolso fraudulento sin cómplice. Los S/ 709 370.47 no tienen segundo par de ojos. Agravado porque `log_statement = none` impide identificar responsables mediante el registro de la base de datos |
| **Recomendación** | El Jefe de Sistemas debe implementar un `TRIGGER BEFORE INSERT OR UPDATE` en `desembolsos` que rechace cuando `usuario_registra = usuario_aprueba AND monto > umbral_aprobacion`, en **5 días hábiles**. El área de Riesgos debe auditar los 23 casos identificados en **15 días calendario** |

## 3. Hallazgo 2

| Elemento | Contenido |
|---|---|
| **Título** | Respaldo sin la tabla `desembolsos` y 47 días consecutivos de fallo — la cooperativa no puede recuperar su historial crediticio |
| **Condición** | Último respaldo exitoso: 2025-11-14. Del 2025-11-15 al 2025-12-31: 47 errores `No space left on device` en `respaldo.log`. El script `respaldo.sh` usa `--exclude-table=desembolsos`, confirmado al restaurar: solo existen `empleados` y `usuarios`, no `desembolsos`. Evidencias: `evidencias/P7_respaldos.txt` · `evidencias/P7_restauracion.txt` |
| **Criterio** | Regla R7 de la Política de Seguridad: *"Respaldo diario completo, que incluye la tabla de desembolsos. Su restauración se prueba cada trimestre"*. Control: **A.8.13 – Respaldo de la información** (NTP-ISO/IEC 27001:2022) |
| **Causa** | El Jefe de Sistemas modificó `respaldo.sh` el 01/11/2025 excluyendo `desembolsos` para reducir el tiempo de ejecución (comentario en `respaldo.sh`, línea 3). Nadie monitoreó el espacio en disco, por lo que el error `No space left on device` se repitió 47 veces sin acción correctiva |
| **Efecto** | Ante una falla del servidor, la cooperativa perdería todas las operaciones de desembolso posteriores al 2025-11-14 (4 813 registros). Ello representa la pérdida total del historial crediticio del Q4-2025. Adicionalmente, la SBS puede imponer sanciones por incumplimiento de normas de gestión de riesgo operacional |
| **Recomendación** | El Jefe de Sistemas debe: **(1)** eliminar `--exclude-table=desembolsos` de `respaldo.sh` y liberar espacio en disco **de inmediato**; **(2)** ejecutar un respaldo manual completo y verificar que incluya `desembolsos` **hoy**; **(3)** configurar alerta de disco (umbral ≥ 80 %) en **3 días hábiles**; **(4)** ejecutar y documentar prueba de restauración trimestral según política |
