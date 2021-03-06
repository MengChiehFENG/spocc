#' Combine results from occ calls to a single data.frame
#'
#' @export
#'
#' @param obj Input from occ, an object of class `occdat`, or an object
#' of class `occdatind`, the individual objects from each source within the
#' `occdat` class.
#' @param what (character) One of data (default) or all (with metadata)
#'
#' @details
#' This function combines a subset of data from each data provider to a single
#' data.frame, or metadata plus data if you request `what="all"`. The
#' single data.frame contains the following columns:
#'
#' - name - scientific (or common) name
#' - longitude - decimal degree longitude
#' - latitude - decimal degree latitude
#' - prov - data provider
#' - date - occurrence record date
#' - key - occurrence record key
#'
#' @examples \dontrun{
#' # combine results from output of an occ() call
#' spnames <- c('Accipiter striatus', 'Setophaga caerulescens',
#'   'Spinus tristis')
#' out <- occ(query=spnames, from='gbif', gbifopts=list(hasCoordinate=TRUE),
#'   limit=10)
#' occ2df(out)
#' occ2df(out$gbif)
#'
#' out <- occ(
#'   query='Accipiter striatus',
#'   from=c('gbif','bison','ecoengine','ebird','inat'),
#'   gbifopts=list(hasCoordinate=TRUE), limit=2)
#' occ2df(out)
#' occ2df(out$bison)
#' occ2df(out$ecoengine)
#'
#' # or combine many results from a single data source
#' spnames <- c('Accipiter striatus', 'Spinus tristis')
#' out <- occ(query=spnames, from='ecoengine', limit=2)
#' occ2df(out$ecoengine)
#'
#' spnames <- c('Accipiter striatus', 'Spinus tristis')
#' out <- occ(query=spnames, from='gbif', limit=2)
#' occ2df(out$gbif)
#' }
occ2df <- function(obj, what = "data") {
  UseMethod("occ2df")
}

#' @export
occ2df.occdatind <- function(obj, what = "data") {
  as_tibble(rbind_fill(obj$data))
}

foolist <- function(x) {
  if (is.null(x)) {
    data.frame(NULL)
  } else {
    do.call(rbind_fill, x$data)
  }
}

#' @export
occ2df.occdat <- function(obj, what = "data") {
  what <- match.arg(what, choices = c("all", "data"))
  aa <- foolist(obj$gbif)
  bb <- foolist(obj$bison)
  cc <- foolist(obj$inat)
  dd <- foolist(obj$ebird)
  ee <- foolist(obj$ecoengine)
  vn <- foolist(obj$vertnet)
  id <- foolist(obj$idigbio)
  ob <- foolist(obj$obis)
  ala <- foolist(obj$ala)
  tmp <- rbind_fill(
    Map(
      function(x, y){
        if (NROW(x) == 0) {
          tibble()
        } else {
          dat <- x[ , c('name', 'longitude', 'latitude', 'prov',
                        pluck_fill(x, datemap[[y]]),
                        pluck_fill(x, keymap[[y]])) ]
          if (is.null(datemap[[y]])) {
            dat$date <- as.Date(rep(NA_character_, NROW(dat)))
          } else {
            dat <- rename(dat, stats::setNames("date", datemap[[y]]),
                          warn_missing = FALSE)
          }
          rename(dat, stats::setNames("key", keymap[[y]]))
        }
      },
      list(aa, bb, cc, dd, ee, vn, id, ob, ala),
      c('gbif','bison','inat','ebird','ecoengine',
        'vertnet','idigbio','obis','ala')
    )
  )
  tmpout <- list(
    meta = list(obj$gbif$meta, obj$bison$meta, obj$inat$meta,
                obj$ebird$meta, obj$ecoengine$meta, obj$vn$meta,
                obj$id$meta, obj$ob$meta, obj$ala$meta),
    data = tmp
  )
  if (what %in% "data") as_tibble(tmpout$data) else tmpout
}

datemap <- list(gbif = 'eventDate', bison = 'date', inat = 'observed_on',
                ebird = 'obsDt', ecoengine = 'begin_date',
                vertnet = "eventdate", idigbio = "datecollected",
                obis = "eventDate", ala = "eventDate")

keymap <- list(gbif = "key", bison = "occurrenceID", inat = "id",
               ebird = "locID", ecoengine = "key",
               vertnet = "occurrenceid", idigbio = "uuid", obis = "id",
               ala = "uuid")
