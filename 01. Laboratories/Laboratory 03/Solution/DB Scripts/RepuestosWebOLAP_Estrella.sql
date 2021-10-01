USE master
GO

--Eliminar DB si ya existe y si @EliminarDB = 1
DECLARE @EliminarDB BIT = 1;
IF (((SELECT COUNT(1) FROM sys.databases WHERE name = 'RepuestosWebDWH_Estrella')>0) AND (@EliminarDB = 1))
BEGIN
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'RepuestosWebDWH_Estrella'

	USE [master];
	ALTER DATABASE [RepuestosWebDWH_Estrella] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
		
	DROP DATABASE [RepuestosWebDWH_Estrella]
	PRINT 'RepuestosWebDWH_Estrella ha sido eliminada'
END

CREATE DATABASE RepuestosWebDWH_Estrella
GO

USE RepuestosWebDWH_Estrella
GO

/*SP Para llenar data a la dimension Fecha*/
CREATE PROCEDURE USP_FillDimDate @CurrentDate DATE = '2015-01-01', 
                                 @EndDate     DATE = '2021-12-31'
AS
    BEGIN
        SET NOCOUNT ON;
        DELETE FROM Dimension.Fecha;

        WHILE @CurrentDate < @EndDate
            BEGIN
                INSERT INTO Dimension.Fecha
                ([DateKey], 
                 [Date], 
                 [Day], 
                 [DaySuffix], 
                 [Weekday], 
                 [WeekDayName], 
                 [WeekDayName_Short], 
                 [WeekDayName_FirstLetter], 
                 [DOWInMonth], 
                 [DayOfYear], 
                 [WeekOfMonth], 
                 [WeekOfYear], 
                 [Month], 
                 [MonthName], 
                 [MonthName_Short], 
                 [MonthName_FirstLetter], 
                 [Quarter], 
                 [QuarterName], 
                 [Year], 
                 [MMYYYY], 
                 [MonthYear], 
                 [IsWeekend]
                )
                       SELECT DateKey = YEAR(@CurrentDate) * 10000 + MONTH(@CurrentDate) * 100 + DAY(@CurrentDate), 
                              DATE = @CurrentDate, 
                              Day = DAY(@CurrentDate), 
                              [DaySuffix] = CASE
                                                WHEN DAY(@CurrentDate) = 1
                                                     OR DAY(@CurrentDate) = 21
                                                     OR DAY(@CurrentDate) = 31
                                                THEN 'st'
                                                WHEN DAY(@CurrentDate) = 2
                                                     OR DAY(@CurrentDate) = 22
                                                THEN 'nd'
                                                WHEN DAY(@CurrentDate) = 3
                                                     OR DAY(@CurrentDate) = 23
                                                THEN 'rd'
                                                ELSE 'th'
                                            END, 
                              WEEKDAY = DATEPART(dw, @CurrentDate), 
                              WeekDayName = DATENAME(dw, @CurrentDate), 
                              WeekDayName_Short = UPPER(LEFT(DATENAME(dw, @CurrentDate), 3)), 
                              WeekDayName_FirstLetter = LEFT(DATENAME(dw, @CurrentDate), 1), 
                              [DOWInMonth] = DAY(@CurrentDate), 
                              [DayOfYear] = DATENAME(dy, @CurrentDate), 
                              [WeekOfMonth] = DATEPART(WEEK, @CurrentDate) - DATEPART(WEEK, DATEADD(MM, DATEDIFF(MM, 0, @CurrentDate), 0)) + 1, 
                              [WeekOfYear] = DATEPART(wk, @CurrentDate), 
                              [Month] = MONTH(@CurrentDate), 
                              [MonthName] = DATENAME(mm, @CurrentDate), 
                              [MonthName_Short] = UPPER(LEFT(DATENAME(mm, @CurrentDate), 3)), 
                              [MonthName_FirstLetter] = LEFT(DATENAME(mm, @CurrentDate), 1), 
                              [Quarter] = DATEPART(q, @CurrentDate), 
                              [QuarterName] = CASE
                                                  WHEN DATENAME(qq, @CurrentDate) = 1
                                                  THEN 'First'
                                                  WHEN DATENAME(qq, @CurrentDate) = 2
                                                  THEN 'second'
                                                  WHEN DATENAME(qq, @CurrentDate) = 3
                                                  THEN 'third'
                                                  WHEN DATENAME(qq, @CurrentDate) = 4
                                                  THEN 'fourth'
                                              END, 
                              [Year] = YEAR(@CurrentDate), 
                              [MMYYYY] = RIGHT('0' + CAST(MONTH(@CurrentDate) AS VARCHAR(2)), 2) + CAST(YEAR(@CurrentDate) AS VARCHAR(4)), 
                              [MonthYear] = CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + UPPER(LEFT(DATENAME(mm, @CurrentDate), 3)), 
                              [IsWeekend] = CASE
                                                WHEN DATENAME(dw, @CurrentDate) = 'Sunday'
                                                     OR DATENAME(dw, @CurrentDate) = 'Saturday'
                                                THEN 1
                                                ELSE 0
                                            END     ;
                SET @CurrentDate = DATEADD(DD, 1, @CurrentDate);
            END;
    END;
	GO
