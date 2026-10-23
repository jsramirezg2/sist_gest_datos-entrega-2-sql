# Sistema de préstamos para una biblioteca universitaria

Sistemas de Gestión de Datos — Universidad EAFIT, 2026  
Entrega 2, punto 3: implementación de la base de datos en MySQL.

**Integrantes:** Isabella Gómez, David Rodríguez y Juan Sebastian Ramirez.  
**Profesor:** César Ruiz Jaramillo.

Base de datos para el catálogo de una biblioteca universitaria (libros, autores, categorías y copias), sus usuarios, y los préstamos, renovaciones, reservas y multas. El modelo entidad-relación, el modelo relacional y el diccionario de datos están en el documento de la entrega.

## Archivos

| Archivo | Contenido |
| --- | --- |
| `biblioteca.sql` | Script completo: crea las tablas, carga los datos y ejecuta las consultas. |
| `sql/1_tablas.sql` | Tablas y restricciones (punto 3.1). |
| `sql/2_datos.sql` | Datos de prueba (punto 3.2). |
| `sql/3_consultas.sql` | Las 8 consultas (punto 3.3). |
| `sqlite/biblioteca_sqlite.sql` | El mismo script adaptado a SQLite. |

## Cómo ejecutarlo

**En SQLOnline (MySQL):** entrar a [sqliteonline.com](https://sqliteonline.com/), elegir el motor **MySQL**, pegar el contenido de `biblioteca.sql` y darle **Run**.

**En el computador con sqlite3:**

```bash
sqlite3 -header -column biblioteca.db < sqlite/biblioteca_sqlite.sql
```

Los scripts borran las tablas si ya existen, así que se pueden correr varias veces.

## Guía rápida de sqlite3

Instalarlo (si no está):

```bash
sudo apt install sqlite3      # Ubuntu / Debian
sudo pacman -S sqlite         # Arch
brew install sqlite           # macOS
```

En Windows se descarga de [sqlite.org/download.html](https://sqlite.org/download.html) ("sqlite-tools").

Correr el script completo (crea `biblioteca.db` y muestra los resultados de las consultas):

```bash
sqlite3 -header -column biblioteca.db < sqlite/biblioteca_sqlite.sql
```

- `-header` muestra el nombre de las columnas.
- `-column` muestra los resultados alineados en columnas.

Abrir la base de datos para escribir consultas a mano:

```bash
sqlite3 biblioteca.db
```

Comandos útiles dentro de sqlite3 (empiezan con punto y no llevan `;`):

| Comando | Qué hace |
| --- | --- |
| `.tables` | Lista las tablas. |
| `.schema prestamo` | Muestra cómo se creó la tabla `prestamo`. |
| `.headers on` | Muestra el nombre de las columnas. |
| `.mode column` | Muestra los resultados en columnas. |
| `.read sqlite/biblioteca_sqlite.sql` | Ejecuta un archivo `.sql`. |
| `.quit` | Sale de sqlite3. |

Las consultas SQL normales sí terminan en `;`, por ejemplo:

```sql
SELECT * FROM libro;
```
