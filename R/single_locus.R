setMethod(single_locus_view,
          c("GRanges","character"),
          function(window, object, annotation = NULL, ..., 
                   track_names = ifelse(!is.null(names(object)),
                                        names(object),
                                        basename(object)),
                   groups = NULL,
                   share_y = FALSE,
                   fill = c('tozeroy','none'), 
                   relative = FALSE, 
                   showlegend = TRUE, 
                   colors = NULL, 
                   mode = 'lines',
                   annotation_position = c("top","bottom"),
                   annotation_size = 0.5){
            
            window <- as(window, "ViewRange")
            single_locus_view(window, object, annotation = annotation, ...,
                              track_names = track_names, groups = groups,
                              share_y = share_y, fill = match.arg(fill),
                              relative = relative, showlegend = showlegend,
                              colors = colors, mode = mode, 
                              annotation_position = match.arg(annotation_position),
                              annotation_size = annotation_size)
            
          })
            

setMethod(single_locus_view,
          c("ViewRange","character"),
          function(window, object, annotation = NULL, ..., 
                   track_names = ifelse(!is.null(names(object)),
                                        names(object),
                                        basename(object)),
                   groups = NULL,
                   share_y = FALSE,
                   fill = c('tozeroy','none'), 
                   relative = FALSE, 
                   showlegend = TRUE, 
                   colors = NULL, 
                   mode = 'lines',
                   annotation_position = c("top","bottom"),
                   annotation_size = 0.5){

            
            track_maker <- purrr::partial(make_signal_track, 
                                          window = window,
                                          fill = fill, 
                                          mode = mode, 
                                          showlegend = showlegend
            )
            
            if (!is.null(groups)){
              object_grouped <- split(object, groups)
              track_names_grouped <- split(track_names, groups)
              
              sm <- length(object)
              if (is.null(colors)){
                if (sm == 1){
                  colors = "black"
                } else if (sm <= 8){
                  colors = RColorBrewer::brewer.pal(sm,"Dark2")
                } else if (sm <= 12){
                  colors = RColorBrewer::brewer.pal(sm,"Paired")
                } else{
                  colors = rainbow(sm)
                }
              }
              
              colors_grouped <- lapply(split(seq_along(colors),groups),
                                       function(x){
                                         colors[x]
                                       })
              
              tracks <- purrr::pmap(list(object = object_grouped,
                                         track_names = track_names_grouped,
                                         colors = colors_grouped,
                                         name = names(object_grouped)), 
                                    track_maker)
            } else{
              if (is.null(colors)){ colors = rep("black",length(object))}
              
              tracks <- purrr::pmap(list(object = object,
                                         track_names = track_names,
                                         colors = colors), 
                                    track_maker)
              
            }
            
            if (!is.null(annotation)){
              if (match.arg(annotation_position) == "top"){
                heights = c(annotation_size, rep(1, length(tracks)))
                tracks = c(make_annotation_track(window,annotation),
                           unname(tracks))
              } else{
                heights = c(rep(1, length(tracks)), annotation_size)
                tracks = c(unname(tracks),make_annotation_track(window,annotation))
              }
            } else{
              heights = rep(1, length(tracks))
            }
            
            out <- new("LocusView", as(tracks,"SimpleList"), share_y = share_y,
                       view = window, heights = heights)
            
            return(out)  
            
          })

yaxis_names <- function(x, start = 1L){
 stopifnot(length(x) >= 1)
 out <- paste0("yaxis", seq(start, start + length(x) - 1))
 if (start == 1L) out[1] <- "yaxis"
 out
}

setMethod(get_layout, "AnnotationPlot",
          function(object, yname, domain, ...){
            
            out <- list()
            
            # y axis settings
            out[[yname]] = list(title = object@trackname,
                                domain = domain,
                                zeroline = FALSE,
                                showline = FALSE,
                                showticklabels = FALSE,
                                showgrid = FALSE,
                                ticks = "")

            return(out)
          })

