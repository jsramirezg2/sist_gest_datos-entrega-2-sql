-- =====================================================================
-- Sistema de Gestión de Préstamos para una Biblioteca Universitaria
-- Sistemas de Gestión de Datos — Entrega 2
-- Integrantes: Isabella Gómez, David Rodríguez, Juan Sebastian Ramirez
--
-- 3.1 Base de datos: tablas y relaciones (MySQL)
-- =====================================================================

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
    id           INT          NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(50)  NOT NULL,
    descripcion  VARCHAR(255) NULL,
    sala         VARCHAR(30)  NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE autor (
    id                INT         NOT NULL AUTO_INCREMENT,
    nombres           VARCHAR(60) NOT NULL,
    apellidos         VARCHAR(60) NOT NULL,
    nacionalidad      VARCHAR(50) NULL,
    fecha_nacimiento  DATE        NULL,
    PRIMARY KEY (id)
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
    id                INT          NOT NULL AUTO_INCREMENT,
    nombre            VARCHAR(30)  NOT NULL,
    descripcion       VARCHAR(150) NULL,
    permite_prestamo  BOOLEAN      NOT NULL,
    PRIMARY KEY (id)
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
    id                INT           NOT NULL AUTO_INCREMENT,
    nombre            VARCHAR(40)   NOT NULL,
    rol               VARCHAR(15)   NOT NULL,
    max_prestamos     INT           NOT NULL,
    dias_prestamo     INT           NOT NULL,
    max_renovaciones  INT           NOT NULL,
    tarifa_multa_dia  DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id),
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
    id                INT         NOT NULL AUTO_INCREMENT,
    id_usuario        VARCHAR(15) NOT NULL,
    codigo_ejemplar   CHAR(5)     NOT NULL,
    fecha_prestamo    DATE        NOT NULL,
    fecha_limite      DATE        NOT NULL,
    fecha_devolucion  DATE        NULL,
    PRIMARY KEY (id),
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
    id                INT         NOT NULL AUTO_INCREMENT,
    id_usuario        VARCHAR(15) NOT NULL,
    isbn              CHAR(13)    NOT NULL,
    fecha_reserva     DATE        NOT NULL,
    fecha_expiracion  DATE        NOT NULL,
    estado            VARCHAR(10) NOT NULL,
    PRIMARY KEY (id),
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
    pagada            BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_prestamo),
    FOREIGN KEY (id_prestamo) REFERENCES prestamo(id),
    CHECK (motivo IN ('retraso', 'daño', 'pérdida')),
    CHECK (dias_retraso >= 0),
    CHECK (cargo_adicional >= 0)
);
