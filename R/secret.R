.auth <- gargle::init_AuthState(
  package     = "gsecret",
  auth_active = TRUE
  # app = NULL,
  # api_key = NULL,
  # cred = NULL
)

gsecret_auth_config<-function(app){
  .auth$set_app(app)
}
gsecret_auth_app <-function(){
  .auth$app
}

gsecret_has_token <- function() {
  inherits(.auth$cred, "Token2.0")
}

gsecret_token <- function(){
  if (isFALSE(.auth$auth_active)) {
    return(NULL)
  }
  if (!gsecret_has_token()) {
    gsecret_auth()
  }
  httr::config(token = .auth$cred)
}

gsecret_base_url <- function(){
  "https://secretmanager.googleapis.com"
}

#' Authorize gsecretR
#'
#' @description
#' Authorize gsecretR to access or create secrets stored in Secret Manager on Google Cloud Platform.
#' This function is based on [bigrquery::bq_auth()] and also wraps [gargle::token_fetch()].
#'
#'
#' @param email Optional, your google identity
#' @param path  path to GCP JSON key file for a service account
#' @param scopes required scopes.
#' @param cache Specifies the OAuth token cache
#' @param use_oob Should we use out-of-band authentication
#' @param token Pass in a token
#'
#' @return A token
#' @export
#'
gsecret_auth<-function(email = gargle::gargle_oauth_email(),
                         path = NULL,
                         scopes = "https://www.googleapis.com/auth/cloud-platform",
                         cache = gargle::gargle_oauth_cache(),
                         use_oob = gargle::gargle_oob_default(),
                         token = NULL){
  if (is.null(gsecret_auth_app())){
    stop("Secret Manager requires an oauth app specific for the project.")
  }
  cred <- gargle::token_fetch(
    scopes = scopes,
    app = gsecret_auth_app(),
    email = email,
    path = path,
    cache = cache,
    use_oob = use_oob,
    token = token
  )

  .auth$set_cred(cred)
  .auth$set_auth_active(TRUE)

  invisible(cred)
}

#' @rdname set_secret
#' @export
get_secret_version <- function(project_id,secret_id,version_id="latest"){
  token <- gsecret_token()

  path <- "v1/projects/{project_id}/secrets/{secret_id}/versions/{version_id}:access"
  params <- list(project_id=project_id,
                 secret_id=secret_id,
                 version_id=version_id)
  req <- gargle::request_build(method="GET",path=path,params = params,token = token,
                               base_url = gsecret_base_url())
  resp <- gargle::request_make(req)
  out <- gargle::response_process(resp)
  rawToChar(jsonlite::base64_dec(out$payload$data))
}


get_secret <- function(project_id,secret_id){
  token <- gsecret_token()

  path <- "v1/projects/{project_id}/secrets/{secret_id}"
  params <- list(project_id=project_id,secret_id=secret_id)
  req <- gargle::request_build(method="GET",path=path,params = params,token = token,
                               base_url = gsecret_base_url())
  resp <- gargle::request_make(req)
  if (httr::status_code(resp) == 404){
    message("... create a new secret ...")
    resp <- create_secret(project_id,secret_id)
  }

  gargle::response_process(resp)
}

create_secret <- function(project_id,secret_id){
  token <- gsecret_token()

  path <- "v1/projects/{project_id}/secrets?secretId={secret_id}"
  params <- list(project_id=project_id,
                 secret_id=secret_id)
  body = list(replication=list(automatic=c()))
  req <- gargle::request_build(method="POST",path=path,params = params,
                               body= body,
                               token = token, base_url = gsecret_base_url())
  gargle::request_make(req)
}

add_version_to_secret <- function(project_id,secret_id,b64_encoded_secret){
  token <- gsecret_token()
  path <- "v1/projects/{project_id}/secrets/{secret_id}:addVersion"
  params <- list(project_id=project_id,
                 secret_id=secret_id)
  body <- list(payload=list(data=b64_encoded_secret))
  req <- gargle::request_build(method="POST",path=path,params = params,
                               body= body,
                               token = token, base_url = gsecret_base_url())
  gargle::request_make(req)
}

#' Set a secret on Google Cloud
#' @description
#' `set_secret()` assigns a secret to an id in project.
#' `get_secret_version()` retrieves the secret with id from a project
#' by default, `get_secret_version()` returns the latest version of a
#' secret, but if you know the secret, you can select it by the version.
#'
#'
#' @param project_id   the project storing (and charged for) the secret
#' @param secret_id    the id of the secret
#' @param secret       a string secret
#' @param version_id   version id retrieved by get_secret_version
#'
#' @export
#'
set_secret <- function(project_id,secret_id,secret){
  token <- gsecret_token()

  path <- "v1/projects/{project_id}/secrets?secretId={secret_id}"
  params <- list(project_id=project_id,
                 secret_id=secret_id)

  ## the data can have a crc32c checksum.  Would
  ## be great to have.
  b64_secret <- jsonlite::base64_enc(secret)

  secret <- get_secret(project_id,secret_id)

  resp <- add_version_to_secret(project_id,secret_id,b64_secret)
  gargle::response_process(resp)
}


#   Install Package:           'Cmd + Shift + B'
#   Check Package:             'Cmd + Shift + E'
#   Test Package:              'Cmd + Shift + T'
