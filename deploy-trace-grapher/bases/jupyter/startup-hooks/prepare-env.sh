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

jupyter nbextension enable autoscroll/main;
jupyter nbextension enable code_prettify/code_prettify;
jupyter nbextension enable codefolding/main;
jupyter nbextension enable codefolding/edit;
jupyter nbextension enable collapsible_headings/main;
jupyter nbextension enable init_cell/main;
jupyter nbextension enable python-markdown/main;
jupyter nbextension enable splitcell/splitcell;
jupyter nbextension enable toc2/main;
jupyter nbextension enable varInspector/main;


jupyter-nbextension install rise --py --sys-prefix
jupyter-nbextension enable rise --py --sys-prefix
