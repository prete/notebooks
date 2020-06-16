# Distributed under the terms of the Modified BSD License.
FROM jupyter/base-notebook

USER root

# GENERAL PACKAGES
RUN apt-get update && apt-get install -yq --no-install-recommends \
    python3-software-properties \
    software-properties-common \
    apt-utils \
    gnupg2 \
    fonts-dejavu \
    tzdata \
    gfortran \
    curl \
    less \
    gcc \
    g++ \
    clang-6.0 \
    openssh-client \
    openssh-server \
    cmake \
    python-dev \
    libgsl-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2 \
    libxml2-dev \
    libapparmor1 \
    libedit2 \
    libhdf5-dev \
    libclang-dev \
    lsb-release \
    psmisc \
    rsync \
    vim \
    default-jdk \
    libbz2-dev \
    libpcre3-dev \
    liblzma-dev \
    zlib1g-dev \
    xz-utils \
    liblapack-dev \
    libopenblas-dev \
    libigraph0-dev \
    libreadline-dev \
    libblas-dev \
    libtiff5-dev \
    fftw3-dev \
    git \
    texlive-xetex \
    hdf5-tools \
    libffi-dev \
    gettext \
    libpng-dev \
    libpixman-1-0 \ 
    fuse libfuse2 sshfs \
    libxkbcommon-x11-0 \
    htop \
    tmux \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Select the right versio of libblas to be used
# there was a problem running R in python and vice versa
RUN pip install --no-cache-dir simplegeneric &&\
    update-alternatives --install /etc/alternatives/libblas.so.3-x86_64-linux-gnu libblas /usr/lib/x86_64-linux-gnu/blas/libblas.so.3 5

# RStudio
ENV RSTUDIO_PKG=rstudio-server-1.2.5019-amd64.deb
RUN wget -q https://download2.rstudio.org/server/bionic/amd64/${RSTUDIO_PKG} && \
    dpkg -i ${RSTUDIO_PKG} && \
    rm ${RSTUDIO_PKG}
# add RStudio to PATH
ENV PATH="${PATH}:/usr/lib/rstudio-server/bin"
ENV LD_LIBRARY_PATH="/usr/lib/R/lib:/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server:/opt/conda/lib/R/lib"

# Shiny Server
RUN SHINY_SERVER_VERSION=1.5.9.923 && \
    wget -q "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-${SHINY_SERVER_VERSION}-amd64.deb" -O shiny-server-latest.deb && \
    dpkg -i shiny-server-latest.deb && \
    rm -f shiny-server-latest.deb

# jupyter-server-proxy extension and jupyter-rsession-procy (nbrsessionproxy)
RUN pip install --no-cache-dir \
        jupyter-server-proxy \
        https://github.com/yuvipanda/nbrsessionproxy/archive/rserver-again.zip && \
    jupyter serverextension enable --sys-prefix jupyter_server_proxy

# R
# https://cran.r-project.org/bin/linux/ubuntu/README.html
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/" | sudo tee -a /etc/apt/sources.list && \
    add-apt-repository ppa:marutter/c2d4u && \
    apt-get update && apt-get install -yq --no-install-recommends \
        r-base \
        r-base-dev \
    && apt-get clean \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    rm -rf /var/lib/apt/lists/*
# Install hdf5r for Seurat and IRkernel to run R code in jupyetr lab
RUN Rscript -e "install.packages('hdf5r',configure.args='--with-hdf5=/usr/bin/h5cc')" && \
    Rscript -e "install.packages('IRkernel')" && \
    Rscript -e "IRkernel::installspec()"

# PYTHON
# install mostly used packages
RUN pip --no-cache-dir install --upgrade \
        scanpy \
        python-igraph \
        louvain \
        bbknn \
        rpy2 \
        tzlocal \
        scvelo \
        leidenalg \
        ipykernel
# install scanorama
RUN git clone https://github.com/brianhie/scanorama.git && \
    cd scanorama/ && \
    python setup.py install

# JULIA
ENV JULIA_VERSION=1.4.2
ENV JULIA_PKGDIR=/opt/julia
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_DEPOT_PATH=/opt/julia
RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    wget -q https://julialang-s3.julialang.org/bin/checksums/julia-${JULIA_VERSION}.sha256 && \
    echo "$(cat julia-${JULIA_VERSION}.sha256 | grep linux-x86_64 | awk '{print $1}') *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum --check --status && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}.sha256 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia && \
    # show Julia where conda libraries are \
    mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

# fix permissions
RUN conda clean -tipsy && \
    conda build purge && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER 

USER $NB_UID

RUN julia -e 'import Pkg; Pkg.update()' && \
    julia -e 'import Pkg; Pkg.add("IJulia")' && \
    julia -e 'using IJulia'

USER root

# MOVE JULIA KERNELSPEC OUT OF HOME
RUN mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter

# MAKE DEFAULT USER SUDO
RUN sed -i -e "s/Defaults    requiretty.*/ #Defaults    requiretty/g" /etc/sudoers && \
    echo "jovyan ALL= (ALL) NOPASSWD: ALL" >> /etc/sudoers.d/jovyan

# MOUNT FARM SCRIPT
COPY mount-farm /usr/local/bin/mount-farm
RUN chmod +x /usr/local/bin/mount-farm

# POSTSTART SCRIPT
COPY poststart.sh /
