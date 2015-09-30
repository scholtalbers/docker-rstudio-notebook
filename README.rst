GalaxyConnector
---------------

About:
======

This package will allow you to interact with any Galaxy instance for which you 
have a API Key. You can retrieve and upload files from and to Galaxy and save 
and restore your R Session in a Galaxy history.
To install, first download the .tar.gz

End user:
=========

First load the package: :code:`library(GalaxyConnector)`

Then you configure the package by setting your Galaxy API Key and the Galaxy
Instance to work with.
You can find the API key under user preference in the Galaxy instance.

Run :code:`gx_init(your_Galaxy_API_Key,GALAXY_URL='usegalaxy.org')`. This will
set it up for the **current session** only (see below for more information).

You can now run :code:`gx_list_histories()` to list all of your Galaxy
histories. Pick a history and set this as your current (default is latest)
history by running :code:`gx_switch_history(HISTORY_ID)`.

With :code:`gx_get(1)` you get the first dataset from your Galaxy 
history and shows you where it has been put. 

By running :code:`gx_put(/tmp/some_file.txt)` you will upload a file back into
Galaxy.

Other functions you can discover from the man pages, all functions are prefixed
with `gx_`

Setup API Key for all sessions:
+++++++++++++++++++++++++++++++

If you do not want to run gx_init each time you want to communicate with Galaxy,
you can set the variables in your ~/.Renviron file. e.g.
::

  GX_API_KEY=D1g1tsAndcharact3rs    # Your Galaxy API Key
  GX_URL=http://usegalaxy.org       # The Galaxy instance url

Admin:
======

For now this package uses environment variables for the settings, so you can set
a default Galaxy instance, e.g. to your local instance. For this set the same
keys as above in for example RStudio's configuration
`/etc/rstudio/rsession-profile`.

Credits:
========

This is based on the work by Eric Rasche and Bjoern Gruening - see the fork 
origin: https://github.com/erasche/docker-rstudio-notebook