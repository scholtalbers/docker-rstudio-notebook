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
  }else{
    Sys.setenv('GX_URL'=GALAXY_URL)
  }

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
      stop(paste(directory, 'does not exist. You can specify create=TRUE'))
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
#' @param filename, Path to file
#' @param file_type, auto-detect otherwise

gx_put <- function(filename, file_type="auto"){
  command <- paste(
    Sys.getenv('GX_PYTHON_BIN'), Sys.getenv('GX_PYTHON_FILE'),
    "--action", "put", "--argument", filename, "--filetype", file_type)
  system(command)
}

#' gx_get
#'
#' Download a dataset from the current Galaxy history by ID #
#'
#' @param file_id, ID number
#' @param create, if TRUE, create import directory if it does not exist

gx_get <- function(file_id,create=FALSE){
  file_path = file.path(gx_get_import_directory(create=create), file_id)
  command <- paste(
    Sys.getenv('GX_PYTHON_BIN'), Sys.getenv('GX_PYTHON_FILE'),
    "--action", "get", "--argument", file_id, "--file-path", file_path)
  system(command)
  return(file_path)
}


#' gx_save
#'
#' Save the notebook .RData and .RHistory to Galaxy. Convenience function which wraps save.image and gx_put
#'
#' @param session_name, default "workspace"

gx_save <- function(session_name="workspace"){
  tmp_dir <- gx_get_tmp_directory()
  workspace <- paste(tmp_dir,session_name,".RData",sep="")
  hist <- paste(tmp_dir,session_name,".RHistory",sep="")
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
  gx_list_histories()
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
  read.delim(
    text=system2(
      Sys.getenv('GX_PYTHON_BIN'),
      args=paste(
        Sys.getenv('GX_PYTHON_FILE'),
        "--action",
        "histories"
      ),
      stdout=TRUE)
  )
}
