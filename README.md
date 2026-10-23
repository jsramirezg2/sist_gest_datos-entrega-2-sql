# Sistema de préstamos para una biblioteca universitaria

Sistemas de Gestión de Datos — Universidad EAFIT, 2026  
punto 3: implementación de la base de datos en MySQL.

**Equipo:** Isabella Gómez, David Rodríguez y Juan Sebastian Ramirez.  
**Profesor:** César Ruiz Jaramillo.

 El modelo entidad-relación, el modelo relacional y el diccionario de datos están en el documento de la entrega.

## Archivos

- `biblioteca.sql`: Script completo: crea las tablas, carga los datos y ejecuta las consultas.
- `sql/1_tablas.sql`: Tablas y sus restricciones
- `sql/2_datos.sql`: Datos de prueba ingresados a la tabla
- `sql/3_consultas.sql`: Las 8 consultas
- `sqlite/biblioteca_sqlite.sql`: sqlite para pruebas y uso comodo en pc mientras lo desarrollabamos.

## RECORDAR

- ejecutar en SQLOnline

- cargar la base de datos de sqlite en pc con:  sqlite3 -header -column biblioteca.db < sqlite/biblioteca_sqlite.sql