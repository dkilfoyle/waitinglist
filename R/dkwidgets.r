# shiny ui utiltieis

library(RJSONIO)

spreadsheetInput <- function(inputId = "exampleGrid", value, colHeaders="true", options="") {
  
  json_content <- toJSON(value, collapse = "")
  
  dataTableDef <- sprintf('
    $(window).load(function(){
      var myData = %s;
      
      $("#%s").handsontable({
        data: myData,
        startRows: 5,
        startCols: 5,
        minSpareCols: 0,
        minSpareRows: 0,
        rowHeaders: false,
        colHeaders: %s,
        contextMenu: true,
        %s
      });
    });', json_content, inputId, colHeaders, options)

  tagList(
    singleton(tags$head(tags$script(src = "js/handsontable/jquery.handsontable.full.js", type='text/javascript'))),
    singleton(tags$head(tags$script(src = "js/shiny-handsontable.js", type='text/javascript'))),
    singleton(tags$head(tags$link(rel="stylesheet", type="text/css", href="js/handsontable/jquery.handsontable.full.css"))),
    
    tags$div(id=inputId, class="dataTable"),   
    tags$script(type='text/javascript', dataTableDef)
  )
}

select2Input <- function(inputId, label, choices = NULL, selected = NULL, placeholder = "", ...) {

  tagList(
    
    singleton(tags$head(tags$link(href="js/select2/select2.css",rel="stylesheet",type="text/css"))),
    singleton(tags$head(tags$script(src="js/select2/select2.js"))),
    singleton(tags$head(tags$script(src="js/jquery-ui-1.10.3.custom.min.js"))),
    singleton(tags$head(tags$script(src="js/select2.sortable.js"))),
    
    # don't use Shiny 0.9+'s selectize as it clashses with select2
    # can't use selectize as it doesn't support sorting and reordering of selections
    selectInput(inputId, label, choices, selected, selectize=F, ...),
    tags$script(sprintf("$(function() { $('#%s').select2({width:'resolve', placeholder:'%s'}); $('#%s').select2Sortable(); })", inputId, placeholder, inputId))

  )
}

dkWidgets = function() {
  tagList(
    singleton(tags$head(tags$link(href="js/jquery-ui-slider/jquery-ui.css",rel="stylesheet",type="text/css"))),
    singleton(tags$head(tags$link(href="js/jquery-ui-slider/jquery-ui-slider-pips.css",rel="stylesheet",type="text/css"))),
    singleton(tags$head(tags$link(href="dkwidgets.css",rel="stylesheet",type="text/css"))),
    
    singleton(tags$head(tags$script(src="js/jquery-ui-slider/jquery-ui-dk.js"))), # customised to rename the $().slider to $().uislider to avoid clash with Shiny's jslider plugin
    singleton(tags$head(tags$script(src="js/jquery-ui-slider/jquery-ui-slider-pips.js")))
  )
}

dkSliderInput <- function(inputId, values=5, min = 0, max = 20, step=10, ...) {
  
  tagList(
    singleton(tags$head(tags$script(src="js/shiny-dkslider.js"))),
    tags$div(id=inputId, class="dkSlider"),
    tags$script(sprintf("$(function() { $('#%s').css('background-image', getSliderColors(%s)); $('#%s').uislider({min: %s, max: %s, values: %s, slide: function(evt,ui) {$(evt.target).css('background-image', getSliderColors(ui.values));}}); $('#%s').uislider('pips', {step:%s}); });", 
                        inputId, toJSON(values), inputId, min, max, toJSON(values), inputId, step))
  )
}

updateDkSlider = function(session, inputId, values) {
  session$sendInputMessage(inputId, list(values=values))
}

dkAccordion = function(...) {
    div(class="accordion", ...)
}

dkAccordionPanel = function(name, label, ..., expanded=F) {
  inclass = ifelse(expanded, "in", "")
  collapseRef = paste0("collapse", name)
  tagList(
    div(class="accordion-heading", 
        HTML(sprintf('<a class="accordion-toggle" data-toggle="collapse" href="#%s">%s</a>', collapseRef, label,'</a>'))
    ),
    div(id=collapseRef, class=paste("accordion-body collapse", inclass),
        div(class="accordion-inner", ...) #lapply(item, function(x) x))
    )
  )
}

disableControl <- function(id,session) {
  session$sendCustomMessage(type="jsCode",
                            list(code= paste("$('#",id,"').prop('disabled',true)",sep="")))
}

enableControl <- function(id,session) {
  session$sendCustomMessage(type="jsCode",
                            list(code= paste("$('#",id,"').prop('disabled',false)",sep="")))
}

jsCodeHandler = function() {
  tags$head(tags$script(HTML('
        Shiny.addCustomMessageHandler("jsCode",
          function(message) {
            console.log(message)
            eval(message.code);
          }
        );
      ')))
}

