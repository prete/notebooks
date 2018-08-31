# cellgeni-notebook
A Docker image for Cellgeni JupyterHub installation
Based on [docker-stacks](https://github.com/jupyter/docker-stacks) and used with [Zero to JupyterHub with Kubernetes](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

This Docker image is used as default for every user of Cellgeni JupyterHub installation. The installation contains R packages from [jupyter/r-notebook](https://github.com/jupyter/docker-stacks/blob/master/r-notebook/Dockerfile) and Python packages [jupyter/scipy-notebook](https://github.com/jupyter/docker-stacks/blob/master/scipy-notebook/Dockerfile).



### Creating your own conda environment

Default conda environments are not persistent across Jupyter sessions - you can install an additional package, but it will not be there next time you start Jupyter. To have a persistent conda environment, you can create one inside your home folder. 

1. Go to Jupyter terminal ("New" -> "Terminal")
2. Replace 'myenv' with your environment name
```bash
conda create --name myenv
source activate myenv
# IMPORTANT! it allows the environment to appear in kernels list
conda install nb_conda_kernels  
# conda install all-other-packages
```
3. Reload the main page. Now in the "New" menu you see your new environment in the list of kernels, and you can create a notebook with this kernel. Also you can switch to this kernel in your existing notebooks from the "Kernel" -> "Change kernel" menu.


Instead of creating a new environment, you can also clone an existing one via
```
conda create --clone old_name --name new_name
```
This will eliminate the need to install basic packages.