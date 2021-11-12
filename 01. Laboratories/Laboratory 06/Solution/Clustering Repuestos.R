install.packages("DBI")
install.packages("odbc")
install.packages("factoextra")
install.packages("gridExtra")
install.packages("dplyr")

library(DBI)
library(odbc)
library(factoextra)
library(gridExtra)
library(dplyr)

#b. Cree una conexiÃ³n a SQL Server a la base de datos de RepuestosWeb y consuma la vista
con <- dbConnect(odbc(), Driver = "SQL Server", Server = "LAPTOP-MHM32UUF", Database = "RepuestosWeb")

cotizacionesRaw <- dbGetQuery(conn=con, "SELECT * FROM v_CategoriasCotizaciones")
cotizacionesRaw <- data.frame(TotalPorParte = cotizacionesRaw$TotalPorParte,
                              TotalPartesCotizadas = cotizacionesRaw$TotalPartesCotizadas,
                              PromedioPartesCotizadas = cotizacionesRaw$PromedioPartesCotizadas,
                              row.names = cotizacionesRaw$Nombre)

cotizaciones <- na.omit(cotizacionesRaw)
cotizaciones <- data.frame(scale(cotizacionesRaw))

#cotizacionesSinNombre = subset(cotizaciones, select=-c(Nombre))
#dibujamos la grafica de wss vs K para ver el K "optimo"
set.seed(123)
fviz_nbclust(cotizaciones, kmeans, method = "wss") +
  geom_vline(xintercept = 5, linetype = 2)

clusterk3 <- kmeans(cotizaciones, 3, nstart = 25) 
clusterk4 <- kmeans(cotizaciones, 4, nstart = 25)
clusterk5 <- kmeans(cotizaciones, 5, nstart = 25)
clusterk6 <- kmeans(cotizaciones, 6, nstart = 25)
print(clusterk3)
#visualizacion de asignacion a cluster
clusterk3$cluster
#Tamaño de cada cluster
clusterk3$size
#Centros de los 4 clusters
clusterk3$centers

graficaK3 <- fviz_cluster(clusterk3, geom = "point", data = cotizaciones) + ggtitle("k = 3")
graficaK4 <- fviz_cluster(clusterk4, geom = "point",  data = cotizaciones) + ggtitle("k = 4")
graficaK5 <- fviz_cluster(clusterk5, geom = "point",  data = cotizaciones) + ggtitle("k = 5")
graficaK6 <- fviz_cluster(clusterk6, geom = "point",  data = cotizaciones) + ggtitle("k = 6")

grid.arrange(graficaK3, graficaK4, graficaK5, graficaK6, nrow = 2)

tst<-merge(as.data.frame(clusterk5$cluster),cotizacionesRaw,by=0, all=TRUE)
names(tst)[2]<-"clustno"
tst<-subset(tst, select=-c(Row.names))
aggregate(tst,by=list(tst$clustno),FUN=mean)

graficaK5

#Un plot con el comportamiento de la minimización de distancias “tot.withinss” que muestre 
#cómo se comporta para diferentes números de clusters
x <- NULL
for ( i in 1:10 ){
  kc     <- kmeans( cotizaciones, i, nstart = 25 )
  x[ i ] <- kc$tot.withinss
}
plot( c( 1:10 ), x, type = "b" )


