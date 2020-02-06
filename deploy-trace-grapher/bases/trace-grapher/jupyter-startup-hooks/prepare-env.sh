#! /bin/bash

set -eux;

# Install extensions
conda install --yes --quiet --prefix "${CONDA_DIR}" -c conda-forge \
    jupyter_contrib_nbextensions \
    jupyter_nbextensions_configurator \
;

python3 -m pip -qq install \
    RISE \
;

jupyter nbextension enable codefolding/edit;
jupyter nbextension enable init_cell/main;
jupyter nbextension enable splitcell/splitcell;
jupyter nbextension enable toc2/main;
jupyter nbextension enable varInspector/main;

# Download, convert to Python3 then install libmetric
git clone https://github.com/cznewt/python-libmetric.git;
cd python-libmetric;
2to3 -w libmetric/*;
python setup.py install;
cd ..;
