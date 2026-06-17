args=commandArgs(TRUE)

infile=args[1]
outfile=gsub("\\.hdf5$",".csv",infile)

if(file.exists(outfile))
  file.remove(outfile)

require("hdf5r")

ind=h5file(infile,mode='r')
indat=ind[["locs"]]$read()
indat$frame=as.integer(indat$frame)
# indat$iterations=as.integer(indat$iterations)
write.csv(indat,outfile)

ind$close()



