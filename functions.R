# TODO: 
# - why chosing particular pos & deprel?
# - using lemma instead of original word? -> now using lemma
# - add inverse relationship?

###### prereq dependencies ######
# install.packages(c("tm", "cleanNLP", "coreNLP", "RCurl"))     # install NLP packages
# cnlp_download_corenlp()                                       # download coreNLP materials
#################################

library(tm)
library(cleanNLP)
###### to use in nellodee.si.umich.edu: ######
# dyn.load("/usr/lib/jvm/java-11-openjdk-amd64/lib/server/libjvm.so")
# cnlp_init_corenlp(anno_level = 1L, lib_location = "~/trunk/stanford-corenlp-full-2018-02-27/")
cnlp_init_corenlp(anno_level = 1L)


dep_tok_rel <- function(df_dep, df_tok){
  # tok_nva <- df_tok[df_tok$upos %in% c("NOUN", "VERB", "ADJ", "PRON"),]
  # dep_nva <- df_dep[df_dep$tid %in% tok_nva$tid & df_dep$tid_target %in% tok_nva$tid, ]
  # dep_nva <- df_dep[grep("*mod|*obj", df_dep$relation),]
  dep_nva <- df_dep[grep("*obj|*comp$|*dep", df_dep$relation),]
  tok_nva <- df_tok
  # print(list(tok_nva, dep_nva))
  
  df_res <- apply(dep_nva, 1, function(row){
    rel_reg <- c(tok_nva[(tok_nva$tid==as.numeric(row['tid']) & (tok_nva$sid==as.numeric(row['sid']))), 'lemma'], 
                 row['relation'], 
                 tok_nva[(tok_nva$tid==as.numeric(row['tid_target']) & (tok_nva$sid==as.numeric(row['sid']))), 'lemma'])
    # rel_inv <- c(tok_nva[tok_nva$tid==as.numeric(row['tid_target']), 'lemma'], row['relation'], tok_nva[tok_nva$tid==as.numeric(row['tid']), 'lemma'])
    # print(list(rel_reg, rel_inv))
    # print(rel_reg)
    
    # if(sum(tolower(rel_reg) %in% c(stopwords(), 'root', 'punct'))){ rel_reg <- NULL}
    # if(sum(tolower(rel_inv) %in% c(stopwords(), 'root', 'punct'))){ rel_inv <- NULL}
    # print(list(rel_reg, rel_inv))
    
    # rel_reg <- c(rel_reg[1], paste(rel_reg[2], rel_reg[3], sep=":"))
    # rel_inv <- c(rel_inv[1], paste(rel_inv[2], rel_inv[3], sep="_1:"))
    rel_reg <- c(rel_reg[1], rel_reg[3], rel_reg[2])
    # print(list(rel_reg, rel_inv))
    # print(rel_reg)
    
    
    if(length(rel_reg)>0){
      rel_df <- rbind(rel_reg)
      # rel_df <- rbind(rel_reg, rel_inv)
      rel_df <- data.frame(rel_df, stringsAsFactors = FALSE)
      # print(rel_df)
      
      # colnames(rel_df) <- c("word","deprel")
      colnames(rel_df) <- c("lemma","l_target","deprel")
      rownames(rel_df) <- NULL
      return(rel_df)
    }
    else{
      return(NULL)
    }
  })
  # print(df_res)
  
  if(!is.null(df_res)){
    df_res <- do.call(rbind, df_res)
  }
  
  # if(nrow(df_res)>0){
  #   colnames(df_res) <- c("word","deprel")
  #   rownames(df_res) <- NULL
  # }
  return(df_res)
}


consol_deptok <- function(annotate_txt){
  dep_res <- dep_tok_rel(annotate_txt$dependency, annotate_txt$token)
  return(dep_res)
}

topic_new_doc <- function(mod_post, df_dep){
  voc_dep <- df_dep[,"lemma"]
  voc_gov <- df_dep[,"l_target"]
  
  # multiplication of word pairs
  topic_pairs <- mapply(function(word_dep, word_gov){
    prob_dep <- 1
    prob_gov <- 1
    if(word_dep %in% colnames(mod_post$phi_dep)){
      prob_dep <- mod_post$phi_dep[,word_dep]
    }
    if(word_gov %in% colnames(mod_post$phi_gov)){
      prob_gov <- mod_post$phi_gov[,word_gov]
    }
    prob_pair <- prob_dep * prob_gov
    return(prob_pair)
  }, voc_dep, voc_gov)
  
  # summing topics per pair to represent a document
  # print(topic_pairs)
  topic_doc <- rep(0, ncol(mod_post$theta))
  if(length(topic_pairs)){
    topic_prob_doc <- rowSums(topic_pairs)
    topic_prob_doc <- topic_prob_doc/sum(topic_prob_doc)
    
    topic_doc <- sample.int(n=length(topic_prob_doc), size=100, replace=TRUE, prob=topic_prob_doc)
    topic_doc <- factor(topic_doc, levels=seq(length(topic_prob_doc)))
    topic_doc <- prop.table(table(topic_doc))
  }
  
  return(topic_doc)
}

