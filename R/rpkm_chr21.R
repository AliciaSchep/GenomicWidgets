#' rpkm_chr21
#' 
#' Subset of expression data from Roadmap Epigenomics data for use in examples
#' @format SummarizedExperiment with expression data in rpkm assay 
#' @source Roadmap Epigenomics Project
#' @docType data
#' @examples 
#' 
#' # Access data via:
#' data(rpkm_chr21)
#' 
#' # Code showing how data was created:
#' \dontrun{
#' 
#' library(AnnotationHub)
#' library(dplyr)
#' library(Homo.sapiens)
#' library(SummarizedExperiment)
#' 
#' ah <- AnnotationHub()
#' expr_data <- query(ah , c("EpigenomeRoadMap", "RPKM"))
#' rpkm_pc <- expr_data[["AH49019"]]
#' 
#' meta_data <- query(ah , c("EpigenomeRoadMap", "metadata"))[["AH41830"]]
#' 
#' entrez_mapping <- AnnotationDbi::select(Homo.sapiens, 
#'                                         rownames(rpkm_pc), 
#'                                         c("ENTREZID","SYMBOL"), 
#'                                         "ENSEMBL")
#' 
#' genes_mapping <- as.data.frame(genes(Homo.sapiens, 
#'                                      filter = 
#'                                        list("GENEID" = 
#'                                                    entrez_mapping$ENTREZID)))
#' genes_mapping$GENEID = vapply(genes_mapping$GENEID, as.character,"")
#' 
#' chr21 <- inner_join(entrez_mapping, genes_mapping, 
#'                     by = c("ENTREZID" = "GENEID")) %>% 
#'   mutate(seqnames = as.character(seqnames)) %>% 
#'   dplyr::filter(seqnames == "chr21")
#' 
#' chr21_uniq <- dplyr::group_by(chr21, ENSEMBL) %>% filter(row_number()==1) %>% 
#'   ungroup()
#' 
#' 
#' rpkm_chr21 <- SummarizedExperiment(assays = list(rpkm = 
#'                                as.matrix(rpkm_pc[chr21_uniq$ENSEMBL,2:57])), 
#'                                    colData = dplyr::filter(meta_data, 
#'                                                  EID %in% colnames(rpkm_pc)),
#'                                    rowRanges = as(chr21_uniq,
#'                                                   "GenomicRanges"))
#' 
#' 
#' }
"rpkm_chr21"