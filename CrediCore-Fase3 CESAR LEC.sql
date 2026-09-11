-- Usamos la base de datos del proyecto
USE CrediCore;
GO

-- ==========================================
-- PARTE A: CONEXIONES ENTRE TABLAS
-- ==========================================

-- 1. Unimos Creditos con Clientes usando el IdCliente
ALTER TABLE Operaciones.Creditos
ADD CONSTRAINT FK_Creditos_Clientes 
FOREIGN KEY (IdCliente) REFERENCES Operaciones.Clientes(IdCliente);
GO

-- 2. Unimos Creditos con Vehiculos usando el IdVehiculo
ALTER TABLE Operaciones.Creditos
ADD CONSTRAINT FK_Creditos_Vehiculos 
FOREIGN KEY (IdVehiculo) REFERENCES Garantias.Vehiculos(IdVehiculo);
GO

-- 3. Prueba para ver que la union funciona y no deja borrar clientes con deuda
-- Al correr esto debe dar error, porque el cliente 1 tiene un credito asignado
DELETE FROM Operaciones.Clientes 
WHERE IdCliente = 1;
GO

-- ==========================================
-- PARTE B: REPORTES JUNTANDO INFORMACION
-- ==========================================

-- 1. Reporte completo: junta info de cliente, vehiculo y credito
SELECT 
    cli.NombreCompleto AS Nombre,
    cli.Telefono,
    v.Marca,
    v.Placa,
    c.Monto,
    c.Estado
FROM Operaciones.Creditos c -- Empezamos por la tabla credito
INNER JOIN Operaciones.Clientes cli ON c.IdCliente = cli.IdCliente -- Traemos el nombre del cliente
INNER JOIN Garantias.Vehiculos v ON c.IdVehiculo = v.IdVehiculo; -- Traemos la info del carro
GO

-- 2. Clientes sin credito: buscamos a los que nunca han sacado prestamo
SELECT 
    cli.NombreCompleto AS Nombre,
    cli.Telefono
FROM Operaciones.Clientes cli -- Empezamos por todos los clientes
LEFT JOIN Operaciones.Creditos c ON cli.IdCliente = c.IdCliente -- Los juntamos con creditos
WHERE c.IdCredito IS NULL; -- Solo mostramos los que tienen vacio el IdCredito
GO

-- ==========================================
-- PARTE C: CONSULTAS CON LOGICA ANIDAD
-- ==========================================

-- 1. Buscamos creditos mayores al promedio de todos los prestamos
SELECT 
    cli.NombreCompleto AS Nombre,
    c.Monto,
    c.IdCredito
FROM Operaciones.Creditos c -- Usamos la tabla creditos
INNER JOIN Operaciones.Clientes cli ON c.IdCliente = cli.IdCliente -- Traemos info del cliente
WHERE c.Monto > ( -- Comparamos el monto contra...
    SELECT AVG(Monto) -- ... el calculo del promedio de todos los creditos
    FROM Operaciones.Creditos
);
GO

-- 2. Clientes con creditos de vehiculos viejos (anio 2011 o antes)
SELECT 
    cli.NombreCompleto AS Nombre,
    c.IdCredito AS NumeroDeCredito
FROM Operaciones.Creditos c -- Usamos la tabla creditos
INNER JOIN Operaciones.Clientes cli ON c.IdCliente = cli.IdCliente -- Traemos info del cliente
WHERE c.IdVehiculo IN ( -- Buscamos que el IdVehiculo este...
    SELECT IdVehiculo -- ... dentro de la lista de vehiculos...
    FROM Garantias.Vehiculos 
    WHERE Anio <= 2011 -- ... que sean modelo 2011 o mas viejos
);
GO