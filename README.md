# Sistema de préstamos para una biblioteca universitaria

Sistemas de Gestión de Datos — Universidad EAFIT, 2026  
Entrega 2, punto 3: implementación de la base de datos en MySQL.

Integrantes: Isabella Gómez, David Rodríguez y Juan Sebastian Ramirez.  
Profesor: César Ruiz Jaramillo.

La base de datos guarda el catálogo de una biblioteca universitaria (libros, autores, categorías y copias), sus usuarios y tipos de usuario, y los préstamos, renovaciones, reservas y multas. El modelo entidad-relación, el modelo relacional y el diccionario de datos están en el documento de la entrega.

## Archivos

| Archivo | Contenido |
| --- | --- |
| `biblioteca.sql` | Script completo para MySQL (punto 3.4): crea las tablas, carga los datos y ejecuta las consultas. Es el que se pega en SQLOnline. |
| `sql/1_tablas.sql` | Tablas con sus llaves primarias, llaves foráneas y restricciones (punto 3.1). |
| `sql/2_datos.sql` | Datos de prueba (punto 3.2). |
| `sql/3_consultas.sql` | Las 8 consultas (punto 3.3). |
| `sqlite/biblioteca_sqlite.sql` | El mismo script adaptado a SQLite, para probar en el computador sin instalar MySQL. |

## Cómo ejecutarlo

### En SQLOnline (MySQL)