setMethod(get_layout, "SignalPlot",
          function(object, yname, domain, range, ...){
            
            out <- list()
            
            # y axis settings
            out[[yname]] = list(title = object@trackname,
                                domain = domain,
                                zeroline = FALSE,
                                showgrid = FALSE,
                                range = range)
            
            return(out)
            
            
          })

setMethod(min, "SignalPlot",
          function(x, na.rm = TRUE){
            
          min(sapply(x@signal, min, na.rm = na.rm))
            
          })

setMethod(min, "AnnotationPlot",
          function(x, ...){
            NA
          })

setMethod(max, "SignalPlot",
          function(x, na.rm = TRUE){
            max(sapply(x@signal, max, na.rm = na.rm))
          })

setMethod(max, "AnnotationPlot",
          function(x, ...){
            NA
          })

setMethod(max, "LocusView",
          function(x){
            max(sapply(x, max, na.rm = TRUE), na.rm = TRUE)
          })

setMethod(min, "LocusView",
          function(x){
            min(sapply(x, min, na.rm = TRUE), na.rm = TRUE)
          })

setMethod(max, "MultiLocusView",
          function(x){
            max(sapply(x, max, na.rm = TRUE), na.rm = TRUE)
          })

setMethod(min, "MultiLocusView",
          function(x){
            min(sapply(x, min, na.rm = TRUE), na.rm = TRUE)
          })


setMethod(make_trace, signature = c(x = "LocusView"),
          definition = function(x, ynames, ...){
            traces <- unlist(purrr::map2(as.list(x), ynames, make_trace, view = x@view), 
                             recursive = FALSE)
            
            traces
          })

setMethod(make_shapes, signature = c(x = "LocusView"),
          definition = function(x, ynames, ...){
            shapes <- unlist(purrr::map2(as.list(x), ynames, make_shapes, view = x@view), 
                             recursive = FALSE)
            
            shapes
          })

setMethod(get_layout, signature = c(object = "LocusView"),
          definition = function(object, ynames, domains, range = NULL, ...){
            unlist(purrr::pmap(list(object = as.list(object), 
                                    yname = ynames,
                                    domain = domains),
                               get_layout,
                               range = range), recursive = FALSE)
          })


locus_to_plotly_list <- function(x, ystart = 1L){
  ynames <- yaxis_names(x, ystart)
  traces <- make_trace(x, ynames)
    
  if (x@share_y){
    range = c(min(x), max(x))
  } else{
    range = NULL
  }
  layout_setting <- list(xaxis = 
                           list(title = as.character(seqnames(x@view)),
                                zeroline = FALSE,
                                #showline = FALSE,
                                anchor = gsub("yaxis","y",ynames[length(ynames)]),
                                range = c(relative_position(x@view, start(x@view)),
                                           relative_position(x@view, end(x@view)))))
  sizes = x@heights / sum(x@heights)
  domains = list()
  start_domain <- 0
  for (i in rev(seq_along(x))){
    domains[[i]] <- c(start_domain, start_domain + (sizes[i]*0.95))
    start_domain <- start_domain + sizes[i]
  }
  
  layout_setting <- c(layout_setting,
                      get_layout(x, ynames, domains, range))
  
  shapes <- make_shapes(x, ynames)

  layout_setting$shapes <- shapes
    
  out <- list(data = traces,
              layout = layout_setting,
              source = "Annotation Track",#,x@source,
              config = list(modeBarButtonsToRemove =
                              c("sendDataToCloud",
                                "autoScale2d")))
  attr(out, "TOJSON_FUNC") <- function(x, ...) {
    jsonlite::toJSON(x, digits = 50, auto_unbox = TRUE, force = TRUE,
                     null = "null", na = "null", ...)
  }
  out
}

#' @export
setMethod(to_widget,
          c("LocusView"),
          function(p){
            out <- locus_to_plotly_list(p)
            htmlwidgets::createWidget(
              name = "chipVis",
              x = out,
              width = out$layout$width,
              height = out$layout$height,
              sizingPolicy = htmlwidgets::sizingPolicy(browser.fill = TRUE,
                                                       viewer.fill = TRUE,
                                                       defaultWidth = "100%",
                                                       defaultHeight = 400),
              dependencies = plotly_dependency())
          })