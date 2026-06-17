h5path=commandArgs(TRUE)

outfile=h5path[length(h5path)]

if(file.exists(outfile)){
  if(length(grep("/",outfile)))
    outfile=file.path(gsub("/[^/]*$","",outfile),"combined.hdf5")
  else
    outfile="combined.hdf5"
}else
  h5path=h5path[-length(h5path)]

require("hdf5r")
require("yaml")

datyaml=yaml.load_file(gsub("\\.hdf5",".yaml",h5path[1]))
yamlfile=gsub("\\.hdf5",".yaml",outfile)

file.remove(outfile,showWarnings=FALSE)
file.remove(yamlfile,showWarnings=FALSE)

  f=h5file(h5path[1],mode='r')
  d=f[["locs"]]$read()

if(colnames(d)[10]=="ellipticity"){
f$close()

outfile=h5file(outfile,mode = "w")

dat=data.frame(frame=-1,
               x=0,
               y=0,
               photons=0,
               sx=0,
               sy=0,
               bg=0,
               lpx=0,
               lpy=0,
               ellipticity=0,
               net_gradient=0
#               ,likelihood=0,
#               iterations=0
)

for(f in h5path){
  print(paste("Processing",f,"now."))
  f=h5file(f,mode='r')
  d=f[["locs"]]$read()
  d$frame=d$frame+max(dat$frame)+1
  dat=rbind(dat,d)
  f$close()
  print(paste(max(d$frame),"/",max(dat$frame)))
}

dat=dat[-1,]
dat$frame=as.integer(dat$frame)
# dat$iterations=as.integer(dat$iterations)

datyaml$Frames=as.integer(max(dat$frame)+1)
write_yaml(datyaml,yamlfile)

outfile[["locs"]]=dat
outfile$close()

}else{
f$close()

outfile=h5file(outfile,mode = "w")

dat=data.frame(frame=-1,
               x=0,
               y=0,
               photons=0,
               sx=0,
               sy=0,
               bg=0,
               lpx=0,
               lpy=0,
#              ellipticity=0,
               net_gradient=0
               ,likelihood=0,
               iterations=0
)

for(f in h5path){
  print(paste("Processing",f,"now."))
  f=h5file(f,mode='r')
  d=f[["locs"]]$read()
  d$frame=d$frame+max(dat$frame)+1
  dat=rbind(dat,d)
  f$close()
  print(paste(max(d$frame),"/",max(dat$frame)))
}

dat=dat[-1,]
dat$frame=as.integer(dat$frame)
dat$iterations=as.integer(dat$iterations)

datyaml$Frames=as.integer(max(dat$frame)+1)
write_yaml(datyaml,yamlfile)

outfile[["locs"]]=dat
outfile$close()
}
