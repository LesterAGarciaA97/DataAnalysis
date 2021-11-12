
# Instalamos los paquetes
install.packages('arules')
install.packages("arulesViz")
library('arules')
#libreria para plotear arules
library("arulesViz")

#leemos el csv
txn <- read.transactions ("Compras.csv",rm.duplicates = FALSE,format="single",sep=",",cols=c(1,2))

txn@itemInfo
image(txn)

#definimos las reglas
sales_rules <- apriori(txn,parameter=list(sup=0.5,conf=0.9,target="rules"))
#vemos que reglas son validas
inspect(sales_rules)

#plot grafico
rules_high_lift <- head(sort(sales_rules, by="lift"), 3)

plot(rules_high_lift, engine = "plotly") #plot interactivo

plot(rules_high_lift, method = "graph", engine = "htmlwidget") #plot grafos

