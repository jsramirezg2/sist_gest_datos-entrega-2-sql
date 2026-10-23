-- =====================================================================
-- Sistema de Gestión de Préstamos para una Biblioteca Universitaria
-- Sistemas de Gestión de Datos — Entrega 2
-- Integrantes: Isabella Gómez, David Rodríguez, Juan Sebastian Ramirez
--
-- Versión para SQLite, para probar en el computador con sqlite3:
--   sqlite3 -header -column biblioteca.db < sqlite/biblioteca_sqlite.sql
-- Da los mismos resultados que la versión MySQL.
-- =====================================================================

-- SQLite no revisa las llaves foráneas si no se activan:
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- Tablas
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS multa;
DROP TABLE IF EXISTS reserva;
DROP TABLE IF EXISTS renovacion;
DROP TABLE IF EXISTS prestamo;
DROP TABLE IF EXISTS administrativo;
DROP TABLE IF EXISTS docente;
DROP TABLE IF EXISTS estudiante;
DROP TABLE IF EXISTS usuario_telefono;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS tipo_usuario;
DROP TABLE IF EXISTS ejemplar;
DROP TABLE IF EXISTS estado_ejemplar;
DROP TABLE IF EXISTS libro_autor;
DROP TABLE IF EXISTS libro;
DROP TABLE IF EXISTS autor;
DROP TABLE IF EXISTS categoria;

CREATE TABLE categoria (
    id           INTEGER PRIMARY KEY,
    nombre       VARCHAR(50)  NOT NULL,
    descripcion  VARCHAR(255) NULL,
    sala         VARCHAR(30)  NOT NULL
);

CREATE TABLE autor (
    id                INTEGER PRIMARY KEY,
    nombres           VARCHAR(60) NOT NULL,
    apellidos         VARCHAR(60) NOT NULL,
    nacionalidad      VARCHAR(50) NULL,
    fecha_nacimiento  DATE        NULL
);

CREATE TABLE libro (
    isbn              CHAR(13)     NOT NULL,
    titulo            VARCHAR(200) NOT NULL,
    editorial         VARCHAR(100) NULL,
    anio_publicacion  INT          NULL,
    id_categoria      INT          NOT NULL,
    PRIMARY KEY (isbn),
    FOREIGN KEY (id_categoria) REFERENCES categoria(id),
    CHECK (anio_publicacion >= 1450)
);

CREATE TABLE libro_autor (
    isbn      CHAR(13) NOT NULL,
    id_autor  INT      NOT NULL,
    PRIMARY KEY (isbn, id_autor),
    FOREIGN KEY (isbn)     REFERENCES libro(isbn),
    FOREIGN KEY (id_autor) REFERENCES autor(id)
);

CREATE TABLE estado_ejemplar (
    id                INTEGER PRIMARY KEY,
    nombre            VARCHAR(30)  NOT NULL,
    descripcion       VARCHAR(150) NULL,
    permite_prestamo  BOOLEAN      NOT NULL
);

CREATE TABLE ejemplar (
    codigo             CHAR(5)     NOT NULL,
    isbn               CHAR(13)    NOT NULL,
    id_estado          INT         NOT NULL,
    ubicacion          VARCHAR(10) NULL,
    fecha_adquisicion  DATE        NOT NULL,
    costo_reposicion   DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (codigo),
    FOREIGN KEY (isbn)      REFERENCES libro(isbn),
    FOREIGN KEY (id_estado) REFERENCES estado_ejemplar(id),
    CHECK (costo_reposicion > 0)
);

CREATE TABLE tipo_usuario (
    id                INTEGER PRIMARY KEY,
    nombre            VARCHAR(40)   NOT NULL,
    rol               VARCHAR(15)   NOT NULL,
    max_prestamos     INT           NOT NULL,
    dias_prestamo     INT           NOT NULL,
    max_renovaciones  INT           NOT NULL,
    tarifa_multa_dia  DECIMAL(10,2) NOT NULL,
    CHECK (rol IN ('estudiante', 'docente', 'administrativo')),
    CHECK (max_prestamos > 0),
    CHECK (dias_prestamo > 0),
    CHECK (max_renovaciones >= 0),
    CHECK (tarifa_multa_dia >= 0)
);

