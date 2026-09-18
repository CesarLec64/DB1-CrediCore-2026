USE CrediCore;
GO

-------------------------------------------------------------------------
-- PREPARACIÓN: Ajuste de columnas en Creditos y creación de Esquemas
-------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Auditoria')
    EXEC('CREATE SCHEMA Auditoria;');
GO

-- Aseguramos que la tabla Creditos tenga la columna SaldoActual
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Operaciones.Creditos') AND name = 'SaldoActual')
BEGIN
    ALTER TABLE Operaciones.Creditos ADD SaldoActual DECIMAL(12,2);
    EXEC('UPDATE Operaciones.Creditos SET SaldoActual = Monto;');
END;
GO

-- Tabla necesaria para registrar las transacciones de pago
IF OBJECT_ID('Operaciones.HistorialPagos', 'U') IS NULL
BEGIN
    CREATE TABLE Operaciones.HistorialPagos (
        IdPago INT IDENTITY(1,1) PRIMARY KEY,
        IdCredito INT NOT NULL FOREIGN KEY REFERENCES Operaciones.Creditos(IdCredito),
        MontoAbono DECIMAL(12,2) NOT NULL,
        FechaPago DATETIME DEFAULT GETDATE()
    );
END;
GO


-------------------------------------------------------------------------
-- PARTE A: Capa de Abstracción (Vista de Atención al Cliente)
-------------------------------------------------------------------------
CREATE OR ALTER VIEW Operaciones.vw_AtencionAlCliente AS
SELECT 
    cli.NombreCompleto AS NombreCliente,
    c.IdCredito AS NumeroCredito,
    v.Marca AS MarcaVehiculo,
    c.Estado AS EstadoCredito,
    c.SaldoActual
FROM Operaciones.Creditos c
INNER JOIN Operaciones.Clientes cli ON c.IdCliente = cli.IdCliente
INNER JOIN Garantias.Vehiculos v ON c.IdVehiculo = v.IdVehiculo;
GO


-------------------------------------------------------------------------
-- PARTE B: Lógica de Negocio Segura (Motor de Pagos - SP)
-------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Operaciones.SP_ProcesarPago
    @IdCredito INT,
    @MontoAbono DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @SaldoActual DECIMAL(12,2);
        
        -- Obtener saldo actual con bloqueo de fila
        SELECT @SaldoActual = SaldoActual 
        FROM Operaciones.Creditos WITH (UPDLOCK)
        WHERE IdCredito = @IdCredito;

        -- Validar si existe el credito
        IF @SaldoActual IS NULL
        BEGIN
            RAISERROR('El crédito especificado no existe.', 16, 1);
        END;

        -- Validar abono excesivo
        IF @MontoAbono > @SaldoActual
        BEGIN
            RAISERROR('El monto del abono excede el saldo actual del crédito.', 16, 1);
        END;

        -- 1. Registrar el pago
        INSERT INTO Operaciones.HistorialPagos (IdCredito, MontoAbono)
        VALUES (@IdCredito, @MontoAbono);

        -- 2. Descontar el saldo en la tabla principal
        UPDATE Operaciones.Creditos
        SET SaldoActual = SaldoActual - @MontoAbono
        WHERE IdCredito = @IdCredito;

        COMMIT TRANSACTION;
        PRINT 'Pago procesado exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMsg VARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO


-------------------------------------------------------------------------
-- PARTE C: Auditoría Activa (Bitácora y Trigger)
-------------------------------------------------------------------------
-- 1. Tabla de Bitácora
IF OBJECT_ID('Auditoria.Logs_Creditos', 'U') IS NULL
BEGIN
    CREATE TABLE Auditoria.Logs_Creditos (
        IdLog INT IDENTITY(1,1) PRIMARY KEY,
        Accion VARCHAR(100) NOT NULL,
        ValorAnterior VARCHAR(100),
        ValorNuevo VARCHAR(100),
        FechaHora DATETIME DEFAULT GETDATE()
    );
END;
GO

-- 2. Trigger para detectar cambios de saldo o montos
CREATE OR ALTER TRIGGER Operaciones.TR_Auditoria_Creditos
ON Operaciones.Creditos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Captura cambios directos en SaldoActual o Monto
    IF UPDATE(SaldoActual) OR UPDATE(Monto)
    BEGIN
        INSERT INTO Auditoria.Logs_Creditos (Accion, ValorAnterior, ValorNuevo, FechaHora)
        SELECT 
            'Modificación de Saldo/Monto en Crédito ID: ' + CAST(i.IdCredito AS VARCHAR),
            CAST(d.SaldoActual AS VARCHAR),
            CAST(i.SaldoActual AS VARCHAR),
            GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON i.IdCredito = d.IdCredito
        WHERE i.SaldoActual <> d.SaldoActual OR i.Monto <> d.Monto;
    END
END;
GO
-------------------------------------------------------------------------------------------

--Evidencia 1 'Vista'
SELECT TOP (10) * FROM Operaciones.vw_AtencionAlCliente;

-- 1. Evidencia 2: Procesar pago con exito (Resta 500 al saldo)
EXEC Operaciones.SP_ProcesarPago @IdCredito = 2004, @MontoAbono = 500.00;

-- 2. Evidencia 3: Procesar pago erroneo (Dispara el RAISERROR del TRY...CATCH)
EXEC Operaciones.SP_ProcesarPago @IdCredito = 2004, @MontoAbono = 999999.00;

-- 3. Evidencia 4: Update manual para probar el trigger de auditoria
UPDATE Operaciones.Creditos 
SET SaldoActual = 12349.00 
WHERE IdCredito = 2004;

-- 4. Consulta de la Bitácora (Muestra la captura del log generado)
SELECT * FROM Auditoria.Logs_Creditos;
-------------------------------------------------------------
--MUESTRA DE EJEMPLO SOBRE UN UPDATE

