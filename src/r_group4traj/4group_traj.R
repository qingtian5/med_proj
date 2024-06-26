
# GBTM AND K-MEANS ANALYSIS - RAW CODE

# Load functions

url = "https://raw.githubusercontent.com/bitowaqr/traj/master/Setup_n_functions.R"
source(url)

# set.seed(13)

# prepare data

# Data needs the following format:
# rows = cases
# columns = observations at time points
# no time variables needed

# Enter file path or select manually
setwd("C:/Users/Qingt/Desktop/一个文件夹/pxh工作/xd_med")
test.data = read.csv("data0408/data/wide_data_norm_id.csv")
# Otherwise select your own data:
# test.data = read.csv(file.choose())

# reducing the size of the demo data set
# test.data = test.data[1:100,] # looking at a subset 

# Missing values need to be coded as negative values for crimCV
test.data[is.na(test.data)] = -0.00001

# data frame to matrix
df = as.matrix(test.data[,-1])
rownames(df) = test.data$ID

# resulting data set
kable(head(df),format="markdown")

# GBTM CLUSTERING: crimCV

## set the grid of models to evaluate
# Set: 
n.cluster = c(1,2,3,4) # 1.which k's to evaluate, 
p.poly = c(1,2) # 2. which p's to evaluate, 
rcv = T # 3. do you want to run cross validation? T/F

## model evaluation

# Run all models
cv.eval.list = list()
index = 0
for(k in n.cluster)
{
  sub.index = 0
  index = index + 1
  cv.eval.list[[index]] = list()
  names(cv.eval.list)[k] = paste("Groups",k,sep="_")
  for(p in p.poly)
  {
    print(cat("\n Running models for", n.cluster[k], "Groups, and",p.poly[p],"polynomials..."))
    cat("\n running k=",k,"poly=",p," \n")
    sub.index = sub.index + 1
    temp = crimCV(df,
                  ng = k,
                  dpolyp = p,
                  rcv = rcv,     
                  model = "ZIP"
    )
    
    cv.eval.list[[index]][[sub.index]] = temp
    
    names(cv.eval.list[[index]])[sub.index] = paste("polynomial",p,sep="_")
  }
}

## retrireve model evaluation results  

# retrieve AIC, BIC and CV error for each of the models
points.for.AIC.plot = points.for.BIC.plot = points.for.cv.plot = data.frame(x=NA,value=NA,cluster=NA)
for(c in 1:length(cv.eval.list)){
  for(p in 1:length(cv.eval.list[[c]])){
    
    
    tryCatch({
      cv = ifelse(!is.null(cv.eval.list[[c]][[p]]$cv),cv.eval.list[[c]][[p]]$cv,NA)
      points.for.cv.plot = rbind(points.for.cv.plot,
                                 data.frame(x=p,value=cv ,cluster=c))
    }, error =function(e){})
    
    
    tryCatch({
      aic = ifelse(!is.null(cv.eval.list[[c]][[p]]$AIC),cv.eval.list[[c]][[p]]$AIC,NA)
      points.for.AIC.plot = rbind(points.for.AIC.plot,
                                  data.frame(x=p,value=aic,cluster=c))
    }, error =function(e){})
    
    tryCatch({
      bic = ifelse(!is.null(cv.eval.list[[c]][[p]]$BIC),cv.eval.list[[c]][[p]]$BIC,NA)
      points.for.BIC.plot = rbind(points.for.BIC.plot,
                                  data.frame(x=p,value=bic,cluster=c))
    }, error =function(e){})
    
  }}

points.for.AIC.plot = points.for.AIC.plot[-1,]  
points.for.BIC.plot = points.for.BIC.plot[-1,] 
points.for.cv.plot = points.for.cv.plot[-1,]

AIC.gbtm.plot = ggplot(points.for.AIC.plot) + 
  geom_line(aes(x=x,y=value,col=as.factor(cluster))) +
  #geom_point(aes(x=x,y=value,col=as.factor(cluster))) +
  geom_text(aes(x=x,y=value,col=as.factor(cluster),label=cluster),size=5) +
  xlab("Polynomial") +
  ylab("AIC")

BIC.gbtm.plot = ggplot(points.for.BIC.plot) + 
  geom_line(aes(x=x,y=value,col=as.factor(cluster))) +
  # geom_point(aes(x=x,y=value,col=as.factor(cluster))) +
  geom_text(aes(x=x,y=value,col=as.factor(cluster),label=cluster),size=5) +
  xlab("Polynomial") +
  ylab("BIC")