CREATE TABLE usuario (
    id               VARCHAR(15)  NOT NULL,
    nombres          VARCHAR(60)  NOT NULL,
    apellidos        VARCHAR(60)  NOT NULL,
    correo           VARCHAR(100) NOT NULL,
    id_tipo_usuario  INT          NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (id_tipo_usuario) REFERENCES tipo_usuario(id)
);

-- Atributo multivaluado USUARIO.telefono
CREATE TABLE usuario_telefono (
    id_usuario  VARCHAR(15) NOT NULL,
    telefono    VARCHAR(10) NOT NULL,
    PRIMARY KEY (id_usuario, telefono),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id)
);

-- Subtipos de USUARIO (especialización total y disyunta)
CREATE TABLE estudiante (
    id_usuario  VARCHAR(15) NOT NULL,
    programa    VARCHAR(80) NOT NULL,
    semestre    INT         NOT NULL,
    PRIMARY KEY (id_usuario),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id),
    CHECK (semestre BETWEEN 1 AND 12)
);

CREATE TABLE docente (
    id_usuario    VARCHAR(15) NOT NULL,
    departamento  VARCHAR(80) NOT NULL,
    oficina       VARCHAR(20) NULL,
    PRIMARY KEY (id_usuario),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id)
);

CREATE TABLE administrativo (
    id_usuario   VARCHAR(15) NOT NULL,
    dependencia  VARCHAR(80) NOT NULL,
    cargo        VARCHAR(60) NOT NULL,
    PRIMARY KEY (id_usuario),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id)
);

CREATE TABLE prestamo (
    id                INTEGER PRIMARY KEY,
    id_usuario        VARCHAR(15) NOT NULL,
    codigo_ejemplar   CHAR(5)     NOT NULL,
    fecha_prestamo    DATE        NOT NULL,
    fecha_limite      DATE        NOT NULL,
    fecha_devolucion  DATE        NULL,
    FOREIGN KEY (id_usuario)      REFERENCES usuario(id),
    FOREIGN KEY (codigo_ejemplar) REFERENCES ejemplar(codigo),
    CHECK (fecha_limite >= fecha_prestamo),
    CHECK (fecha_devolucion >= fecha_prestamo)
);

-- Entidad débil: una renovación se identifica por su préstamo y su número
-- (renovación 1 del préstamo 4, renovación 2 del préstamo 4, ...).
CREATE TABLE renovacion (
    id_prestamo            INT  NOT NULL,
    numero                 INT  NOT NULL,
    fecha_renovacion       DATE NOT NULL,
    fecha_limite_anterior  DATE NOT NULL,
    fecha_limite_nueva     DATE NOT NULL,
    PRIMARY KEY (id_prestamo, numero),
    FOREIGN KEY (id_prestamo) REFERENCES prestamo(id),
    CHECK (numero >= 1),
    CHECK (fecha_limite_nueva > fecha_limite_anterior),
    CHECK (fecha_renovacion <= fecha_limite_anterior)
);

CREATE TABLE reserva (
    id                INTEGER PRIMARY KEY,
    id_usuario        VARCHAR(15) NOT NULL,
    isbn              CHAR(13)    NOT NULL,
    fecha_reserva     DATE        NOT NULL,
    fecha_expiracion  DATE        NOT NULL,
    estado            VARCHAR(10) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id),
    FOREIGN KEY (isbn)       REFERENCES libro(isbn),
    CHECK (estado IN ('activa', 'atendida', 'cancelada', 'vencida')),
    CHECK (fecha_expiracion >= fecha_reserva)
);

-- Entidad débil: la llave primaria de multa es el préstamo que la genera.
-- Como una llave primaria no se repite, cada préstamo tiene como máximo una multa.
-- El valor de la multa no se guarda: es un atributo derivado y se calcula en la
-- consulta 2 como dias_retraso * tarifa diaria del tipo de usuario + cargo_adicional.
CREATE TABLE multa (
    id_prestamo       INT           NOT NULL,
    motivo            VARCHAR(10)   NOT NULL,
    fecha_generacion  DATE          NOT NULL,
    dias_retraso      INT           NOT NULL DEFAULT 0,
    cargo_adicional   DECIMAL(10,2) NOT NULL DEFAULT 0,
    pagada            BOOLEAN       NOT NULL DEFAULT 0,
    PRIMARY KEY (id_prestamo),
    FOREIGN KEY (id_prestamo) REFERENCES prestamo(id),
    CHECK (motivo IN ('retraso', 'daño', 'pérdida')),
    CHECK (dias_retraso >= 0),
    CHECK (cargo_adicional >= 0)
);

