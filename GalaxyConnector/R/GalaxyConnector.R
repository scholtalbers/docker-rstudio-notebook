#' pkg.env
#' private environment
pkg.env <- new.env()

pkg.env$GX_API_KEY <- Sys.getenv('GX_API_KEY', unset=NA)
pkg.env$GX_URL <- Sys.getenv('GX_URL', unset=NA)
pkg.env$GX_HISTORY_ID <- Sys.getenv('GX_HISTORY_ID', unset=NA)
pkg.env$GX_IMPORT_DIRECTORY <- Sys.getenv('GX_IMPORT_DIRECTORY', unset=NA)
pkg.env$GX_TMP_DIRECTORY <- Sys.getenv('GX_TMP_DIRECTORY', unset=NA)

# Check if curl dependency exists for jsonlite
if(!require(curl)){
	install.packages('curl')
  library(curl)
}

# If jsonlite isn't installed then let's install it!
if(!require(jsonlite)){
  install.packages('jsonlite')
  library(jsonlite)
}

#' gx_init
#'
#' Function that graps any environment/default settings to set for this session
#' to use.
#'
#' @param API_KEY, to access your Galaxy account
#' @param GALAXY_URL, the Galaxy instance to work with
#' @param HISTORY_ID, the Galaxy history id to work on
#' @param IMPORT_DIRECTORY, default '/tmp/<username>/galaxy_import'
#' @param TMP_DIRECTORY, default '/tmp/<username>/galaxy_import/tmp'
#'
#' @export

gx_init <- function(API_KEY=NULL, GALAXY_URL=NULL, HISTORY_ID=NULL,
                       IMPORT_DIRECTORY=NULL, TMP_DIRECTORY=NULL){
  if(!is.null(API_KEY)){
    pkg.env$GX_API_KEY <- API_KEY
  } else if (is.null(API_KEY) && is.na(pkg.env$GX_API_KEY)){
    stop("You have not set your API Key")
  }

  # Can the url checks be substituted for if(RCurl::url.exists(url))???
  if(!is.null(GALAXY_URL)){
    if(substr(GALAXY_URL, start=nchar(GALAXY_URL), stop=nchar(GALAXY_URL)) != '/'){ # Does it have a slash at the end
      pkg.env$GX_URL <- paste0(pkg.env$GX_URL, '/') # add a slash
    } else if(substr(GALAXY_URL, start=0, stop=4) != 'http'){ # Does it have a protocol?
      pkg.env$GX_URL <- paste0('http://', pkg.env$GX_URL) # add a protocol
      message(cat("Galaxy url was not prepended by the protocol, I constructed this url:",pkg.env$GX_URL))
    } else {
      pkg.env$GX_URL <- GALAXY_URL
    }
  } else if (is.null(GALAXY_URL) && is.na(pkg.env$GX_URL)){
      stop("You have not specified a Galaxy Url, please do so.")
  }


  if(!is.null(HISTORY_ID)){
    pkg.env$GX_HISTORY_ID <- HISTORY_ID
  }else if (is.null(HISTORY_ID) && is.na(pkg.env$GX_HISTORY_ID)){
      # set to latest history
      histories <- gx_list_histories()
      gx_switch_history(histories$id[1])
      message(paste0("You have not specified a history id, run gx_list_histories to see which are available. ",
                    "Current history is set to '",gx_current_history(),"'"))
  }
  gx_set_import_directory(IMPORT_DIRECTORY,create=TRUE)
  gx_set_tmp_directory(TMP_DIRECTORY,create=TRUE)
}

check_url_and_key <- function(){
  if(is.na(pkg.env$GX_URL) && is.na(pkg.env$GX_API_KEY)){
    stop("Please run gx_init(KEY,URL) to set your Galaxy API KEY and the Galaxy URL")
  }
  if(is.na(pkg.env$GX_URL)){
    stop("Please run gx_init(GALAXY_URL=URL) to set the Galaxy URL")
  }
  if(is.na(pkg.env$GX_API_KEY)){
    stop("Please run gx_init(API_KEY=KEY) to set your Galaxy API KEY")
  }
}

