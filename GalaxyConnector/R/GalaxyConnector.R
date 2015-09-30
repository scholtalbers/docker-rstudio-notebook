#' gx_init
#'
#' Function that wraps the setenv calls to set the appropriate Galaxy environment variables
#'
#' @param API_KEY, to access your Galaxy account
#' @param GALAXY_URL, the Galaxy instance to work with
#' @param HISTORY_ID, the Galaxy history id to work on
#' @param IMPORT_DIRECTORY, default '/tmp/<username>/galaxy_import'
#' @param TMP_DIRECTORY, default '/tmp/<username>/galaxy_import/tmp'

gx_init <- function(API_KEY=NULL, GALAXY_URL=NULL, HISTORY_ID=NULL,
                       IMPORT_DIRECTORY=NULL, TMP_DIRECTORY=NULL){
  if(is.null(API_KEY)){
    API_KEY=Sys.getenv('GX_API_KEY',unset=NA)
    if(is.na(API_KEY)){
      stop("You have not set your API Key")
    }
  }else{
    Sys.setenv('GX_API_KEY'=API_KEY)
  }
  if(is.null(HISTORY_ID)){
    HISTORY_ID=Sys.getenv('GX_HISTORY_ID',unset=NA)
    if(is.na(HISTORY_ID)){
      # set to latest history
      HISTORY_ID=gx_switch_history(gx_list_histories[1,1])
      message(cat("You have not specified a history id, run gx_list_histories to see which are available. ",
                    "Current history is set to",HISTORY_ID))
    }
  }else{
    Sys.setenv('GX_HISTORY_ID'=HISTORY_ID)
  }
  if(is.null(GALAXY_URL)){
    GALAXY_URL=Sys.getenv('GX_URL',unset=NA)
    if(is.na(GALAXY_URL)){
      stop("You have not specified a Galaxy Url, please do so.")
    }
  }

  # horrible method to check for correct url construction, please fix
  if ( str_sub(GALAXY_URL,-1) != '/' ){
    GALAXY_URL <- paste0(GALAXY_URL,'/')
  }
  if( str_sub(GALAXY_URL,start=0,4) != 'http'){
    GALAXY_URL <- paste0('http://',GALAXY_URL)
    message(cat("Galaxy url was not prepended by the protocol, I constructed this url:",GALAXY_URL))
  }
  Sys.setenv('GX_URL'=GALAXY_URL)

  gx_set_import_directory(IMPORT_DIRECTORY,create=TRUE)
  gx_set_tmp_directory(TMP_DIRECTORY,create=TRUE)
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
  if(is.na(Sys.getenv('GX_IMPORT_DIRECTORY',unset=NA))){
    gx_set_import_directory(create=create)
  }
  import_directory=Sys.getenv('GX_IMPORT_DIRECTORY')
  history = Sys.getenv('GX_HISTORY_ID')
  history_import_directory = file.path(import_directory, history)
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
    IMPORT_DIRECTORY=file.path("/tmp",username,"galaxy_import")
  }
  directory_exists(IMPORT_DIRECTORY,create=create)
  Sys.setenv('GX_IMPORT_DIRECTORY'=IMPORT_DIRECTORY)
}


#' gx_get_tmp_directory
#'
#' This function returns the tmp directory to work with
#'
#' @param create, if TRUE, create import directory if it does not exist

gx_get_tmp_directory <- function(create=FALSE){
  if(is.na(Sys.getenv('GX_TMP_DIRECTORY',unset=NA))){
    gx_set_tmp_directory(create=create)
  }
  return(directory_exists(Sys.getenv('GX_TMP_DIRECTORY'),create=create))
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
  Sys.setenv('GX_TMP_DIRECTORY'=TMP_DIRECTORY)
}


#' gx_put
#'
#' This function uploads a dataset to the current Galaxy history
#'
#' @param filepath, Path to file
#' @param filename, Name of the file to display in Galaxy
#' @param file_type, auto-detect otherwise

gx_put <- function(filepath, filename='', file_type="auto"){
  api_key = Sys.getenv('GX_API_KEY')
  url <- paste0(Sys.getenv('GX_URL'),'api/tools/?api_key=',api_key)
  history_id = Sys.getenv('GX_HISTORY_ID')

  inputs_json <- sprintf(
    '{"files_0|NAME":"%s",
    "files_0|type":"upload_dataset",
    "dbkey": "?",
    "file_type":"%s",
    "ajax_upload":"true"}',filename,file_type
  )
  params=list(
      'files_0|file_data'=fileUpload(filepath),
      key=api_key,
      tool_id='upload1',
      history_id=history_id,
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
  hist_datasets <- fromJSON(
    paste0(Sys.getenv('GX_URL'),'api/histories/',Sys.getenv('GX_HISTORY_ID'),'/contents?key=',Sys.getenv('GX_API_KEY'))
  )
  return(hist_datasets)
}

#' gx_show_dataset
#'
#' Show dataset info based
#'
#' @param dataset_encoded_id, the encoded dataset id which you can get from gx_list_history_datasets()

gx_show_dataset <- function(dataset_encoded_id){
  return(fromJSON(paste0(
    Sys.getenv('GX_URL'),
    'api/datasets/',
    dataset_encoded_id,
    '/?key=',Sys.getenv('GX_API_KEY')
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
      Sys.getenv('GX_URL'),'api/histories/',Sys.getenv('GX_HISTORY_ID'),
      '/contents/',encoded_dataset_id,'/display',
      '?to_ext=',dataset_details$extension,
      '&key=',Sys.getenv('GX_API_KEY'))
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
  tmp_dir <- gx_get_tmp_directory()
  workspace <- paste0(tmp_dir,session_name,".RData")
  hist <- paste0(tmp_dir,session_name,".RHistory")
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
  rdata <- gx_get(rdata_id)
  rhistory <- gx_get(rhistory_id)
  load(rdata,envir=.GlobalEnv)
  loadhistory(rhistory)
}

#' gx_latest_history
#'
#' Set the current history to the last updated in Galaxy
#'
gx_latest_history <- function(){
  hist_obj <- fromJSON(
      paste0(Sys.getenv('GX_URL'),'api/histories/most_recently_used/?key=',Sys.getenv('GX_API_KEY'))
  )
  return(hist_obj$id)
}

#' gx_switch_history
#'
#' Convenience method to set the current history id in the environment setting
#'
#' @param HISTORY_ID, the Galaxy history id to work on

gx_switch_history <- function(HISTORY_ID){
  Sys.setenv('GX_HISTORY_ID'=HISTORY_ID)
  gx_set_tmp_directory(create=TRUE)
}


#' gx_list_histories
#'
#' List all Galaxy histories of the current user

gx_list_histories <- function(){
  return( fromJSON(paste0(Sys.getenv('GX_URL'),'api/histories/?key=',Sys.getenv('GX_API_KEY')) ))
}