-- ---------------------------------------------------------------------
-- Datos
-- ---------------------------------------------------------------------

INSERT INTO categoria (id, nombre, descripcion, sala) VALUES
(1, 'Literatura',      'Novela y cuento',        'Sala 1'),
(2, 'Ciencia ficción', 'Novelas de ciencia ficción', 'Sala 1'),
(3, 'Matemáticas',     'Álgebra y cálculo',      'Sala 2'),
(4, 'Física',          'Física general',         'Sala 2'),
(5, 'Infantil',        'Libros para niños',      'Sala 3');

INSERT INTO autor (id, nombres, apellidos, nacionalidad, fecha_nacimiento) VALUES
(1, 'Gabriel', 'García Márquez',   'Colombiana',     '1927-03-06'),
(2, 'Frank',   'Herbert',          'Estadounidense', '1920-10-08'),
(3, 'Aurelio', 'Baldor',           'Cubana',         '1906-10-22'),
(4, 'Antoine', 'de Saint-Exupéry', 'Francesa',       '1900-06-29'),
(5, 'David',   'Halliday',         'Estadounidense', '1916-03-03'),
(6, 'Robert',  'Resnick',          'Estadounidense', '1923-01-11');

INSERT INTO libro (isbn, titulo, editorial, anio_publicacion, id_categoria) VALUES
('9780307474728', 'Cien años de soledad', 'Sudamericana', 1967, 1),
('9780441172719', 'Dune',                 'Chilton Books', 1965, 2),
('9786075502083', 'Álgebra',              'Patria',        1941, 3),
('9788478887194', 'El principito',        'Salamandra',    1943, 5),
('9789702402572', 'Física Vol. 1',        'Patria',        1960, 4);

INSERT INTO libro_autor (isbn, id_autor) VALUES
('9780307474728', 1),
('9780441172719', 2),
('9786075502083', 3),
('9788478887194', 4),
('9789702402572', 5),
('9789702402572', 6);

INSERT INTO estado_ejemplar (id, nombre, descripcion, permite_prestamo) VALUES
(1, 'disponible',    'En el estante',             1),
(2, 'prestado',      'Lo tiene un usuario',       0),
(3, 'reservado',     'Apartado para una reserva', 0),
(4, 'en reparación', 'Dañado, fuera de servicio', 0),
(5, 'perdido',       'No fue devuelto',           0);

INSERT INTO ejemplar (codigo, isbn, id_estado, ubicacion, fecha_adquisicion, costo_reposicion) VALUES
('EJ-01', '9780307474728', 2, 'E1-N1', '2023-02-10', 60000),
('EJ-02', '9780307474728', 1, 'E1-N1', '2023-02-10', 60000),
('EJ-03', '9780441172719', 2, 'E1-N2', '2024-01-15', 70000),
('EJ-04', '9786075502083', 2, 'E2-N1', '2022-07-14', 90000),
('EJ-05', '9788478887194', 5, NULL,    '2021-03-05', 40000),
('EJ-06', '9789702402572', 4, 'E2-N2', '2020-08-19', 150000),
('EJ-07', '9780441172719', 3, 'E1-N2', '2024-01-15', 70000);

INSERT INTO tipo_usuario (id, nombre, rol, max_prestamos, dias_prestamo, max_renovaciones, tarifa_multa_dia) VALUES
(1, 'Estudiante de pregrado', 'estudiante',     3, 15, 1, 1000),
(2, 'Estudiante de posgrado', 'estudiante',     5, 20, 2, 1000),
(3, 'Docente de planta',      'docente',        8, 30, 3,  500),
(4, 'Docente de cátedra',     'docente',        5, 30, 2,  500),
(5, 'Administrativo',         'administrativo', 3, 15, 1, 1000);

