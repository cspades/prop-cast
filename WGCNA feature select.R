
rm(list=ls())

library("WGCNA")
library(fuzzyforest)
mydata = read.csv("C:/Users/canth/Dropbox/UCLA/A2 Neural Networks/project/county macro data/county_macro_data_8.csv")
sample_data <- mydata[c(5:length(mydata))]

var_select = names(sample_data)
scaled.data <- scale(sample_data)

# check that we get mean of 0 and sd of 1
colMeans(scaled.data)  # faster version of apply(scaled.dat, 2, mean)
apply(scaled.data, 2, sd)
var_select = names(sample_data)
mydata[c(5:length(mydata))] <- scaled.data


     net = WGCNA::blockwiseModules(mydata[,5:length(mydata)] , power = 6,TOMType = "unsigned",
                                   minModuleSize = 1,
                                   reassignThreshold = 0,
                                   mergeCutHeight = 0.25,numericLabels = FALSE,
                                   pamRespectsDendro = FALSE,verbose = 0)

     var = c(var_select,"date")
     Formula = as.formula(paste("HPI_perc_chg~",paste(var,collapse = "+")))


     ff_fit = ff(Formula,data = mydata,module_membership=net$colors,
                 screen_params = screen_control(min_ntree = 500,keep_fraction = 0.06),
                 select_params = select_control(min_ntree = 500,number_selected = 20),
                 final_ntree = 1000, num_processors = 1)





     top_variables = ff_fit$feature_list[,1]
 selected_data =  cbind(mydata["date"], mydata["countynum"], mydata["HPI_perc_chg"], mydata[top_variables])

 name = paste("selected_data" ,".csv",sep="")
 write.csv(selected_data,file = name)

 ########################################
 # Graph
 ########################################

 # Choose a set of soft-thresholding powers
 powers = c(c(1:10), seq(from = 12, to=20, by=2))
 # Call the network topology analysis function
 sft = pickSoftThreshold(mydata[,5:length(mydata)], powerVector = powers, verbose = 5)
 # Plot the results:
 sizeGrWindow(9, 5)
 par(mfrow = c(1,2));
 cex1 = 0.9;
 # Scale-free topology fit index as a function of the soft-thresholding power
 plot(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
      xlab="Soft Threshold (power)",ylab="Scale Free Topology Model Fit,signed R^2",type="n",
      main = paste("Scale independence"));
 text(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
      labels=powers,cex=cex1,col="red");
 # this line corresponds to using an R^2 cut-off of h
 abline(h=0.90,col="red")
 # Mean connectivity as a function of the soft-thresholding power
 plot(sft$fitIndices[,1], sft$fitIndices[,5],
      xlab="Soft Threshold (power)",ylab="Mean Connectivity", type="n",
      main = paste("Mean connectivity"))
 text(sft$fitIndices[,1], sft$fitIndices[,5], labels=powers, cex=cex1,col="red")

 softPower = 6;
 adjacency = adjacency(mydata[,5:length(mydata)], power = softPower);
 # Turn adjacency into topological overlap
 TOM = TOMsimilarity(adjacency);
 dissTOM = 1-TOM

 # Call the hierarchical clustering function
 geneTree = hclust(as.dist(dissTOM), method = "average");
 # Plot the resulting clustering tree (dendrogram)
 sizeGrWindow(12,9)
 plot(geneTree, xlab="", sub="", main = "Gene clustering on TOM-based dissimilarity",
      labels = FALSE, hang = 0.04);
 # We like large modules, so we set the minimum module size relatively high:
 minModuleSize = 1;
 # Module identification using dynamic tree cut:
 dynamicMods = cutreeDynamic(dendro = geneTree, distM = dissTOM,
                             deepSplit = 2, pamRespectsDendro = FALSE,
                             minClusterSize = minModuleSize);
 table(dynamicMods)

 # Convert numeric lables into colors
 dynamicColors = labels2colors(dynamicMods)
 table(dynamicColors)
 # Plot the dendrogram and colors underneath
 sizeGrWindow(8,6)
 plotDendroAndColors(geneTree, dynamicColors, "Tree Cut",
                     dendroLabels = FALSE, hang = 0.03,
                     addGuide = TRUE, guideHang = 0.05,
                     main = "Dendrogram and module colors")
