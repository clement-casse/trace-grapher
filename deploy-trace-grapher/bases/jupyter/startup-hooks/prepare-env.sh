#! /bin/bash

set -eux;

# Install extensions
conda install --yes --quiet --prefix "${CONDA_DIR}" -c conda-forge \
    ipywidgets \
    jupyter_contrib_nbextensions \
    jupyter_nbextensions_configurator \
    qgrid \
;

conda install --yes --quiet --prefix "${CONDA_DIR}" -c damianavila82 \
    rise \
;

jupyter nbextension enable codefolding/edit;
jupyter nbextension enable init_cell/main;
jupyter nbextension enable splitcell/splitcell;
jupyter nbextension enable toc2/main;
jupyter nbextension enable varInspector/main;

jupyter-nbextension install rise --py --sys-prefix
jupyter-nbextension enable rise --py --sys-prefix

# Download, convert to Python3 then install libmetric
git clone https://github.com/cznewt/python-libmetric.git;
cd python-libmetric;
2to3 -w libmetric/*;
python setup.py install --user;
cd ..;
