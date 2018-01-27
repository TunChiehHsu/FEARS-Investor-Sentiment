
# Exploratory of time series clustering

# load package
library(readr)
library(TSclust)
library(dtwclust)
library(reshape2)
library(ggplot2)
library(dendextend)

df = read.csv('/Users/mueric35/Desktop/Sentiment-and-Marktet-Analysis/df_all.csv')
colnames(df)[0] = 'Date'
word_names = colnames(df)[-1]
 

df_list = list()
for( i in c(2:ncol(df))){
  df_list[[i-1]] = df[,i]
}
names(df_list) = word_names


pc = tsclust(df_list, type  = "partitional", k = 20L, 
        distance = "L2", centroid = "pam", 
        seed = 3247L, trace = TRUE,
        args = tsclust_args(dist = list(window.size = 20L)))

cluster_list = list()
for(i in c(1 : 20)){
  cluster_list[[i]] = c(0)
}
for(i in (1:length(pc@cluster))){
  cluster = pc@cluster[i]
  cluster_list[[cluster]] = c(word_names[i],cluster_list[[cluster]])
}
pc@cluster

# transform into matrix
df_mat = as.matrix(df[,-1])
df_mat = df_mat[1:100,1:100]
df_mat = ts(df_mat,frequency = 7)

# use pearson's correlation to evaluate similarity
dis_cor = diss((df_mat),METHOD = 'COR')

# hiearachical clustering for EDA
clu = hclust(dis_cor)
plt_c1 = clu %>% as.dendrogram
par(mar=c(3,3,3,10)) 

# plot the clusters 
k = 10
plt_c1 %>%
  color_branches(k=k) %>% 
  plot(., horiz = T)
plt_c1 %>% rect.dendrogram(k=k,horiz=TRUE)       
     
# Return Group of Cluster  
cutree(clu, k = 10)

# plot heatmap 
melted_cormat <- melt(as.matrix(dis_cor)
)

ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill = value^6)) + 
  geom_tile() + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + 
  scale_fill_gradient(high = "#132B43", low = "#56B1F7")


## Test another package: dcwclust
df_list = list()
for( i in c(2:ncol(df))){
  df_list[[i-1]] = df[,i]
}
names(df_list) = word_names


pc = tsclust(df_list, type  = "partitional", k = 20L, 
             distance = "L2", centroid = "pam", 
             seed = 3247L, trace = TRUE,
             args = tsclust_args(dist = list(window.size = 20L)))

cluster_list = list()
for(i in c(1 : 20)){
  cluster_list[[i]] = c(0)
}
for(i in (1:length(pc@cluster))){
  cluster = pc@cluster[i]
  cluster_list[[cluster]] = c(word_names[i],cluster_list[[cluster]])
}
pc@cluster



