USE CrediCore;
GO

INSERT INTO Operaciones.Creditos (IdCliente, IdVehiculo, MontoCapital, TasaInteresMensual, Estado)
VALUES 
-- PEGA AQUÍ TUS FILAS REEMPLAZANDO LAS TUBERÍAS '|' POR COMAS Y COMILLAS EN EL ESTADO
-- Ejemplo:
(1, 1, 15000.00, 2.50, 'Activo'),
(2, 2, 25000.00, 3.00, 'Activo'),
(3, 3, 80000.00, 1.80, 'Finalizado');

--------------------------------------

SELECT 
    Estado,
    SUM(MontoCapital) AS TotalCapitalPrestado,
    AVG(TasaInteresMensual) AS TasaInteresPromedio
FROM Operaciones.Creditos
GROUP BY Estado;

-----------------------------------------
SELECT 
    v.Marca,
    COUNT(c.IdCredito) AS TotalPrestamos
FROM Operaciones.Creditos c
INNER JOIN Garantias.Vehiculos v ON c.IdVehiculo = v.IdVehiculo
GROUP BY v.Marca
HAVING COUNT(c.IdCredito) > 50;
--------------------------------------------
SELECT 
    MAX(MontoCapital) AS PrestamoMaximo,
    MIN(MontoCapital) AS PrestamoMinimo
FROM Operaciones.Creditos;
