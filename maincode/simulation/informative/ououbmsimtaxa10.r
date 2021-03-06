#setwd("/Users/TerryLai/Dropbox/TerryLai/simulation/ououbm/")
setwd("/Users/terrylai/Dropbox/TerryLai/simulation/ououbm/")
rm(list=ls())
#source("/Users/TerryLai/Dropbox/TerryLai/R_code/abc_V2/ououbmabc.r")
source("/Users/terrylai/Dropbox/TerryLai/R_code/abc_infor_prior/ououbmabc.r")
root<-0
#true params
true.alpha.y<-0.1
true.alpha.x<-0.15
true.theta.x<-0
true.sigma.sq.x<-1
true.tau<- 0.35

true.b0 <- 0
true.b1 <- 0.5
true.b2 <- 0.5

#hyper parameters
alpha.y.rate <- 1/0.15
alpha.x.rate <- 1/0.1
theta.x.mean <- 0
theta.x.sd  <- 1
sigma.sq.x.rate <-1
tau.rate <- 1/0.35
b0.min = -1
b0.max = 1
b1.min = 0
b1.max = 1
b2.min = 0
b2.max = 1

prior.model.params=c(alpha.y.rate, alpha.x.rate, theta.x.mean, theta.x.sd, sigma.sq.x.rate, tau.rate)
names(prior.model.params)<-c("alpha.y.rate", "alpha.x.rate", "theta.x.mean","theta.x.sd", "sigma.sq.x.rate", "tau.rate")
prior.reg.params=c(b0.min, b0.max, b1.min, b1.max, b2.min, b2.max)

numbsim<-1;lambda<-2.0;mu<-0.5;frac<-0.6;age<-2
taxa.size.array<-c(10)#,20,50,100)
sims<-50000
model.params.array<-array(0,c(5,sims))
rownames(model.params.array)<-c("alpha.y","alpha.x","theta.x","sigma.sq.x","tau")
reg.params.array<-array(0,c(3,sims))
row.names(reg.params.array)<-c("b0", "b1", "b2")
y.sum.stat.array<-array(0,c(2,sims))
rownames(y.sum.stat.array)<-c("y.mean","y.sd")
x1.sum.stat.array<-array(0,c(2,sims))
rownames(x1.sum.stat.array)<-c("x1.mean","x1.sd")
x2.sum.stat.array<-array(0,c(2,sims))
rownames(x2.sum.stat.array)<-c("x2.mean","x2.sd")


for(taxa.size.Index in 1:length(taxa.size.array)){
  n<-taxa.size.array[taxa.size.Index]
  print(paste("taxa",n,sep=""))
  sim.ououbm.trait<-array(0,c(n,3,sims))
  tree<-sim.bd.taxa.age(n=n,numbsim=1,lambda=lambda,mu=mu,frac=frac,age=age,mrca=TRUE)[[1]]
  tree<-reorder(tree,"postorder")
  # tree$edge
  # plot(tree)
  # nodelabels()
  # tiplabels()
  true.trait<-ououbmmodel(model.params=c(true.alpha.y, true.alpha.x, true.theta.x, true.sigma.sq.x, true.tau),reg.params=c(true.b0,true.b1,true.b2),root=root,tree=tree)
  assign(paste("true.trait.taxa",taxa.size.array[taxa.size.Index],sep=""),true.trait)
  
  y.raw.sum.stat<-sum.stat(trait=true.trait$y,tree=tree)
  x1.raw.sum.stat<-sum.stat(trait=true.trait$x1,tree=tree)
  x2.raw.sum.stat<-sum.stat(trait=true.trait$x2,tree=tree)
  raw.sum.stat <- cbind(t(y.raw.sum.stat),t(x1.raw.sum.stat),t(x2.raw.sum.stat))
  assign(paste("raw.sum.stat.taxa",taxa.size.array[taxa.size.Index],sep=""),raw.sum.stat)
  for(simIndex in 1:sims){
    if(simIndex %%1000==0){print(simIndex)}
    prior.params <- ououbmprior(prior.model.params=prior.model.params,prior.reg.params=prior.reg.params)
    model.params.array[,simIndex]<-prior.params$model.params#for record only
    reg.params.array[,simIndex]<-prior.params$reg.params#for record only
    sim.trait <-ououbmmodel(model.params=prior.params$model.params,reg.params=prior.params$reg.params,root=root,tree=tree)
    sim.ououbm.trait[,1,simIndex]<-sim.trait$y
    sim.ououbm.trait[,2,simIndex]<-sim.trait$x1
    sim.ououbm.trait[,3,simIndex]<-sim.trait$x2
    y.sum.stat.array[,simIndex]<- sum.stat(trait=sim.trait$y,tree=tree)
    x1.sum.stat.array[,simIndex]<- sum.stat(trait=sim.trait$x1,tree=tree)
    x2.sum.stat.array[,simIndex]<- sum.stat(trait=sim.trait$x2,tree=tree)
  }#end of loop
  
  ### Use abc package
  sim.sum.stat <- cbind(t(y.sum.stat.array),t(x1.sum.stat.array),t(x2.sum.stat.array))
  ououbm.par.sim <- cbind(t(model.params.array),t(reg.params.array))
  
  assign(paste("sim.ououbm.trait.taxa",taxa.size.array[taxa.size.Index],sep=""),sim.ououbm.trait)
  assign(paste("sim.sum.stat.taxa",taxa.size.array[taxa.size.Index],sep=""),sim.sum.stat)
  assign(paste("ououbm.par.sim.taxa",taxa.size.array[taxa.size.Index],sep=""),ououbm.par.sim)
  
  ### The rejection alogoritm
  assign(paste("rej.taxa",taxa.size.array[taxa.size.Index],sep=""),abc(target=c(y.raw.sum.stat,x1.raw.sum.stat,x2.raw.sum.stat), param=ououbm.par.sim, sumstat=sim.sum.stat, tol=0.05, method="rejection"))
  setwd("/Users/terrylai/Documents/simulate_data_0504/")
  save.image(paste("ououbmsimstaxa",taxa.size.array[taxa.size.Index], ".RData", sep=""))
}#end of taxasize