cv.error.gbtm.plot = ggplot(points.for.cv.plot) + 
  geom_line(aes(x=x,y=value,col=as.factor(cluster))) +
  geom_text(aes(x=x,y=value,col=as.factor(cluster),label=cluster),size=5) +
  #geom_point(aes(x=x,y=value,col=as.factor(cluster))) +
  xlab("Polynomial")  +
  ylab("LOOCV Absolute error") 

plot.legend = get_legend(AIC.gbtm.plot + theme(legend.position = "bottom"))

model.eval.plot = 
  plot_grid(
    plot_grid(cv.error.gbtm.plot + theme(legend.position = "none"),
              BIC.gbtm.plot + theme(legend.position = "none"),
              AIC.gbtm.plot + theme(legend.position = "none"),
              ncol=3),
    plot.legend,nrow = 2,rel_heights = c(10,1))

# plot model evaluation
model.eval.plot

## Set the parameters for your model of choice

# Select k and p 
k.set = 4
p.set = 1

# plot details
y.axis.label = "Temperature per time"
x.axis.label = "Time"
plot.title = "Temperature per time over the last 3 days"


## Retrive data from your model of choi


# select model
ind.k = which(grepl(k.set,names(cv.eval.list)))
ind.p = which(grepl(p.set,names(cv.eval.list[[ind.k]])))
# retrieve participants membership
gbtm.members = data.frame(ID =  rownames(df),
                          cluster = apply(summary(cv.eval.list[[ind.k]][[ind.p]]),
                                          1,
                                          function(x)which(x ==max(x))))

members.per.cluster = data.frame(table(gbtm.members$cluster))

## Plot estimated trajectories
write.csv(gbtm.members, "0420/id_class.csv", row.names = TRUE)


# estimated trajectories

modelled.list = plot(cv.eval.list[[ind.k]][[ind.p]],size=1,plot=F)
modelled.list$time = modelled.list$time 

# remove normalization (Important)
new_value = (modelled.list$value / 7.8) + 34.2
modelled.list$value = new_value - 1

model.plot.modelled = 
  ggplot(modelled.list) +
  geom_line(aes(x=time,y=value,col=cluster)) +
  scale_y_continuous(name=y.axis.label) +
  scale_x_continuous(name=x.axis.label) +
  ggtitle(plot.title) +
  scale_color_manual(lab=paste("Group ",members.per.cluster$Var1," (n=",members.per.cluster$Freq,")",sep=""),
                     values=c(2,3,4,5),
                     name="Estimated group trajectories") +
  theme_minimal()

model.plot.modelled

## Retrieve group function terms

# retrieve model function terms with intercept and * for p < .05
long.test.dat = melt(df)
names(long.test.dat)  = c("ID","time","value")
long.test.dat$time = as.numeric(gsub("t.","",long.test.dat$time))
long.test.dat = merge(long.test.dat,gbtm.members,"ID")
long.test.dat$cluster = as.factor(long.test.dat$cluster)


# remove normalization (Important)
new_value = (long.test.dat$value / 7.8) + 34.2
long.test.dat$value = new_value - 1


polynomial.model.results = summary(lm(value ~ -1+poly(time,p.set):cluster+cluster, long.test.dat))
model.spec = round(polynomial.model.results$coefficients[,1],2)
sig.model.specification = ifelse(polynomial.model.results$coefficients[,4]<0.05,"*"," ")
model.spec = paste(model.spec,sig.model.specification,sep="")
model.spec = formatC(model.spec)
model.spec = matrix(data=model.spec, ncol=p.set+1)

colnames(model.spec) = c("Intercept",paste("Polynomial",1:p.set))
rownames(model.spec) = c(paste("Group",1:k.set))

kable(model.spec,format="markdown")

## Plot average group trajectories

# Retrieve observed group trajectories
long.test.dat$value[long.test.dat$value<0] = NA
long.test.dat.means = aggregate(value ~ cluster + time, long.test.dat, function(x) mean( x , na.rm = T))


model.plot.from.data = ggplot(long.test.dat.means) +
  geom_line(aes(x=time,y=value,col=cluster)) +
  scale_y_continuous(name=y.axis.label) +
  scale_x_continuous(name=x.axis.label) +
  ggtitle(plot.title) +
  scale_color_manual(lab=paste("Group ",members.per.cluster$Var1," (n=",members.per.cluster$Freq,")",sep=""),
                     values=c(2,3,4,5),
                     name="Observed group trajectories") +
  theme_minimal()

