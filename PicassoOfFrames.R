args=commandArgs(TRUE)
hdf5pat=args[1]
tiffpat=args[2]
scale=args[3]
print("Please give hdf5_file_path, tiff_file_path and scale_number.")

if(!require("configr")){
  install.packages("configr")
  require("configr")
}
if(!require("hdf5r")){
  install.packages("hdf5r")
  require("hdf5r")
}
if(!require("EBImage")){
  if(!require("BiocManager")){
    install.packages("BiocManager")
      require("BiocManager")
  }
  BiocManager::install("EBImage")
  require("EBImage")
}

PicassoOfFrames=function(hdf5File,  # Input localization data file.
                         tiffFile=gsub(".hdf5$",".tif",hdf5File),  # Output TIFF file
                         yamlFile=gsub(".hdf5$",".yaml",hdf5File),  # Parameters describe DNA-PAINT raw images.
                         scale=16,  # The scale factor of the output image compared to the captured image.
                         gb=10*scale/128,  # Sigma of Gaussian blurring.
                         frames=configr::read.config(file = yamlFile)$Frames,  # Number of frames which is presented in output TIFF file.
                         startfs=0,  # Only data after start frame number is going to be presented in output TIFF file.
                         lowContrast=0,  # Use lowContrast if there is too much noise. The value must between 0 and 1.
                         highContrast=0){  # # Use highContrast if signals of certain part of image are too strong. The value must between 0 and 1.
  yaml=configr::read.config(file=yamlFile)
  w=yaml$Width*scale
  h=yaml$Height*scale
  hdf5=H5File$new(hdf5File,mode="r")
  hdf5$open("locs")->locs
  print(paste0("Precessing ",hdf5File," now."))
  locs=locs[startfs <= locs[]$frame & locs[]$frame < (startfs+frames)]
  locs=data.frame(f=locs$frame,x=locs$x,y=locs$y)
  hdf5$close()
  write.csv(locs,gsub(".hdf5$",".csv",hdf5File))
  locs$x=scale*locs$x
  locs$y=scale*locs$y
  locs=data.frame(f=locs$f[w>= locs$x & locs$x > 0 & h>= locs$y & locs$y > 0],x=locs$x[w>= locs$x & locs$x > 0 & h>= locs$y & locs$y > 0],y=locs$y[w>= locs$x & locs$x > 0 & h>= locs$y & locs$y > 0])
  print(paste0("Rendering ",tiffFile," now."))
  im=matrix(0,w,h)
  for(i in 1:length(locs$x)){
    im[ceiling(locs$x[i]),ceiling(locs$y[i])]=im[ceiling(locs$x[i]),ceiling(locs$y[i])]+1
  }
  if((lowContrast>0 & lowContrast<1) | (highContrast>0 & highContrast<1)){
    ord=order(im)
    zero=length(im[im==0])
    if(lowContrast>0 & lowContrast<1)
      im[ord[(zero+1):(zero+lowContrast*(length(im)-zero))]]=0
    if(highContrast>0 & highContrast<1)
       im[ord[ceiling(zero+(1-highContrast)*(length(im)-zero)):length(im)]]=im[ord[floor(zero+(1-highContrast)*(length(im)-zero))]]
  }
  bl=max(im)
  print(paste0("Saving ",tiffFile," now."))
  dir.create(gsub(paste0(tail(strsplit(tiffFile,.Platform$file.sep)[[1]],1),'$'),'',tiffFile),showWarnings = FALSE, recursive = TRUE)
  EBImage::writeImage(EBImage::gblur(im,gb)/bl,tiffFile)
}

if(length(na.omit(scale))){
  s=as.numeric(scale)
}else{
  s=16
}

if(length(na.omit(tiffpat))){
  PicassoOfFrames(hdf5File=hdf5pat,tiffFile=tiffpat,scale=s)
}else{
  PicassoOfFrames(hdf5File=hdf5pat,scale=s)
}