INSERT INTO usuario (id, nombres, apellidos, correo, id_tipo_usuario) VALUES
('1001', 'Laura',    'Gómez',    'lgomez@u.edu.co',    1),
('1002', 'Mateo',    'Ríos',     'mrios@u.edu.co',     1),
('1003', 'Sara',     'López',    'slopez@u.edu.co',    1),
('1004', 'Tomás',    'Vélez',    'tvelez@u.edu.co',    2),
('1005', 'Valeria',  'Ochoa',    'vochoa@u.edu.co',    1),
('2001', 'Ana',      'Restrepo', 'arestrepo@u.edu.co', 3),
('2002', 'Carlos',   'Mesa',     'cmesa@u.edu.co',     3),
('2003', 'Paula',    'Correa',   'pcorrea@u.edu.co',   4),
('2004', 'Jorge',    'Castaño',  'jcastano@u.edu.co',  3),
('2005', 'Felipe',   'Arango',   'farango@u.edu.co',   4),
('3001', 'Natalia',  'Giraldo',  'ngiraldo@u.edu.co',  5),
('3002', 'Daniel',   'Osorio',   'dosorio@u.edu.co',   5),
('3003', 'Marcela',  'Patiño',   'mpatino@u.edu.co',   5),
('3004', 'Andrés',   'Rendón',   'arendon@u.edu.co',   5),
('3005', 'Camila',   'Betancur', 'cbetancur@u.edu.co', 5);

INSERT INTO usuario_telefono (id_usuario, telefono) VALUES
('1001', '3001234567'),
('1001', '6044441234'),
('1002', '3104567890'),
('2001', '3207418529'),
('3001', '6042619510'),
('3002', '3189990011');

INSERT INTO estudiante (id_usuario, programa, semestre) VALUES
('1001', 'Ingeniería de Sistemas',  4),
('1002', 'Ingeniería de Sistemas',  6),
('1003', 'Derecho',                 3),
('1004', 'Maestría en Ingeniería',  2),
('1005', 'Economía',                5);

INSERT INTO docente (id_usuario, departamento, oficina) VALUES
('2001', 'Matemáticas', '38-412'),
('2002', 'Sistemas',    '19-501'),
('2003', 'Física',      NULL),
('2004', 'Física',      '38-305'),
('2005', 'Humanidades', NULL);

INSERT INTO administrativo (id_usuario, dependencia, cargo) VALUES
('3001', 'Biblioteca',  'Auxiliar'),
('3002', 'Admisiones',  'Analista'),
('3003', 'Tesorería',   'Coordinadora'),
('3004', 'Tecnología',  'Soporte'),
('3005', 'Bienestar',   'Profesional');

-- fecha_limite guarda la fecha límite vigente (ya incluye las renovaciones)
INSERT INTO prestamo (id, id_usuario, codigo_ejemplar, fecha_prestamo, fecha_limite, fecha_devolucion) VALUES
(1,  '1001', 'EJ-01', '2026-10-10', '2026-11-09', NULL),
(2,  '3005', 'EJ-03', '2026-09-25', '2026-10-10', NULL),
(3,  '1003', 'EJ-04', '2026-09-30', '2026-10-15', NULL),
(4,  '2001', 'EJ-02', '2026-08-01', '2026-10-30', '2026-10-05'),
(5,  '1004', 'EJ-05', '2026-07-10', '2026-08-19', NULL),
(6,  '1005', 'EJ-06', '2026-08-03', '2026-08-18', '2026-08-18'),
(7,  '1001', 'EJ-02', '2026-07-01', '2026-07-16', '2026-07-23'),
(8,  '3001', 'EJ-07', '2026-09-25', '2026-10-10', '2026-10-14'),
(9,  '2002', 'EJ-03', '2026-08-01', '2026-09-30', '2026-09-10'),
(10, '1002', 'EJ-01', '2026-08-01', '2026-08-16', '2026-08-28');

