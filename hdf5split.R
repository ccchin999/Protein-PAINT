args=commandArgs(TRUE)

infile=args[1]
splitframe=as.numeric(args[2])
outpath=gsub(".hdf5$",paste0("-split",splitframe),infile)

require("hdf5r")
require("yaml")

ind=h5file(infile,mode='r')
indat=ind[["locs"]]$read()
inyaml=yaml.load_file(gsub("\\.hdf5",".yaml",infile))
totalframe=as.numeric(inyaml$Frames)
if(totalframe>=splitframe){
  if(!dir.exists(outpath))
  dir.create(outpath)
  for(i in 1:(totalframe/splitframe)){
    dat=indat[(splitframe*(i-1))<=indat$frame & indat$frame<=(splitframe*i-1),]
    dat$frame=dat$frame-(splitframe*(i-1))
    outfile=file.path(outpath,paste0(gsub("\\.hdf5$","",gsub(".*/","",infile)),"_",(splitframe*(i-1)),"-",(splitframe*i-1),".hdf5"))
    yamlfile=gsub("\\.hdf5",".yaml",outfile)
    file.remove(outfile,showWarnings=FALSE)
    file.remove(yamlfile,showWarnings=FALSE)
    outfile=h5file(outfile,mode = "w")
    dat$frame=as.integer(dat$frame)
#    dat$iterations=as.integer(dat$iterations)
    outfile[["locs"]]=dat
    outfile$close()
    outyaml=inyaml
    outyaml$Frames=as.integer(splitframe)
    write_yaml(outyaml,yamlfile)
  }
  if((splitframe*i)<totalframe){
    dat=indat[indat$frame>=(splitframe*i),]
    dat$frame=dat$frame-(splitframe*i)
    outfile=file.path(outpath,paste0(gsub("\\.hdf5$","",gsub(".*/","",infile)),"_",(splitframe*i),"-",(totalframe-1),".hdf5"))
    yamlfile=gsub("\\.hdf5",".yaml",outfile)
    file.remove(outfile,showWarnings=FALSE)
    file.remove(yamlfile,showWarnings=FALSE)
    outfile=h5file(outfile,mode = "w")
    dat$frame=as.integer(dat$frame)
#    dat$iterations=as.integer(dat$iterations)
    outfile[["locs"]]=dat
    outfile$close()
    outyaml=inyaml
    outyaml$Frames=as.integer(totalframe-(splitframe*i))
    write_yaml(outyaml,yamlfile)
  }
}


ind$close()