#' directory_exists
#'
#' Return directory name if exists. If create is TRUE, creates directory, else stop
#'
#' @param directory, the directory to check
#' @param create, directory if true
#'
#' @export

directory_exists <- function(directory,create='FALSE'){
  # ensure directory exists
  if (!dir.exists(directory)){
    if(create){
      dir.create(directory,recursive=TRUE)
    }else{
      stop(paste0(directory, 'does not exist. You can specify create=TRUE'))
    }
  }
  return(directory)
}

#' gx_get_import_directory
#'
#' This function returns the import directory to work with
#'
#' @param create, if TRUE, create import directory if it does not exist
#'
#' @export

gx_get_import_directory <- function(create=FALSE){
  if(is.na(pkg.env$GX_IMPORT_DIRECTORY)){
    gx_set_import_directory(create=create)
  }
  history_import_directory <- file.path(pkg.env$GX_IMPORT_DIRECTORY, pkg.env$GX_HISTORY_ID)
  return(directory_exists(history_import_directory,create=create))
}

#' gx_set_import_directory
#'
#' This function sets the import directory
#'
#' @param IMPORT_DIRECTORY, path to use as import directory, default /tmp/<username>/galaxy_import
#' @param create, default FALSE. If TRUE, try to create the directory if it doesn't exist
#'
#' @export

gx_set_import_directory <- function(IMPORT_DIRECTORY=NULL,create=FALSE){
  if(is.null(IMPORT_DIRECTORY)){
    username <- Sys.getenv('RSTUDIO_USER_IDENTITY')
    IMPORT_DIRECTORY <- file.path("/tmp",username,"galaxy_import")
  }
  directory_exists(IMPORT_DIRECTORY,create=create)
  pkg.env$GX_IMPORT_DIRECTORY <- IMPORT_DIRECTORY
}


#' gx_get_tmp_directory
#'
#' This function returns the tmp directory to work with
#'
#' @param create, if TRUE, create import directory if it does not exist
#'
#' @export

gx_get_tmp_directory <- function(create=FALSE){
  if(is.na(pkg.env$GX_TMP_DIRECTORY)){
    gx_set_tmp_directory(create=create)
  }
  return(directory_exists(pkg.env$GX_TMP_DIRECTORY,create=create))
}

#' gx_set_tmp_directory
#'
#' This function sets the tmp directory
#'
#' @param TMP_DIRECTORY, path to use as tmp directory, default $GX_IMPORT_DIRECTORY/tmp
#' @param create, default FALSE. If TRUE, try to create the directory if it doesn't exist
#'
#' @export

gx_set_tmp_directory <- function(TMP_DIRECTORY=NULL,create=FALSE){
  if(is.null(TMP_DIRECTORY)){
    TMP_DIRECTORY=file.path(gx_get_import_directory(create=create),"tmp")
  }
  directory_exists(TMP_DIRECTORY,create=create)
  pkg.env$GX_TMP_DIRECTORY <- TMP_DIRECTORY
}


#' gx_put
#'
#' This function uploads a dataset to the current Galaxy history
#'
#' @param filepath, Path to file
#' @param filename, Name of the file to display in Galaxy
#' @param file_type, auto-detect otherwise
#'
#' @export

gx_put <- function(filepath, filename='', file_type="auto"){
  check_url_and_key()
  url <- paste0(pkg.env$GX_URL,'api/tools?api_key=',pkg.env$GX_API_KEY)

  inputs_json <- sprintf(
    '{"files_0|NAME":"%s",
    "files_0|type":"upload_dataset",
    "dbkey": "?",
    "file_type":"%s",
    "ajax_upload":"true"}',filename,file_type
  )
  params=list(
      'files_0|file_data'=fileUpload(filepath),
      key=pkg.env$GX_API_KEY,
      tool_id='upload1',
      history_id=pkg.env$GX_HISTORY_ID,
      inputs=inputs_json)

  response <- fromJSON(postForm(url, .params=params,
           .opts = list(verbose = FALSE, header = TRUE)
           ))
  response$jobs
}

#' gx_list_history_datasets
#'
#' List datasets from the current history id
#'
#' @export