model.plot.from.data 

## Setup for complex plot

# give names to clusters? 
cluster.names = paste(
  c("First cluster", 
    "Second",
    "Third",
    "Fourth"),
  " (n=",format(as.numeric(members.per.cluster$Freq),digits=1),")",sep="")


# set a y limits to have all sub plots on the same scale?
set.y.limit = c(34.5,42)


## Plot group and individual trajectories

# Group average overview and individual trajectories

pop.average.traj = aggregate(value ~time, long.test.dat, function(x) mean(x,na.rm=T))
model.plot.modelled.plus.pop.average = 
  ggplot() +
  geom_line(data=modelled.list,aes(x=time,y=value,col=cluster,linetype="Estimated")) +
  #geom_line(data=pop.average.traj,aes(x=time,y=value,col="Total",linetype="Average")) +  
  scale_y_continuous(name=y.axis.label) +
  scale_x_continuous(name=x.axis.label) +
  ggtitle("Temperature per time") +
  scale_color_manual(lab=c(paste("Group ",members.per.cluster$Var1," (n=",members.per.cluster$Freq,")",sep=""),
                           paste("Total", " (n=",sum(members.per.cluster$Freq),")",sep="")
                           ),
                     values=c(2:(k.set+1),1),
                     name="Estimated group trajectories") +
  #scale_linetype_manual(lab=c("Average","Estimated"),values = c(2,1), name="")+
  guides(color = guide_legend(order = 1),
         linetype = guide_legend(order=0)) +
  theme_minimal()


individual.plot.list = list()
times.ex = unique(long.test.dat$time)

for(i in 1:length(unique(long.test.dat$cluster))){
  individual.plot.list[[i]] = 
    ggplot() +
    theme_minimal() +
    geom_line(data=long.test.dat[long.test.dat$cluster==i,],
              aes(x=time,y=value,group=ID,linetype="Average"),col=i+1,alpha=0.3,size=0.4) +
    geom_line(data=long.test.dat.means[long.test.dat.means$cluster==i,],
              aes(x=time,y=value,linetype="Average"),col=i+1,size=1) +
    geom_line(data=modelled.list[modelled.list$cluster==i,],
              aes(x=time,y=value,col=cluster,linetype="Estimate"),col=i+1,size=1) +
    scale_linetype_manual(lab=c("Average","Estimated"),values = c(2,1), name="") +
    theme(legend.position = "none") +
    ylab("") +
    # ggtitle(plot.titles.for.mega[i]) +
    coord_cartesian(ylim=set.y.limit) 
}
# individual.plot.list[[length(individual.plot.list)+1]] = get.legend

gbtm.mega.plot = 
  plot_grid(model.plot.modelled.plus.pop.average+
              coord_cartesian(ylim=set.y.limit),
            plot_grid(plotlist=individual.plot.list,ncol=round(k.set/2,0)),ncol=1,rel_heights = c(2,3))

gbtm.mega.plot

# k-means clustering

## k-means of what?

?step1measures # info shows the 24 measurements on which k-means is performend

## Automated function for plotting results from `step1measures` --> `step2factors` --> `step3clusters`

