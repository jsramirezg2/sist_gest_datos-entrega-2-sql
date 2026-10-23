
-- 3.3 Consultas



-- Consulta 1 -> prestamos sin devolver con fechcha vencida
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

-- Consulta 2: usuarios con deuda en multas sin pagar qye supera $10.000.
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

-- Consulta 3: libros con título que contiene "Física", con sus autores y su categoría.
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

-- Consulta 4: ejemplares fuera de circulación.
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

-- Consulta 5: usuarios con al menos una multa sin pagar.
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

-- Consulta 6): libros con dos o más reservas activas y la fecha de la reserva más antigua.
SELECT l.titulo,
       COUNT(r.id) AS reservas_activas,
       MIN(r.fecha_reserva) AS reserva_mas_antigua
FROM libro l
JOIN reserva r ON r.isbn = l.isbn
WHERE r.estado = 'activa'
GROUP BY l.isbn, l.titulo
HAVING COUNT(r.id) >= 2
ORDER BY reservas_activas DESC;

-- Consulta 7: renovaciones usadas por préstamo frente al máximo permitido por el su ti0po de usuario.
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

-- Consulta 8: cuántos estudiantes distintos han pedido préstamos y cuántos préstamos en total por program,a
SELECT es.programa,
       COUNT(DISTINCT es.id_usuario) AS estudiantes,
       COUNT(p.id) AS prestamos
FROM estudiante es
JOIN prestamo p ON p.id_usuario = es.id_usuario
GROUP BY es.programa
ORDER BY prestamos DESC, es.programa;