/*DATA TYPES*/
--Enteros

	--Tipo para SK entero: Surrogate Key
	CREATE TYPE [UDT_SK] FROM INT
	GO

	--Tipo para PK entero
	CREATE TYPE [UDT_PK] FROM INT
	GO

--Cadenas

	--Tipo para cadenas largas
	CREATE TYPE [UDT_VarcharLargo] FROM VARCHAR(500)
	GO

	--Tipo para cadenas medianas
	CREATE TYPE [UDT_VarcharMediano] FROM VARCHAR(200)
	GO

	--Tipo para cadenas cortas
	CREATE TYPE [UDT_VarcharCorto] FROM VARCHAR(100)
	GO

	--Tipo para cadenas cortas
	CREATE TYPE [UDT_UnCaracter] FROM CHAR(1)
	GO

--Decimal

	--Tipo Decimal 12,2
	CREATE TYPE [UDT_Decimal12.2] FROM DECIMAL(12,2)
	GO

	--Tipo Decimal 2,2
	CREATE TYPE [UDT_Decimal2.2] FROM DECIMAL(2,2)
	GO

--Fechas
	CREATE TYPE [UDT_DateTime] FROM DATETIME
	GO

--Entero

	--Tipo para SK entero
	CREATE TYPE [UDT_INT] FROM INT
	GO

	/*ESQUEMAS*/
