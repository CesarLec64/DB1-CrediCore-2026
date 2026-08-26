-- ====================================================================
-- PROYECTO CREDICORE - FASE 1: CIMIENTOS DE TITANIO (DDL Y DOMINIOS)
-- Autor: César Anibal Lec Morales
-- Curso: Bases de Datos I
-- carne: 2290-24-8741
-- Descripción: Creación de esquemas lógicos, definición de tablas y 
--              restricciones de dominio inquebrantables.
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. CREACIÓN DE ESQUEMAS DE SEGURIDAD
-- Separación lógica entre la administración operacional de créditos
-- y el control de activos constituidos como garantías vehiculares.
-- --------------------------------------------------------------------

CREATE SCHEMA Operaciones;
CREATE SCHEMA Garantias;

-- --------------------------------------------------------------------
-- 2. TABLA: Operaciones.Clientes
-- Registro de información personal de clientes solicitantes de crédito.
-- --------------------------------------------------------------------

CREATE TABLE Operaciones.Clientes (
    IdCliente INT IDENTITY(1,1) NOT NULL,
    Nombres VARCHAR(60) NOT NULL,
    Apellidos VARCHAR(60) NOT NULL,
    DPI VARCHAR(13) NOT NULL,
    Telefono VARCHAR(15) NULL,
    Correo VARCHAR(100) NULL,
    
    -- Llave Primaria Autoincremental
    CONSTRAINT PK_Clientes PRIMARY KEY (IdCliente),
    
    -- Restricción Inquebrantable: DPI único por cliente para evitar duplicidad
    CONSTRAINT UQ_Clientes_DPI UNIQUE (DPI)
);

-- --------------------------------------------------------------------
-- 3. TABLA: Garantias.Vehiculos
-- Registro de los automóviles entregados como respaldo del préstamo.
-- --------------------------------------------------------------------

CREATE TABLE Garantias.Vehiculos (
    IdVehiculo INT IDENTITY(1,1) NOT NULL,
    Marca VARCHAR(30) NOT NULL,
    Modelo VARCHAR(30) NOT NULL,
    Anio INT NOT NULL,
    Color VARCHAR(20) NOT NULL,
    NumeroTituloPropiedad VARCHAR(50) NOT NULL,
    NumeroPlaca VARCHAR(15) NOT NULL,
    NumeroChasis VARCHAR(30) NOT NULL,
    
    -- Llave Primaria Autoincremental
    CONSTRAINT PK_Vehiculos PRIMARY KEY (IdVehiculo),
    
    -- Restricción Inquebrantable: Prohibidos vehículos con más de 15 años (Año >= 2011)
    CONSTRAINT CK_Vehiculos_Anio CHECK (Anio >= 2011),
    
    -- Restricción Inquebrantable: La combinación de Placa y Chasis debe ser única
    CONSTRAINT UQ_Vehiculos_Placa_Chasis UNIQUE (NumeroPlaca, NumeroChasis)
);

-- --------------------------------------------------------------------
-- 4. TABLA: Operaciones.Creditos
-- Registro de los contratos financieros de desembolso de capital.
-- --------------------------------------------------------------------

CREATE TABLE Operaciones.Creditos (
    IdCredito INT IDENTITY(1,1) NOT NULL,
    IdCliente INT NOT NULL,
    IdVehiculo INT NOT NULL,
    MontoCapital DECIMAL(18,2) NOT NULL,
    TasaInteresMensual DECIMAL(5,2) NOT NULL,
    
    -- Restricción DEFAULT: Estado inicial 'Activo' por defecto
    Estado VARCHAR(15) NOT NULL CONSTRAINT DF_Creditos_Estado DEFAULT 'Activo',
    
    -- Restricción DEFAULT: Captura automática de fecha y hora exacta del servidor
    FechaDesembolso DATETIME NOT NULL CONSTRAINT DF_Creditos_FechaDesembolso DEFAULT GETDATE(),
    
    -- Llave Primaria Autoincremental
    CONSTRAINT PK_Creditos PRIMARY KEY (IdCredito),
    
    -- Restricción Inquebrantable: El monto otorgado debe ser estrictamente mayor a Q1,000.00
    CONSTRAINT CK_Creditos_MontoCapital CHECK (MontoCapital > 1000.00),
    
    -- Restricción Inquebrantable: La tasa de interés jamás puede ser negativa
    CONSTRAINT CK_Creditos_TasaInteres CHECK (TasaInteresMensual >= 0.00)
);

-- ====================================================================
-- SECCIÓN DE PRUEBAS DE DESTRUCCIÓN (INTENTOS MALICIOSOS)
-- Para probar estas validaciones en vivo durante la grabación del video,
-- desmarca los guiones dobles (--) y ejecuta cada instrucción individualmente.
-- ====================================================================

-- Prueba 1: Intento de registro de vehículo año 2005 (Debe fallar por CK_Vehiculos_Anio)
-- INSERT INTO Garantias.Vehiculos (Marca, Modelo, Anio, Color, NumeroTituloPropiedad, NumeroPlaca, NumeroChasis)
-- VALUES ('Toyota', 'Yaris', 2005, 'Rojo', 'TIT-99999', 'P-123ABC', 'CHS-999999999');

-- Prueba 2: Intento de desembolso menor a Q1,000 (Debe fallar por CK_Creditos_MontoCapital)
-- INSERT INTO Operaciones.Creditos (IdCliente, IdVehiculo, MontoCapital, TasaInteresMensual)
-- VALUES (1, 1, 500.00, 3.50);

-- Prueba 3: Intento de asignación de tasa negativa (Debe fallar por CK_Creditos_TasaInteres)
-- INSERT INTO Operaciones.Creditos (IdCliente, IdVehiculo, MontoCapital, TasaInteresMensual)
-- VALUES (1, 1, 5000.00, -2.00);