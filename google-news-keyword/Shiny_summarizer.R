library(shiny)
library(ggplot2)
library(xml2)
library(rvest)
library(lexRankr)
library(officer)
library(downloader)
library(stringr)
library(qdapRegex)

ui <- fluidPage(
  # App title ----
  titlePanel("Download summarized documents"),
  textInput('keyword', 'Enter keyword :', ""),
  # Button
  downloadButton("downloadData", "Download")
)

server <- function(input, output) {
  
  print_doc <- reactive({ 
    #function that summarize an artcile into n sentences
    summarize <- function(page, n) {
      
      #extract text from page html using selector
      page_text = rvest::html_text(rvest::html_nodes(page, "p"))
      top_n = lexRankr::lexRank(page_text,
                                #only 1 article; repeat same docid for all of input vector
                                docId = rep(1, length(page_text)),
                                #return 3 sentences to mimick /u/autotldr's output
                                n = n,
                                continuous = TRUE)
      #reorder the top 4 sentences to be in order of appearance in article
      order_of_appearance = order(as.integer(gsub("_","",top_n$sentenceId)))
      #extract sentences in order of appearance
      ordered_top_n = top_n[order_of_appearance, "sentence"]
      #format sentences
      formatted_top_n = paste(ordered_top_n[1], ordered_top_n[2], ordered_top_n[3], ordered_top_n[4], sep = "\n")
      return(formatted_top_n)
    }
    
    google_articles <- function(google_pages) {
      links <- NULL
      for (page in google_pages) {
        google <- (read_html(page) %>% html_nodes("a") %>% html_attr("href"))[17:26] 
        temp_links <- qdapRegex::ex_between(google, "/url?q=", "&sa=U")
        temp_links <- unlist(temp_links)
        links <- c(links, temp_links)
      }
      return(links)
    }
    
    summary_doc <- function(urls) {
      doc <- read_docx()
      for (url in urls) {
        #read page html
        summarized_sentences = "Summary not available"
        tryCatch({
          page = xml2::read_html(url)
          summarized_sentences <- summarize(page, 4)
        }, error=function(e) { NULL })
        
        doc <- body_add_par(doc, url, style = "heading 2")
        doc <- body_add_par(doc, summarized_sentences)
      }
      return(doc)
    }
    
    download_google_html <- function(keywords) {
      google_1 <- paste0("https://www.google.com/search?q=", keywords, "&rlz=1C1CAFC_enUS855US855&sxsrf=ALiCzsY9cF5OlrYfh8TyqIVIGtM0PJUo5g:1657048596520&source=lnms&tbm=nws&sa=X&ved=2ahUKEwis_uGHu-L4AhUblGoFHSWaCIEQ_AUoAXoECAIQAw")
      google_2 <- paste0("https://www.google.com/search?q=", keywords, "&rlz=1C1CAFC_enUS855US855&tbm=nws&sxsrf=ALiCzsY9OeOzljOuzfm19ABS9SZ5H_ZA8w:1657048611785&ei=I47EYoC8L-2iqtsPoZ6Z-Ac&start=10&sa=N&ved=2ahUKEwjA2YWPu-L4AhVtkWoFHSFPBn8Q8tMDegQIARA4&biw=1280&bih=577&dpr=1.5")
      google_3 <- paste0("https://www.google.com/search?q=", keywords, "&rlz=1C1CAFC_enUS855US855&tbm=nws&sxsrf=ALiCzsZi10xaIsqF6AbNw5HpiTNtWUecLg:1657048633315&ei=OY7EYq7kEoagqtsP_dWc4AE&start=20&sa=N&ved=2ahUKEwju5KeZu-L4AhUGkGoFHf0qBxw4ChDy0wN6BAgBEDo&biw=1280&bih=577&dpr=1.5")
      
      todownload <- c(google_1, google_2, google_3)
      
      filenames <- NULL
      
      for(i in 1:length(todownload)) {
        temp_dest <- paste0("Inputs/", keywords, as.character(i), ".html")
        download.file(todownload[i], destfile = temp_dest, mode = "wb")
        filenames <- c(filenames, temp_dest)
      }
      
      all_articles <- google_articles(filenames)
      return(all_articles)
      
    }
    
    create_documents <- function(keywords) {
      for (keyword in keywords) {
        articles_list <- download_google_html(keyword)
        articles_doc <- summary_doc(articles_list)
        return(articles_doc)
      }
    }
    
    t <- input$keyword
    return(create_documents(as.vector(t)))
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("report-", Sys.Date(), ".docx", sep="")
    },
    content = function(file) {
      temp_doc <- print_doc()
      print(temp_doc, target = file)
    }
  )
}

shinyApp(ui, server)