1. Entrar a [sqliteonline.com](https://sqliteonline.com/) y, en el panel de la izquierda, elegir el motor **MySQL**.
2. Pegar todo el contenido de `biblioteca.sql`.
3. Ejecutar con **Run**. Se ve el resultado de cada consulta.

### En el computador con sqlite3

```bash
sqlite3 -header -column biblioteca.db < sqlite/biblioteca_sqlite.sql
```

Los dos scripts borran las tablas si ya existen, así que se pueden volver a correr. Las dos versiones dan los mismos resultados.

## 3.1 Base de datos

16 tablas:

- **Catálogo:** `categoria`, `autor`, `libro`, `libro_autor` (relación muchos a muchos entre libro y autor), `estado_ejemplar` y `ejemplar`.
- **Usuarios:** `tipo_usuario`, `usuario`, `usuario_telefono` (atributo multivaluado) y los subtipos `estudiante`, `docente` y `administrativo`.
- **Movimientos:** `prestamo`, `renovacion`, `reserva` y `multa`.

`renovacion` y `multa` son entidades débiles, así que su llave primaria incluye el préstamo al que pertenecen:

- `renovacion`: llave compuesta `(id_prestamo, numero)`. Por ejemplo, renovación 1 y renovación 2 del préstamo 4.
- `multa`: llave `id_prestamo`. Como una llave primaria no se repite, cada préstamo tiene como máximo una multa (relación 1:1).

Además de las llaves primarias y foráneas, las tablas tienen restricciones `CHECK` sencillas: valores permitidos de estados, motivos y roles, fechas coherentes y montos no negativos.

El valor de la multa no se guarda en la tabla porque es un atributo derivado: se calcula en la consulta 2 como días de retraso × tarifa diaria del tipo de usuario + cargo adicional.

## 3.2 Datos

| Tabla | Registros |
| --- | --- |
| `categoria` | 5 |
| `autor` | 6 |
| `libro` | 5 |
| `libro_autor` | 6 |
| `estado_ejemplar` | 5 |
| `ejemplar` | 7 |
| `tipo_usuario` | 5 |
| `usuario` | 15 |
| `usuario_telefono` | 6 |
| `estudiante` | 5 |
| `docente` | 5 |
| `administrativo` | 5 |
| `prestamo` | 10 |
| `renovacion` | 5 |
| `reserva` | 6 |
| `multa` | 5 |

Cada tabla tiene al menos 5 registros. Los datos son de prueba, con fechas entre julio y octubre de 2026, y cumplen las reglas de negocio del documento: límites de préstamo y de renovación por tipo de usuario, reservas solo de libros sin copias disponibles y usuarios con multas pendientes sin préstamos nuevos.

## 3.3 Consultas

Las consultas usan como fecha de corte el 22 de octubre de 2026, para que el resultado sea el mismo sin importar el día en que se ejecuten. Todas usan al menos dos tablas.

| N.º | Consulta | Usa |
| --- | --- | --- |
| 1 | Préstamos vencidos sin devolver | ORDER BY |
| 2 | Usuarios con deuda mayor a $10.000 | GROUP BY, HAVING |
| 3 | Búsqueda en el catálogo por título | LIKE |
| 4 | Copias fuera de circulación | IN |
| 5 | Usuarios con multas sin pagar | IN con subconsulta |
| 6 | Libros con dos o más reservas activas | GROUP BY, HAVING |
| 7 | Renovaciones frente al máximo permitido | GROUP BY |
| 8 | Préstamos de estudiantes por programa | GROUP BY, COUNT(DISTINCT) |

### Consulta 1. Préstamos vencidos sin devolver

Préstamos sin devolver que ya pasaron su fecha límite, del más atrasado al menos atrasado.

**Tablas:** prestamo, usuario, ejemplar, libro · **Usa:** ORDER BY

```sql
SELECT p.id AS prestamo,
       u.nombres,
       u.apellidos,
       l.titulo,
       p.fecha_prestamo,
       p.fecha_limite
FROM prestamo p
JOIN usuario u  ON u.id = p.id_usuario
JOIN ejemplar e ON e.codigo = p.codigo_ejemplar
JOIN libro l    ON l.isbn = e.isbn
WHERE p.fecha_devolucion IS NULL
  AND p.fecha_limite < '2026-10-22'
ORDER BY p.fecha_limite;
```

**Resultado:**

| prestamo | nombres | apellidos | titulo | fecha_prestamo | fecha_limite |
| --- | --- | --- | --- | --- | --- |
| 5 | Tomás | Vélez | El principito | 2026-07-10 | 2026-08-19 |
| 2 | Camila | Betancur | Dune | 2026-09-25 | 2026-10-10 |
| 3 | Sara | López | Álgebra | 2026-09-30 | 2026-10-15 |

### Consulta 2. Usuarios con deuda mayor a $10.000

Usuarios cuya deuda en multas sin pagar supera $10.000. El valor de cada multa es un atributo derivado: no se guarda, se calcula como días de retraso * tarifa diaria del tipo de usuario + cargo adicional.

**Tablas:** multa, prestamo, usuario, tipo_usuario · **Usa:** GROUP BY, HAVING

```sql
SELECT u.id,
       u.nombres,
       u.apellidos,
       tu.nombre AS tipo_usuario,
       COUNT(m.id_prestamo) AS multas_pendientes,
       SUM(m.dias_retraso * tu.tarifa_multa_dia + m.cargo_adicional) AS deuda_total
FROM multa m
JOIN prestamo p      ON p.id = m.id_prestamo
JOIN usuario u       ON u.id = p.id_usuario
JOIN tipo_usuario tu ON tu.id = u.id_tipo_usuario
WHERE m.pagada = FALSE
GROUP BY u.id, u.nombres, u.apellidos, tu.nombre
HAVING SUM(m.dias_retraso * tu.tarifa_multa_dia + m.cargo_adicional) > 10000
ORDER BY deuda_total DESC;
```

**Resultado:**

| id | nombres | apellidos | tipo_usuario | multas_pendientes | deuda_total |
| --- | --- | --- | --- | --- | --- |
| 1005 | Valeria | Ochoa | Estudiante de pregrado | 1 | 80000 |
| 1004 | Tomás | Vélez | Estudiante de posgrado | 1 | 51000 |
| 1002 | Mateo | Ríos | Estudiante de pregrado | 1 | 12000 |

### Consulta 3. Búsqueda en el catálogo por título

Libros cuyo título contiene "Física", con sus autores y su categoría.

**Tablas:** libro, libro_autor, autor, categoria · **Usa:** LIKE

```sql
SELECT l.titulo,
       a.nombres,
       a.apellidos,
       c.nombre AS categoria
FROM libro l
JOIN libro_autor la ON la.isbn = l.isbn
JOIN autor a        ON a.id = la.id_autor
JOIN categoria c    ON c.id = l.id_categoria
WHERE l.titulo LIKE '%Física%'
ORDER BY a.apellidos;
```

**Resultado:**

| titulo | nombres | apellidos | categoria |
| --- | --- | --- | --- |
| Física Vol. 1 | David | Halliday | Física |
| Física Vol. 1 | Robert | Resnick | Física |

### Consulta 4. Copias fuera de circulación

Ejemplares fuera de circulación (en reparación o perdidos).

**Tablas:** ejemplar, libro, categoria, estado_ejemplar · **Usa:** IN

```sql
SELECT e.codigo,
       l.titulo,
       ee.nombre AS estado,
       c.sala,
       e.costo_reposicion
FROM ejemplar e
JOIN libro l            ON l.isbn = e.isbn
JOIN categoria c        ON c.id = l.id_categoria
JOIN estado_ejemplar ee ON ee.id = e.id_estado
WHERE ee.nombre IN ('en reparación', 'perdido')
ORDER BY ee.nombre;
```

**Resultado:**

| codigo | titulo | estado | sala | costo_reposicion |
| --- | --- | --- | --- | --- |
| EJ-06 | Física Vol. 1 | en reparación | Sala 2 | 150000 |
| EJ-05 | El principito | perdido | Sala 3 | 40000 |

### Consulta 5. Usuarios con multas sin pagar

Usuarios con al menos una multa sin pagar. Según las reglas de negocio, estos usuarios no pueden pedir préstamos ni renovar.

**Tablas:** usuario, tipo_usuario, multa, prestamo · **Usa:** IN con subconsulta

```sql
SELECT u.id,
       u.nombres,
       u.apellidos,
       tu.nombre AS tipo_usuario
FROM usuario u
JOIN tipo_usuario tu ON tu.id = u.id_tipo_usuario
WHERE u.id IN (SELECT p.id_usuario
               FROM multa m
               JOIN prestamo p ON p.id = m.id_prestamo
               WHERE m.pagada = FALSE)
ORDER BY u.apellidos;
```

**Resultado:**

| id | nombres | apellidos | tipo_usuario |
| --- | --- | --- | --- |
| 3001 | Natalia | Giraldo | Administrativo |
| 1005 | Valeria | Ochoa | Estudiante de pregrado |
| 1002 | Mateo | Ríos | Estudiante de pregrado |
| 1004 | Tomás | Vélez | Estudiante de posgrado |

### Consulta 6. Libros con dos o más reservas activas

Libros con dos o más reservas activas y la fecha de la reserva más antigua.

**Tablas:** libro, reserva · **Usa:** GROUP BY, HAVING

```sql
SELECT l.titulo,
       COUNT(r.id) AS reservas_activas,
       MIN(r.fecha_reserva) AS reserva_mas_antigua
FROM libro l
JOIN reserva r ON r.isbn = l.isbn
WHERE r.estado = 'activa'
GROUP BY l.isbn, l.titulo
HAVING COUNT(r.id) >= 2
ORDER BY reservas_activas DESC;
```

**Resultado:**

| titulo | reservas_activas | reserva_mas_antigua |
| --- | --- | --- |
| Dune | 2 | 2026-10-05 |

### Consulta 7. Renovaciones frente al máximo permitido

Renovaciones usadas por préstamo frente al máximo permitido por el tipo de usuario.

**Tablas:** prestamo, usuario, tipo_usuario, renovacion · **Usa:** GROUP BY

```sql
SELECT p.id AS prestamo,
       u.nombres,
       u.apellidos,
       tu.nombre AS tipo_usuario,
       COUNT(r.numero) AS renovaciones_usadas,
       tu.max_renovaciones
FROM prestamo p
JOIN usuario u       ON u.id = p.id_usuario
JOIN tipo_usuario tu ON tu.id = u.id_tipo_usuario
JOIN renovacion r    ON r.id_prestamo = p.id
GROUP BY p.id, u.nombres, u.apellidos, tu.nombre, tu.max_renovaciones
ORDER BY p.id;
```

**Resultado:**

| prestamo | nombres | apellidos | tipo_usuario | renovaciones_usadas | max_renovaciones |
| --- | --- | --- | --- | --- | --- |
| 1 | Laura | Gómez | Estudiante de pregrado | 1 | 1 |
| 4 | Ana | Restrepo | Docente de planta | 2 | 3 |
| 5 | Tomás | Vélez | Estudiante de posgrado | 1 | 2 |
| 9 | Carlos | Mesa | Docente de planta | 1 | 3 |

### Consulta 8. Préstamos de estudiantes por programa

Cuántos estudiantes distintos han pedido préstamos y cuántos préstamos han hecho en total, por programa.

**Tablas:** estudiante, prestamo · **Usa:** GROUP BY, COUNT(DISTINCT)

```sql
SELECT es.programa,
       COUNT(DISTINCT es.id_usuario) AS estudiantes,
       COUNT(p.id) AS prestamos
FROM estudiante es
JOIN prestamo p ON p.id_usuario = es.id_usuario
GROUP BY es.programa
ORDER BY prestamos DESC, es.programa;
```

**Resultado:**

| programa | estudiantes | prestamos |
| --- | --- | --- |
| Ingeniería de Sistemas | 2 | 3 |
| Derecho | 1 | 1 |
| Economía | 1 | 1 |
| Maestría en Ingeniería | 1 | 1 |

## 3.4 Script

El script completo es [`biblioteca.sql`](biblioteca.sql). Corre de principio a fin en una base de datos vacía: borra las tablas si existen, las crea, inserta los datos y ejecuta las 8 consultas.
