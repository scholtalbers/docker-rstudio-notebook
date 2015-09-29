GalaxyConnector
---------------

End user:
=========

To download and upload your datasets from and to Galaxy, you first need to
tell the package what your Galaxy API Key is and what instance you will work
with. You can find the API key under user preference in the
Galaxy instance.
For this run :code:`gx_set_env(API_KEY,GALAXY_URL='usegalaxy.org')`. This will
set it up for the **current session** only (see below for more information).

You can now run :code:`gx_list_histories()` to list all of your Galaxy
histories. Pick a history and set this as your current history by running
:code:`gx_switch_history(HISTORY_ID)`. Now you can run :code:`gx_get(1)` to
get the first dataset you have in this history. It will show you where the
file has been copied to, so you can run
:code:`gx_put(/tmp/<user>/<history_id>/1)` to copy it back into Galaxy.

Other functions you can discover from the man pages, all functions are
prefixed with `gx_`

Setup API Key for all sessions:
+++++++++++++++++++++++++++++++

If you do not want to run gx_set_env each time you want to communicate with
Galaxy, you can set the variables in your ~/.Renviron file. e.g.
::

  GX_API_KEY=D1g1tsAndcharact3rs    # Your Galaxy API Key
  GX_URL=http://usegalaxy.org       # The Galaxy instance url
  GX_HISTORY_ID=a93656117103148     # The initial/default Galaxy History
  # Other variables that the administrator generally sets
  # GX_PYTHON_FILE=/usr/local/bin/galaxy.py # Location of the python script
  # GX_PYTHON_BIN=python                    # Python binary with bioblend
                                            # installed

Admin:
======

You will need to put the galaxy.py somewhere accessible by all RStudio users.
Then in the RStudio configuration (`/etc/rstudio/rsession-profile`) set the
system environment variable :code:`GX_PYTHON_FILE` to this location e.g.
:code:`/usr/local/bin/galaxy.py`
In addition, you will need to ensure the python executable used, has the
package bioblend installed (:code:`pip install bioblend`). You then set the
:code:`GX_PYTHON_BIN` variable to that python version.
Since this package uses environment variables for the settings, you can
pre-set them for your users.
E.g. set GX_URL=https://test.galaxyproject.org/

Credits
=======
This is based on the work by Eric Rasche and Bjoern Gruening - see the fork origin: https://github.com/erasche/docker-rstudio-notebook