gx_list_history_datasets <- function(){
  check_url_and_key()
  hist_datasets <- fromJSON(
    paste0(pkg.env$GX_URL,'api/histories/',pkg.env$GX_HISTORY_ID,'/contents?key=',pkg.env$GX_API_KEY)
  )
  return(hist_datasets)
}

#' gx_show_dataset
#'
#' Show dataset info based
#'
#' @param dataset_encoded_id, the encoded dataset id which you can get from gx_list_history_datasets()
#'
#' @export

gx_show_dataset <- function(dataset_encoded_id){
  check_url_and_key()
  return(fromJSON(paste0(
    pkg.env$GX_URL,
    'api/datasets/',
    dataset_encoded_id,
    '?key=',pkg.env$GX_API_KEY
  )))
}

#' gx_get
#'
#' Download a dataset from the current Galaxy history by ID #
#'
#' @param file_id, ID number
#' @param create, if TRUE, create import directory if it does not exist
#' @param force, if TRUE, will download the file even if it already exists locally
#'
#' @export

gx_get <- function(file_id,create=FALSE,force=FALSE){
  check_url_and_key()
  hist_datasets <- gx_list_history_datasets()

  encoded_dataset_id <- hist_datasets[hist_datasets$hid==file_id,'id'] # Let's get some info about the data!
  name <- hist_datasets[hist_datasets$hid==file_id, 'name']
  hid <- hist_datasets[hist_datasets$hid==file_id, 'hid']

  if(!dir.exists(file.path(gx_get_import_directory(create=create), hid))){ # If the directory doesn't exist then we download!
    if(0 < file_id && file_id <= nrow(hist_datasets)){
      data_type <- hist_datasets[hist_datasets$hid == file_id, 'type'] # Check if it's a collection or not

      if(data_type == 'collection'){
        return(gx_get_collection(file_id, hist_datasets)) # get_collection calls gx_download_file which returns a file path
      } else {
        file_path <- file.path(gx_get_import_directory(create=create), hid, name)
        file_dir <- file.path(gx_get_import_directory(), hid)

        if(!dir.exists(file_dir)) { dir.create(file_dir) }

        gx_download_file(encoded_dataset_id, file_path, force)# gx_download_file returns a file path
        return(file_path)
      }
    } else {
      message(paste0("dataset #", file_id, " does not exist, please try again"))
    }
  } else {
    return(file.path(gx_get_import_directory(), hid, "null_name")) # use null_name because Pavian calls using dirname()
  }
}

#' gx_get_collection
#'
#' Correctly download the collection data into directories similar to gx_get()
#' gx_get is the parent call, in gx_get is where file_id is detemined to be a collection or not
#' If the file_id is a collection then this function will be called.
#'
#' @param file_id, ID number
#' @param hist_datasets, table of all dataset info
#' @param create, if TRUE, create import directory if it does not exist
#' @param force, if TRUE, will download the file even if it already exists locally
#'

gx_get_collection <- function(file_id, hist_datasets, create=FALSE, force=FALSE){

  file_dir <- file.path(gx_get_import_directory(), file_id) # Download directory
  if(!dir.exists(file_dir)) { dir.create(file_dir) } # Does the dir exist? No then let's make it!

  verified <- gx_verify_collection(file_id, hist_datasets)

  if(verified > -1){
    for(pos in seq(verified, file_id-1)){ # We do -1 so we don't include the collection
      encoded_dataset_id <- hist_datasets[hist_datasets$hid==pos,'id']
      name <- hist_datasets[hist_datasets$hid==pos, 'name']

      file_path <- file.path(gx_get_import_directory(create=create), file_id, name)

      gx_download_file(encoded_dataset_id, file_path, force) # This is returned on last iteration

    }

    return(file_path)
  } else {
    message("The data from this collection doesn't exist outside of the collection in this history") # Need to look into this!
    message("Please copy data into history first, then create a collection")

    return(NULL)
  }
}

#' gx_verify_collection
#'
#' @param file_d, ID number
#' @param hist_datasets, Datasets from Galaxy history

