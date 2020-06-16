#!/usr/bin/env bash


# create default environment
if [ ! -d my-conda-envs/myenv ]; then
    conda create --clone base --name myenv
    source activate myenv
    python -m ipykernel install --user --name=myenv
fi
if [ ! -d .bashrc ]; then
    echo "source activate myenv" > .bashrc
fi

Rscript -e 'dir.create(path = Sys.getenv("R_LIBS_USER"), showWarnings = FALSE, recursive = TRUE)'
Rscript -e '.libPaths( c( Sys.getenv("R_LIBS_USER"), .libPaths() ) )'
Rscript -e 'IRkernel::installspec()'

# create matching folders to mount the farm
sudo mkdir -p /nfs
sudo mkdir -p /lustre
sudo mkdir -p /warehouse

export USER=jovyan
