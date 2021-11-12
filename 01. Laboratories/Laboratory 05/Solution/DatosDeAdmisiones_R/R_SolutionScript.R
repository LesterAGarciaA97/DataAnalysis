# Demo R
# Comandos para instalar paquetes y utilizar librerías
install.packages("ggplot2")
install.packages("dplyr")
library(ggplot2)
library(dplyr)
library(DBI)

# Creación de diferentes objetos con notación =
ObjetoCadena = "Esta es una cadena"
ObjetoEntero = 2
ObjetoVector = c(1:5) # Rango de números continuos

# Creación de diferentes objetos con notación de R <-
ObjetoCadena <- "Esta es una cadena"
ObjetoEntero <- 2
ObjetoVector <- c(1:5)

#Funciones para explorar objetos
str(ObjetoCadena)
str(ObjetoEntero)
str(ObjetoVector)
typeof(ObjetoVector) # Información del tipo de clase
typeof(ObjetoEntero)
typeof(ObjetoCadena)
class(ObjetoVector) # Información del tipo de objeto de la cual se instanció
class(ObjetoEntero)
class(ObjetoCadena)

#Data frames
Temperaturas <- data.frame(Anios=c(2015,2016,2017,2018),
                           Invierno=c(5,8,7,10),
                           Primavera=c(10,12,15,13),
                           Verano=c(25,26,29,32),
                           Otonio=c(13,14,12,10)
                           )

Temperaturas$Verano
head(Temperaturas,2) # Muestra los 2 registros de arriba
tail(Temperaturas,1) # Muestra el registro de abajo

# dplyr
# Filtrar informción
Temperaturas %>% filter(Anios==2018)
Temperaturas %>% slice(1:2)

# Ordenar
Temperaturas %>% arrange(desc(Invierno))

# GroupBy's
TemperaturasRandom <- data.frame(Anios=(sample(c(2015:2018),20,replace = TRUE)),
                                 Invierno=rnorm(20, mean=2, sd=1),
                                 Primavera=rnorm(20, mean=15, sd=3),
                                 Verano=rnorm(20, mean=2, sd=4),
                                 Otonio=rnorm(20, mean=10, sd=2)
                                 )

TemperaturasRandom  %>% summarise(TemperaturaPromedio = mean(Invierno))
TemperaturasRandom  %>% group_by(Anios)  %>% summarise(TemperaturaPromedio = mean(Invierno))
TemperaturasRandom  %>% slice(1:5) %>% group_by(Anios)  %>% summarise(TemperaturaPromedio = mean(Invierno))

# ggplot2
TemperaturasRandomPromedio <- TemperaturasRandom %>% group_by(Anios)  %>% summarise(TemperaturaPromedio = mean(Invierno))
ggplot(data=TemperaturasRandomPromedio, aes(x=Anios,y=TemperaturaPromedio))+
  geom_line()+
  geom_text(
    label=TemperaturasRandomPromedio$TemperaturaPromedio,
    nudge_x = 0.25, nudge_y = 0.25,
    check_overlap = T
  )

# Conectar a DB
con <- dbConnect(odbc::odbc(), Driver = "SQL Server", Server = "ACER-PREDATOR-H", 
                 Database = "Admisiones_DWH", User = "leste", Password = "holacomoestas*", 
                 timeout = 10)

dfsql <- dbGetQuery(conn=con,"SELECT e.*,c.NombreFacultad
                              FROM Fact.Examen E INNER JOIN
                                   Dimension.Carrera c on (e.sk_carrera = c.sk_carrera)")

DF_ConteoPorFacultad <- dfsql %>% count(NombreFacultad)

ggplot(DF_ConteoPorFacultad, aes(x="", y=n, fill=NombreFacultad))+
  geom_bar(stat = "identity", width = 1)+
  coord_polar("y", start = 0)
# ------------------------------------------------------------------------------------------------------------------

# Laboratorio 04 - Introducción a leguajes estadísticos - Solución

# Conectar a DB
con <- dbConnect(odbc::odbc(), Driver = "SQL Server", Server = "ACER-PREDATOR-H", 
                 Database = "Admisiones_DWH", User = "leste", Password = "holacomoestas*", 
                 timeout = 10)

# Inciso B - i
dfsql <- dbGetQuery(conn=con,"SELECT e.*,c.NombreFacultad
                              FROM Fact.Examen E INNER JOIN
                              Dimension.Carrera c on (e.sk_carrera = c.sk_carrera)")

DF_ConteoPorFacultad <- dfsql %>% count(NombreFacultad)


# Inciso B - ii
dfsql2 <- dbGetQuery(conn=con,"SELECT e.*,c.Genero
                               FROM Dimension.Candidato C")

DF_ConteoPorGeneroCandidato <- dfsql2 %>% count(Genero)


# Inciso B - iii
dfsql3 <- dbGetQuery(conn=con,"SELECT e.NotalTotal, c.NombreFacultad
                               FROM Fact.Examen E INNER JOIN
                               Dimension.Carrera c on (e.sk_carrera = c.sk_carrera)")
                              

DF_TotalIngresos <- dfsql3 %>% group_by(NombreCarrera) %>% summarise(TotalIngresos = sum(Precio))

# Inciso B - iv
dfsql4 <- dbGetQuery(conn=con,"SELECT e.*,c.NombreFacultad
                               FROM Fact.Examen E INNER JOIN
                               Dimension.Carrera c on (e.sk_carrera = c.sk_carrera)")

DF_PromediosAltos <- dfsql4 %>% slice(1:3) %>% group_by(NombreFacultad) %>% summarise(PromediosAltos = max(NotaTotal))

# Inciso C - i
dfsql <- dbGetQuery(conn=con,"SELECT e.*,c.NombreFacultad
                              FROM Fact.Examen E INNER JOIN
                              Dimension.Carrera c on (e.sk_carrera = c.sk_carrera)")

DF_ConteoPorFacultad <- dfsql %>% count(NombreFacultad)

ggplot(DF_ConteoPorFacultad, aes(x="", y=n, fill=NombreFacultad))+
  geom_bar(stat = "identity", width = 1)+
  coord_polar("y", start = 0)

# Inciso C - ii
dfsql5 <- dbGetQuery(conn=con,"SELECT e.*,c.NombreCarrera
                               FROM Fact.Examen E INNER JOIN
                               Dimension.Carrera c on (e.sk_carrera = c.sk_carrera)")

DF_PromediosCarreras <- dfsql5 %>% group_by(NombreCarrera) %>% summarise(PromediosCarreras = mean(NotaTotal))

ggplot(DF_PromediosCarreras, aes(x=NombreCarrera, y=PromediosCarreras, fill=NombreCarrera))+
  geom_bar(stat = "identity", width = 0.5)+
  theme_dark()

# Inciso C - iii
dfsql6 <- dbGetQuery(conn=con,"SELECT e.*, f.Year
                               FROM Fact.Examen E INNER JOIN
                               Dimension.Fecha F ON (e.DateKey = f.DateKey)")

DF_CantidadExamenesAnuales <- dfsql6 %>% group_by(Year) %>% count(Year)

ggplot(DF_CantidadExamenesAnuales, aes(x=Year, y=n, group=1))+
  geom_line()+
  geom_point()