gx_verify_collection <- function(file_id, hist_datasets){

  is_populdated <- hist_datasets[hist_datasets$hid == file_id, 'populated']

  if(is_populdated){
    count <- count <- hist_datasets[hist_datasets$hid == file_id, 'element_count'] # grab the # of elements the collection contains
    start_pos <- file_id - count # Get the first position of the collection's data

    if(start_pos > 0){ # Is it positive? yes, that means some data exists
      # Now we need to check if the data is actually the data we think it is, how can we do this?
      #   gx_list_history_datasets() doesn't give us any of this information
      # Even if the collection exists last, we need its data to actually exist in the history, being hidden or visible.
      return(start_pos)
    } else { # No data exists before this collection
      return(-1)
    }
  }
}

#' gx_download_file
#'
#' Download a file from
#'
#' @param encoded_dataset_id, the data's encoded IDs
#' @param file_path, path to download to
#' @param force, force the download?
#'

gx_download_file <- function(encoded_dataset_id, file_path, force){
  dataset_details <- gx_show_dataset(encoded_dataset_id)

  if(!force && file.exists(file_path)){
    message("You already downloaded this file, use force=TRUE to overwrite")
  }

  if(dataset_details$state == 'ok' ){
    url <- paste0(
      pkg.env$GX_URL,'api/histories/',pkg.env$GX_HISTORY_ID,
      '/contents/',encoded_dataset_id,'/display',
      '?to_ext=',dataset_details$extension,
      '&key=',pkg.env$GX_API_KEY)

    download.file(url, file_path, quiet=TRUE) # Download the file
  }

  return(file_path)
}


#' gx_save
#'
#' Save the notebook .RData and .RHistory to Galaxy. Convenience function which wraps save.image and gx_put
#'
#' @param session_name, default "workspace"
#'
#' @export

gx_save <- function(session_name="workspace"){
  check_url_and_key()
  tmp_dir <- gx_get_tmp_directory()
  workspace <- file.path(tmp_dir,paste0(session_name,".RData"))
  hist <- file.path(tmp_dir,paste0(session_name,".RHistory"))
  save.image(workspace)
  savehistory(hist)
  gx_put(workspace)
  gx_put(hist)
}


#' gx_restore
#'
#' Restore the notebook from a .RData and .RHistory object from the current Galaxy history.
#'
#' @param rdata_id, .RData ID number
#' @param rhistory_id, .RHistory ID number
#'
#' @export

gx_restore <- function(rdata_id,rhistory_id){
  check_url_and_key()
  rdata <- gx_get(rdata_id)
  rhistory <- gx_get(rhistory_id)
  load(rdata,envir=.GlobalEnv)
  loadhistory(rhistory)
}

#' gx_latest_history
#'
#' Uses the Galaxy API histories/most_recently_used to get the last updated history
#'
#' @export

gx_latest_history <- function(){
  check_url_and_key()
  hist_obj <- fromJSON(
      paste0(pkg.env$GX_URL,'api/histories/most_recently_used?key=',pkg.env$GX_API_KEY)
  )
  return(hist_obj)
}

#' gx_switch_history
#'
#' Convenience method to set the current history id in the environment setting
#'
#' @param HISTORY_ID, the Galaxy history id to work on
#'
#' @export

gx_switch_history <- function(HISTORY_ID){
  check_url_and_key()
  pkg.env$GX_HISTORY_ID <- HISTORY_ID
  gx_set_tmp_directory(create=TRUE)
}

#' gx_current_history
#'
#' Show the name of the current history
#'
#' @param full, if True, return a list with some history details
#'
#' @export

gx_current_history <- function(full=FALSE){
  check_url_and_key()
  histories <- gx_list_histories()
  if (full){
    return(histories[histories$id==pkg.env$GX_HISTORY_ID,])
  }else{
    return(histories$name[histories$id==pkg.env$GX_HISTORY_ID])
  }
}

#' gx_list_histories
#'
#' List all Galaxy histories of the current user
#'
#' @export

gx_list_histories <- function(){
  check_url_and_key()
  return( fromJSON(paste0(pkg.env$GX_URL,'api/histories?key=',pkg.env$GX_API_KEY) ))
}