INSERT INTO renovacion (id_prestamo, numero, fecha_renovacion, fecha_limite_anterior, fecha_limite_nueva) VALUES
(1, 1, '2026-10-20', '2026-10-25', '2026-11-09'),
(4, 1, '2026-08-31', '2026-08-31', '2026-09-30'),
(4, 2, '2026-09-25', '2026-09-30', '2026-10-30'),
(5, 1, '2026-07-28', '2026-07-30', '2026-08-19'),
(9, 1, '2026-08-28', '2026-08-31', '2026-09-30');

INSERT INTO reserva (id, id_usuario, isbn, fecha_reserva, fecha_expiracion, estado) VALUES
(1, '2005', '9780441172719', '2026-10-05', '2026-10-25', 'activa'),
(2, '3002', '9780441172719', '2026-10-12', '2026-11-01', 'activa'),
(3, '2004', '9786075502083', '2026-10-16', '2026-11-05', 'activa'),
(4, '1003', '9780307474728', '2026-08-10', '2026-08-30', 'atendida'),
(5, '3004', '9789702402572', '2026-09-10', '2026-09-30', 'vencida'),
(6, '3005', '9788478887194', '2026-08-15', '2026-09-04', 'cancelada');

INSERT INTO multa (id_prestamo, motivo, fecha_generacion, dias_retraso, cargo_adicional, pagada) VALUES
(7,  'retraso', '2026-07-23',  7,     0, 1),
(10, 'retraso', '2026-08-28', 12,     0, 0),
(5,  'pérdida', '2026-08-30', 11, 40000, 0),
(6,  'daño',    '2026-08-18',  0, 80000, 0),
(8,  'retraso', '2026-10-14',  4,     0, 0);

-- ---------------------------------------------------------------------
-- Consultas (fecha de corte: 22 de octubre de 2026)
-- ---------------------------------------------------------------------

-- Consulta 1 (ORDER BY): préstamos sin devolver que ya pasaron su fecha límite,
-- del más atrasado al menos atrasado.
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

-- Consulta 2 (HAVING): usuarios cuya deuda en multas sin pagar supera $10.000.
-- El valor de cada multa es un atributo derivado: no se guarda, se calcula como
-- días de retraso * tarifa diaria del tipo de usuario + cargo adicional.
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
WHERE m.pagada = 0
GROUP BY u.id, u.nombres, u.apellidos, tu.nombre
HAVING SUM(m.dias_retraso * tu.tarifa_multa_dia + m.cargo_adicional) > 10000
ORDER BY deuda_total DESC;

-- Consulta 3 (LIKE): libros cuyo título contiene "Física", con sus autores y su categoría.
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

-- Consulta 4 (IN): ejemplares fuera de circulación (en reparación o perdidos).
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

-- Consulta 5 (IN con subconsulta): usuarios con al menos una multa sin pagar.
-- Según las reglas de negocio, estos usuarios no pueden pedir préstamos ni renovar.
SELECT u.id,
       u.nombres,
       u.apellidos,
       tu.nombre AS tipo_usuario
FROM usuario u
JOIN tipo_usuario tu ON tu.id = u.id_tipo_usuario
WHERE u.id IN (SELECT p.id_usuario
               FROM multa m
               JOIN prestamo p ON p.id = m.id_prestamo
               WHERE m.pagada = 0)
ORDER BY u.apellidos;

-- Consulta 6 (HAVING): libros con dos o más reservas activas y la fecha de la reserva más antigua.
SELECT l.titulo,
       COUNT(r.id) AS reservas_activas,
       MIN(r.fecha_reserva) AS reserva_mas_antigua
FROM libro l
JOIN reserva r ON r.isbn = l.isbn
WHERE r.estado = 'activa'
GROUP BY l.isbn, l.titulo
HAVING COUNT(r.id) >= 2
ORDER BY reservas_activas DESC;

-- Consulta 7: renovaciones usadas por préstamo frente al máximo permitido por el tipo de usuario.
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

-- Consulta 8: cuántos estudiantes distintos han pedido préstamos y cuántos préstamos
-- han hecho en total, por programa.
SELECT es.programa,
       COUNT(DISTINCT es.id_usuario) AS estudiantes,
       COUNT(p.id) AS prestamos
FROM estudiante es
JOIN prestamo p ON p.id_usuario = es.id_usuario
GROUP BY es.programa
ORDER BY prestamos DESC, es.programa;
