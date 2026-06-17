# Protein-PAINT
Scripts and raw data of "Protein-PAINT in living cells using engineered reversible bilirubin-binding fluorescent protein"

## Install first

- R
- R packages:
  - EBImage
  - hdf5r
  - configr
  - yaml
  - data.table
  - RANN
  - igraph
  - clue
  - ggplot2
- Fiji
  - ImageJ plugin raw-yaml exporter (Download https://github.com/jungmannlab/imagej-raw-yaml-export/blob/master/jar/Raw_Yaml_Export.jar and put .jar file into `Fiji.app/plugins` directory)

## Work flow

- Preprocess Protein-PAINT raw images with [Fiji](https://fiji.sc/).  If necessary, export the data in RAW format using plugin [raw-yaml exporter](https://github.com/jungmannlab/imagej-raw-yaml-export/blob/master/jar/Raw_Yaml_Export.jar).
- Fit & localize Protein-PAINT raw data with [Picasso software](https://github.com/jungmannlab/picasso), save hdf5 files.
- Combine all hdf5 file of single field of view in temporal order using `hdf5combine.R`: `Rscript hdf5combine.R /path/to/hdf5/file/1 /path/to/hdf5/file/2 ... /path/to/combined/hdf5/file`.
- If necessary, conduct drift correction using Picasso Render.
- Split the combined hdf5 file to get a temporal sequence of super-resolution images using `hdf5split.R`: `Rscript hdf5split.R /path/to/combined/hdf5/file N`, where `N` is the raw data frame number corresponding to a single reconstructed image.
- Render 16-bit images in TIFF format using `PicassoOfFrames.R`: `Rscript PicassoOfFrames.R /path/to/hdf5/file /target/path/for/reconstructed/tiff/image Scale`, where `Scale` is the magnification factor of the final tiff image relative to the original data.
- Export localization details for microtubule growth rate and shrink rate calculation using `hdf52csv.R`: `Rscript hdf52cssv.R /path/to/hdf5/file`.
- Calculate microtubule growth rate and shrink rate using `growth_shrink_rate.R`: `Rscript hdf52cssv.R /path/to/csv/file`, The mean growth rate, median growth rate, mean shrink rate and median shrink rate will be printed to the console.