# Takes a 'data frame' and creates traj cluster analysis with mean and individual plots
traj.k.mean = function( fill.data.matrix = test.data[,-1],
                        ID = test.data$ID ,
                        nclusters = NULL # set number of clusters, or NULL to let R decide
)
{
  times = dim(fill.data.matrix)[2]
  colnames(fill.data.matrix) = paste("x",1:dim(fill.data.matrix)[2],sep="")
  time.mat =  matrix(data=rep(1:dim(fill.data.matrix)[2],each=dim(fill.data.matrix)[1]),
                     nrow=dim(fill.data.matrix)[1],
                     ncol=dim(fill.data.matrix)[2])
  colnames(time.mat) = paste("t",1:dim(fill.data.matrix)[2],sep="")
  cluster.data = cbind(ID = ID, fill.data.matrix,time.mat)
  
  fill.data.matrix = cbind(ID,fill.data.matrix)
  time.mat = cbind(ID,time.mat)
  
  cat("\n Clustering needas at least 5 observation per case... Cases with fewer observations are being removed...! \n")
  s1 = step1measures(Data = fill.data.matrix, 
                     Time = time.mat,
                     ID = T )
  s2all = step2factors(s1)
  s3all = step3clusters(s2all, nclusters = nclusters)  # 5 clusters
  # clust.build.plot(s3all,y.max.lim =y.max.lim)
  k.membership.table = data.frame(table(s3all$clusters$cluster))
  k.membership = s3all$clusters
  k.k = unique(k.membership$cluster)
  
  
  cluster.plot.df = data.frame(cluster=NA,value=NA,time=NA)
  for(i in k.k){
    mean.per.cluster = colMeans(fill.data.matrix[fill.data.matrix$ID %in% k.membership$ID[k.membership$cluster==i],-1],na.rm=T)
    cluster.name = paste(i," (",length(fill.data.matrix[fill.data.matrix$ID %in% k.membership$ID[k.membership$cluster==i],1]),")",sep="")
    cluster.plot.df=rbind(cluster.plot.df,
                          data.frame(cluster=cluster.name,
                                     value=mean.per.cluster,
                                     time = 1:length(mean.per.cluster)))
  }
  cluster.plot.df = cluster.plot.df[-1,]
  cluster.plot.df$time = as.numeric(cluster.plot.df$time)
  n.per.cluster = as.numeric(table(cluster.plot.df$cluster))
  cluster.plot.df$cluster = as.factor(cluster.plot.df$cluster)
  
  mean.cluster.plot = 
    ggplot(cluster.plot.df) + 
    geom_line(aes(x=time,y=value,col=cluster)) +
    guides(color=guide_legend("Cluster (n)"))  # add guide properties by aesthetic
  
  # Individual plot
  indiv.data = merge(fill.data.matrix,k.membership,"ID")
  indiv.data = melt(indiv.data,id.vars=c("ID","cluster"))
  indiv.data$variable = as.character(indiv.data$variable)
  indiv.data$variable = gsub("x","",indiv.data$variable)
  indiv.data$variable = as.numeric(indiv.data$variable)
  indiv.data$cluster = as.factor(indiv.data$cluster)
  
  lev.clust = levels(indiv.data$cluster)
  n.clust = as.numeric(by(indiv.data$ID,indiv.data$cluster,function(x)length(unique(x))))
  names.clust = data.frame(cluster = lev.clust,n = paste(lev.clust," (",n.clust,")",sep=""))
  indiv.data = merge(indiv.data,names.clust,by="cluster")
  indiv.data$ID = as.factor(indiv.data$ID)
  
  individual.cluster.plot = 
    ggplot(indiv.data,aes(x=variable,y=value,col= cluster)) + 
    geom_line(aes(group=ID),alpha=0.3,size=0.6) +
    stat_summary(aes(group = cluster), fun.y = mean, geom = 'line', size=1, alpha=1) +
    guides(color=guide_legend("Cluster")) 
  
  
  cluster.analysis = list(
    s1 = s1,
    s2all = s2all,
    s3all = s3all,
    membership = k.membership,
    mean.cluster.plot=mean.cluster.plot,
    individual.cluster.plot = individual.cluster.plot)
  
  return(cluster.analysis)
}

## k-means cluster analysis

cluster.analysis.full = traj.k.mean( fill.data.matrix = test.data[,-1], ID = test.data$ID ,nclusters = NULL)

# results
cluster.analysis.full$s3
cluster.analysis.full$mean.cluster.plot
cluster.analysis.full$individual.cluster.plot

## k-means clusters within GBTM clusters

# k-means clusters within GBTM clusters
unique.GBTM.clusters = unique(long.test.dat$cluster)

clusters.within.clusters.plots = list()
set.y.limit = set.y.limit 

for(k in unique.GBTM.clusters){
  temp.pat = unique(long.test.dat$ID[long.test.dat$cluster==k])
  temp.fill.data = test.data[test.data$ID %in% temp.pat,-1]
  temp.k.means = traj.k.mean( fill.data.matrix = temp.fill.data, ID = temp.pat ,nclusters = NULL)
  clusters.within.clusters.plots[[k]] = temp.k.means$individual.cluster.plot + coord_cartesian(ylim=set.y.limit) 
}

## Overiew plot

plot_grid(plotlist = clusters.within.clusters.plots)


## References

citation("crimCV")
citation("traj")

## end


