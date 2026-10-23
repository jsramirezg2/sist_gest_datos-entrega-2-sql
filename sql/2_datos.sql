
-- Datos de prueba


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
(1, 'disponible',    'En el estante',             TRUE),
(2, 'prestado',      'Lo tiene un usuario',       FALSE),
(3, 'reservado',     'Apartado para una reserva', FALSE),
(4, 'en reparación', 'Dañado, fuera de servicio', FALSE),
(5, 'perdido',       'No fue devuelto',           FALSE);

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
(7,  'retraso', '2026-07-23',  7,     0, TRUE),
(10, 'retraso', '2026-08-28', 12,     0, FALSE),
(5,  'pérdida', '2026-08-30', 11, 40000, FALSE),
(6,  'daño',    '2026-08-18',  0, 80000, FALSE),
(8,  'retraso', '2026-10-14',  4,     0, FALSE);
