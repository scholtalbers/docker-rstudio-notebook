# GalaxyConnector #

## About ##

This package will allow you to interact with any Galaxy instance for which you 
have an API Key. You can retrieve and upload files from and to Galaxy and save 
and restore your R Session in a Galaxy history.

I've added the ability to get a collection from Galaxy.

## Install ##

To install, first download the GalaxyConnector .tar.gz release and install through `install.packages('GalaxyConnector_0.3.tar.gz',type='source',
repos=NULL)`.

You may need to install some missing dependencies manually.

## End user ##

First load the package: `library(GalaxyConnector)`

### Setup keys for all sessions ###

If you do not want to run gx_init each time you want to communicate with Galaxy,
you can set the variables in your ~/.Renviron file. 

e.g.

    GX_API_KEY=digitsAndCharacters    # Your Galaxy API Key
    GX_URL=http://usegalaxy.org       # The Galaxy instance url
    GX_HISTORY_ID=digitsAndCharacters # The Galaxy History ID

Can set the environment variables using R commands:

    Sys.setenv("GX_API_KEY" = 'your_Galaxy_API_key') # Your Galaxy API Key
    Sys.setenv("GX_GALAXY_URL" = 'the_galaxy_url')
    Sys.setenv("GX_HISTORY_ID" = 'your_history_id')

### Initialization ###

Use gx_init() to setup the **current session** only (see below for more information).

You can find the API key under user preference in the Galaxy instance.

Initialize the GalaxyConnector: `gx_init(API_KEY='your_Galaxy_API_Key', GALAXY_URL='usegalaxy.org', HISTORY_ID='your_history_id')`.

To initialize using environment variables: `gx_init(API_KEY=Sys.getenv("GX_API_KEY"), GALAXY_URL=Sys.getenv("GX_GALAXY_URL"), HISTORY_ID=Sys.getenv("GX_HISTORY_ID"))`

### Usage ###

You can now run `gx_list_histories()` to list all of your Galaxy
histories. Pick a history and set this as your current (default is latest)
history by running `gx_switch_history('HISTORY_ID')`.

With `gx_get(1)` you get the first dataset from your Galaxy history. On completion `gx_get(1)` shows you where it has been downloaded.

`gx_get()` also works with collections. It calls `gx_get_collection()`.

By running `gx_put(/tmp/some_file.txt)` you will upload a file into
the current Galaxy history.

`gx_list_history_datasets()` to get information on every dataset from the history.

Other functions you can discover from the man pages, all functions are prefixed
with `gx_`

## Admin ##

For now this package uses environment variables for the settings, so you can set
a default Galaxy instance, e.g. to your local instance. To set the defaults set
the same keys as above in e.g. the RStudio's configuration
`/etc/rstudio/rsession-profile`.

## Credits ##

Strongly based off the work of [scholtalbers](https://github.com/scholtalbers/r-galaxy-connector)

Who based their fork on the work by Eric Rasche and Bjoern Gruening - see the fork 
origin: https://github.com/erasche/docker-rstudio-notebook