--Schemas para separar objetos
	CREATE SCHEMA Fact
	GO

	CREATE SCHEMA Dimension
	GO

	/*TABLAS DIMENSIONES*/
	CREATE TABLE Dimension.Fecha
	(
		DateKey INT PRIMARY KEY
	)
	GO

	CREATE TABLE Dimension.Geografia
	(
		SK_Geografia [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO

	CREATE TABLE Dimension.Clientes
	(
		SK_Clientes [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO

	CREATE TABLE Dimension.Partes
	(
		SK_Partes [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO

--Tablas Fact

	CREATE TABLE Fact.Orden
	(
		SK_Orden [UDT_SK] PRIMARY KEY IDENTITY,
		SK_Geografia [UDT_SK] REFERENCES Dimension.Geografia(SK_Geografia),
		SK_Clientes [UDT_SK] REFERENCES Dimension.Clientes(SK_Clientes),
		SK_Partes [UDT_SK] REFERENCES Dimension.Partes(SK_Partes),
		DateKey INT REFERENCES Dimension.Fecha(DateKey)
	)

--Modelado logico			

	--Fact
	ALTER TABLE Fact.Orden ADD ID_Ventas [UDT_PK]
	ALTER TABLE Fact.Orden ADD ID_Ciudad [UDT_PK]
	ALTER TABLE Fact.Orden ADD ID_Clientes [UDT_PK]
	ALTER TABLE Fact.Orden ADD ID_Partes [UDT_PK]
	ALTER TABLE Fact.Orden ADD TotalOrden [UDT_Decimal12.2]
	ALTER TABLE Fact.Orden ADD FechaOrden [UDT_DateTime]
	ALTER TABLE Fact.Orden ADD Nombre_Status_Orden [UDT_VarcharCorto]
	ALTER TABLE Fact.Orden ADD Cantidad [UDT_INT]
	ALTER TABLE Fact.Orden ADD Nombre_de_Descuento [UDT_VarcharMediano]
	ALTER TABLE Fact.Orden ADD Porcentaje_de_Descuento [UDT_Decimal2.2]

	--Dimension Fecha	
	ALTER TABLE Dimension.Fecha ADD [Date] DATE NOT NULL
    ALTER TABLE Dimension.Fecha ADD [Day] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DaySuffix] CHAR(2) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Weekday] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName] VARCHAR(10) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName_Short] CHAR(3) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName_FirstLetter] CHAR(1) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DOWInMonth] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DayOfYear] SMALLINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekOfMonth] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekOfYear] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Month] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName] VARCHAR(10) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName_Short] CHAR(3) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName_FirstLetter] CHAR(1) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Quarter] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [QuarterName] VARCHAR(6) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Year] INT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MMYYYY] CHAR(6) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthYear] CHAR(7) NOT NULL
    ALTER TABLE Dimension.Fecha ADD IsWeekend BIT NOT NULL
  
	--Dimension Geografia
	ALTER TABLE Dimension.Geografia ADD ID_Geografia [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD ID_Ciudad [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD ID_Region [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD ID_Pais [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD NombreCiudad [UDT_VarcharCorto]
	ALTER TABLE Dimension.Geografia ADD CodigoPostal [UDT_INT]
	ALTER TABLE Dimension.Geografia ADD NombreRegion [UDT_VarcharCorto]
	ALTER TABLE Dimension.Geografia ADD NombrePais [UDT_VarcharCorto]
	
	--Dimension Clientes
	ALTER TABLE Dimension.Clientes ADD ID_Cliente [UDT_PK]
	ALTER TABLE Dimension.Clientes ADD PrimerNombre [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD SegundoNombre [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD PrimerApellido [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD SegundoApellido [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD Genero [UDT_UnCaracter]
	ALTER TABLE Dimension.Clientes ADD CorreoElectronico [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD FechaNacimiento [UDT_DateTime]

	--Dimension Partes
	ALTER TABLE Dimension.Partes ADD ID_Partes [UDT_PK]
	ALTER TABLE Dimension.Partes ADD ID_Categoria [UDT_PK]
	ALTER TABLE Dimension.Partes ADD ID_Linea [UDT_PK]
	ALTER TABLE Dimension.Partes ADD NombrePartes [UDT_VarcharCorto]
	ALTER TABLE Dimension.Partes ADD DescripcionPartes [UDT_VarcharLargo]
	ALTER TABLE Dimension.Partes ADD PrecioPartes [UDT_Decimal12.2]
	ALTER TABLE Dimension.Partes ADD NombreCategoria [UDT_VarcharCorto]
	ALTER TABLE Dimension.Partes ADD DescripcionCategoria [UDT_VarcharLargo]
	ALTER TABLE Dimension.Partes ADD NombreLinea [UDT_VarcharCorto]
	ALTER TABLE Dimension.Partes ADD DescripcionLinea [UDT_VarcharLargo]
	

--Metadata

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Geografia provee una vista desnormalizada de las tablas origen Ciudad, Region y Pais, dejando todo en una unica dimensi�n para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Geografia';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Clientes provee una vista de la tabla origen Clientes en una sola dimesion para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Clientes';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Partes provee una vista desnormalizada de las tablas origen Partes, Categoria y Linea en una sola dimesion para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Partes';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension fecha es generada de forma automatica y no tiene datos origen, se puede regenerar enviando un rango de fechas al stored procedure USP_FillDimDate', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Fecha';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La abla de hecos es una union que viene de las tablas de Orden, Detalle_Orden, Descuento y StatusOrden', 
     @level0type = N'SCHEMA', 
     @level0name = N'Fact', 
     @level1type = N'TABLE', 
     @level1name = N'Orden';
	GO

--Indices Columnares
	CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCS-Precio] ON [Fact].[Orden]
	(
	   [TotalOrden]
	)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)
	GO

--Queries para llenar datos


	EXEC USP_FillDimDate 


--Dimensiones

	--Dimensión Geografia
	INSERT INTO Dimension.Geografia
	(ID_Ciudad, 
	 ID_Region,
	 ID_Pais,
	 NombreCiudad, 
	 CodigoPostal,
	 NombreRegion,
	 NombrePais
	)
	SELECT  C.ID_Ciudad, 
			R.ID_Region, 
			P.ID_Pais,
			C.Nombre, 
			C.CodigoPostal,
			R.Nombre,
			P.Nombre
	FROM RepuestosWeb.dbo.Pais P
		INNER JOIN RepuestosWeb.dbo.Region R ON(P.ID_Pais = R.ID_Pais)
		INNER JOIN RepuestosWeb.dbo.Ciudad C ON (C.ID_Region = R.ID_Region);
		
	--Dimensión Clientes
	INSERT INTO Dimension.Clientes
	(ID_Cliente, 
	 PrimerNombre,
	 SegundoNombre,
	 PrimerApellido,
	 SegundoApellido,
	 Genero,
	 CorreoElectronico,
	 FechaNacimiento
	)
	SELECT C.ID_Cliente, 
			C.PrimerNombre,
			C.SegundoNombre,
			C.PrimerApellido,
			C.SegundoApellido,
			C.Genero,
			C.Correo_Electronico,
			C.FechaNacimiento
	FROM RepuestosWeb.dbo.Clientes C


	--Dimensión Partes
	INSERT INTO Dimension.Partes
	(ID_Partes, 
	 ID_Categoria,
	 ID_Linea,
	 NombrePartes,
	 DescripcionPartes,
	 PrecioPartes,
	 NombreCategoria,
	 DescripcionCategoria,
	 NombreLinea,
	 DescripcionLinea
	)
	SELECT P.ID_Partes, 
			C.ID_Categoria,
			L.ID_Linea,
			P.Nombre,
			P.Descripcion,
			p.Precio,
			C.Nombre,
			C.Descripcion,
			L.Nombre,
			L.Descripcion
	FROM RepuestosWeb.dbo.Linea L
		INNER JOIN RepuestosWeb.dbo.Categoria C ON(C.ID_Linea = L.ID_Linea)
		INNER JOIN RepuestosWeb.dbo.Partes P ON (P.ID_Categoria = C.ID_Categoria)


	--Fact
	INSERT INTO [Fact].[Orden]
	(SK_Geografia, 
	 SK_Clientes,
	 SK_Partes,
	 DateKey,
	 ID_Ventas,
	 ID_Ciudad,
	 ID_Clientes,
	 ID_Partes,
	 TotalOrden,
	 FechaOrden,
	 Nombre_Status_Orden,
	 Cantidad,
	 Nombre_de_Descuento,
	 Porcentaje_de_Descuento
	)
	SELECT SK_Geografia, 
			SK_Clientes, 
			SK_Partes,
			F.DateKey, 
			O.ID_Orden,
			O.ID_Ciudad,
			O.ID_Cliente,
			DO.ID_Partes,
			O.Total_Orden,
			O.Fecha_Orden,
			S.NombreStatus,
			DO.Cantidad,
			D.NombreDescuento,
			D.PorcentajeDescuento
	FROM RepuestosWeb.dbo.Descuento D
		INNER JOIN RepuestosWeb.dbo.Detalle_orden DO ON(D.ID_Descuento = DO.ID_Descuento)
		INNER JOIN RepuestosWeb.dbo.Orden O ON(O.ID_Orden = DO.ID_Orden)
		INNER JOIN RepuestosWeb.dbo.StatusOrden S ON(S.ID_StatusOrden = O.ID_StatusOrden)
		INNER JOIN Dimension.Geografia C ON(C.ID_Ciudad = O.ID_Ciudad)
		INNER JOIN Dimension.Clientes CL ON(CL.ID_Cliente = O.ID_Cliente)
		INNER JOIN Dimension.Partes P ON(P.ID_Partes = DO.ID_Partes)
		LEFT JOIN Dimension.Fecha F ON(CAST( (CAST(YEAR(O.Fecha_Orden) AS VARCHAR(4)))+left('0'+CAST(MONTH(O.Fecha_Orden) AS VARCHAR(4)),2)+left('0'+(CAST(DAY(O.Fecha_Orden) AS VARCHAR(4))),2) AS INT)  = F.DateKey);

	
	--ver datos de la dimension Geografia
	SELECT * FROM Dimension.Geografia

	--ver datos de la dimension Clientes
	SELECT * FROM Dimension.Clientes

	--ver datos de la dimension Partes
	SELECT * FROM Dimension.Partes

	--ver datos de la dimension Fecha
	SELECT * FROM Dimension.Fecha

	--ver datos de la tabla de hechos Ventas Repuestos
	SELECT * FROM Fact.Orden

--------------------------------------------------------------------------------------------
------------------------------------Resultado Final-----------------------------------------
--------------------------------------------------------------------------------------------	

	SELECT *
	FROM	Fact.Orden AS O INNER JOIN
			Dimension.Partes AS C ON o.SK_Partes = C.SK_Partes INNER JOIN
			Dimension.Geografia AS CA ON O.SK_Geografia = CA.SK_Geografia INNER JOIN
			Dimension.Clientes AS DC ON O.SK_Clientes = DC.SK_Clientes INNER JOIN
			Dimension.Fecha AS F ON O.DateKey = F.DateKey