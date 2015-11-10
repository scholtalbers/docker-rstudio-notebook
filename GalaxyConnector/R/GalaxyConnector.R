#' pkg.env
#' private environment
pkg.env <- new.env()

pkg.env$GX_API_KEY <- Sys.getenv('GX_API_KEY', unset=NA)
pkg.env$GX_URL <- Sys.getenv('GX_URL', unset=NA)
pkg.env$GX_HISTORY_ID <- Sys.getenv('GX_HISTORY_ID', unset=NA)
pkg.env$GX_IMPORT_DIRECTORY <- Sys.getenv('GX_IMPORT_DIRECTORY', unset=NA)
pkg.env$GX_TMP_DIRECTORY <- Sys.getenv('GX_TMP_DIRECTORY', unset=NA)

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

gx_init <- function(API_KEY=NULL, GALAXY_URL=NULL, HISTORY_ID=NULL,
                       IMPORT_DIRECTORY=NULL, TMP_DIRECTORY=NULL){
  if(!is.null(API_KEY)){
    pkg.env$GX_API_KEY <- API_KEY
  } else if (is.null(API_KEY) && is.na(pkg.env$GX_API_KEY)){
    stop("You have not set your API Key")
  }

  if(!is.null(GALAXY_URL)){
    pkg.env$GX_URL <- GALAXY_URL
  } else if (is.null(GALAXY_URL) && is.na(pkg.env$GX_URL)){
      stop("You have not specified a Galaxy Url, please do so.")
  }
  # horrible method to check for correct url construction, please fix
  if ( str_sub(pkg.env$GX_URL,-1) != '/' ){
    pkg.env$GX_URL <- paste0(pkg.env$GX_URL,'/')
  }
  if( str_sub(pkg.env$GX_URL,start=0,4) != 'http'){
    pkg.env$GX_URL <- paste0('http://',pkg.env$GX_URL)
    message(cat("Galaxy url was not prepended by the protocol, I constructed this url:",pkg.env$GX_URL))
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

gx_get <- function(file_id,create=FALSE,force=FALSE){
  check_url_and_key()
  file_path = file.path(gx_get_import_directory(create=create), file_id)
  if( !force && file.exists(file_path)){
    message("You already downloaded this file, use force=TRUE to overwrite")
    return(file_path)
  }
  hist_datasets <- gx_list_history_datasets()
  encoded_dataset_id <- hist_datasets[hist_datasets$hid==file_id,'id']
  dataset_details <- gx_show_dataset(encoded_dataset_id)

  if( dataset_details$state == 'ok' ){
    url <- paste0(
      pkg.env$GX_URL,'api/histories/',pkg.env$GX_HISTORY_ID,
      '/contents/',encoded_dataset_id,'/display',
      '?to_ext=',dataset_details$extension,
      '&key=',pkg.env$GX_API_KEY)
    download.file(url,file_path,quiet=TRUE)
  }
  return(file_path)
}


#' gx_save
#'
#' Save the notebook .RData and .RHistory to Galaxy. Convenience function which wraps save.image and gx_put
#'
#' @param session_name, default "workspace"

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

gx_list_histories <- function(){
  check_url_and_key()
  return( fromJSON(paste0(pkg.env$GX_URL,'api/histories?key=',pkg.env$GX_API_KEY) ))
}
