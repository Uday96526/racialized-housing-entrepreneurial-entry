#import libraries
options(scipen=999); "%notin%" <- Negate("%in%")
lib_list <- c('dplyr','ipumsr','ggplot2','dtplyr','stringr','tidyr','rvest','httr','readxl','data.table')
lapply(lib_list, library, character.only=TRUE)

#cps object
cps <- setRefClass(
  'cps',
  #object parameters
  fields = list(
    poi='numeric', #period of interest
    voi='character', #variables of interest
    importType='character',
    localPath='character' #cps data import type...api or local
  ),
  #object methods
  methods = list(
    #initialize object parameters
    initialize = function(...){ 
      if(missing(...)){
        .self$poi <- c(c(2024,1),c(2024,3)) #c(start,end) date...date format: (year,month)
        .self$voi <- c('age','race','classwkr') #cps defined variables
        .self$importType <- 'local' 
        .self$localPath <- ''
      }else{ 
        #extract parameters
        params <- list(...) 
        #poi parameter
        if('poi' %in% names(params)){
          if(length(params$poi) == 4 & 
             mean(c(params$poi[1],params$poi[3]) %in% c(1962:format(Sys.Date(),'%Y'))) == 1 & 
             params$poi[3] >= params$poi[1] & 
             mean(c(params$poi[2],params$poi[4]) %in% c(1:12)) == 1){ 
            if(params$poi[3] == params$poi[1] & params$poi[2] > params$poi[4]){ 
              warning('ensure that the end_date month is greater than start_date month: \n c(c(2024,1),(2024,3))...meaning: c(c(start_year,start_month),c(end_year,end_month))')
            }else{.self$poi <- params$poi} 
          }else{warning('poi expects a vector of two dates in the format: \n c(c(2024,1),(2024,3))...meaning: c(c(start_year,start_month),c(end_year,end_month))')}
        }else{.self$poi <- c(c(2024,1),c(2024,3))} 
        #voi parameter
        if('voi' %in% names(params)){
          if(is.atomic(params$voi) & is.character(params$voi)){ 
            .self$voi <- params$voi 
          }else{warning('voi expects a vector of cps defined variables in the format: \n c(race,age,classwkr)...meaning: c(variable1,variable2,...,variablen)')}
        }else{.self$voi <- c('age','race','classwkr')} 
        #importType parameter
        if('importType' %in% names(params)){
          if(params$importType %in% c('api','local')){ 
            .self$importType <- params$importType 
          }else{warning('importType expects a single string...either api (for api import) or local (for local import)')}
        }else{.self$importType <- 'local'} 
        #localPath parameter
        if('localPath' %in% names(params)) {
          if(is.character(params$localPath) && length(params$localPath) == 1) {
            .self$localPath <- params$localPath
          }else{warning('localPath expects a single string representing the file path')}
        }else{
          if(.self$importType == 'local') {
            .self$localPath <- ''  
          }else{.self$localPath <- 'NA'}}
      }
    },  
    
    #base cps data import 
    base.df = function(){ 
      if(.self$importType == 'api'){ 
        #initialize samples
        sample_info <- get_sample_info('cps')
        #define import date ranges
        start_date <- c(.self$poi[1],.self$poi[2])
        end_date <- c(.self$poi[3],.self$poi[4])
        #initialize code data with user defined date ranges
        code_df <- 
          data.frame(date = seq(as.Date(paste(start_date[1],'-',start_date[2],'-1',sep='')),
                                as.Date(paste(end_date[1],'-',end_date[2],'-1',sep='')),
                                by='month')) %>%
          mutate(description = paste('IPUMS-CPS,', 
                                     format(date,'%B'),
                                     format(date,'%Y'))) %>%
          merge(sample_info,by='description') 
        #initialize extract parameters
        extract_samples <- code_df$name 
        variable_names <- c(.self$voi) 
        #run cps data workflow
        cps_df <- 
          define_extract_micro(collection = "cps", 
                               description = paste('cps ',
                                                   start_date[1],'-',start_date[2], ' to',
                                                   end_date[1],'-',end_date[2],' extract.'),
                               samples = extract_samples, 
                               variables = variable_names) %>% 
          submit_extract() %>% 
          wait_for_extract() %>% 
          download_extract() %>% 
          read_ipums_micro() 
        colnames(cps_df) <- tolower(colnames(cps_df)) 
      }else{ 
        cps_df <- suppressMessages(read_ipums_micro(.self$localPath))
        colnames(cps_df) <- tolower(colnames(cps_df))
      }
      return(cps_df)
    },
    
    #entrepreneurship df with HPI integration
    entrepreneurship.df = function(ind1990Link='character',hpiCountyLink='character'){
      #define base cps df
      cps_df <- .self$base.df()
      
      #required cps variables
      entrepreneurship.cols <- c('race','hispan','nchild','sex',
                                 'educ','ind1990','age','statefip',
                                 'county','individcc','classwkr','mish') 
      
      #base file column check
      if(mean(entrepreneurship.cols %in% colnames(cps_df)) != 1){
        return('valid cps variables (voi) required...entrepreneurship.df method expects the variables: race, hispan, nchild, sex, educ, ind1990, age, statefip, county, individcc, classwkr, & mish')
      }
      
      #engineer race variable - using consistent approach from df_wk.Rmd
      cps_df <- 
        cps_df %>%
        mutate(
          # Create race_hispan more safely
          race_hispan = case_when(
            hispan == 0 ~ as.character(paste0(race, "000")),
            TRUE ~ as.character(paste0(race, hispan))
          ),
          # Convert to numeric safely, handling any conversion issues
          race_hispan_num = suppressWarnings(as.numeric(race_hispan)),
          # Create race factor based on the numeric version
          race = as.factor(case_when(
            race_hispan_num == 100000 ~ 'White Non-Hispanic',
            race_hispan_num == 200000 ~ 'Black Non-Hispanic',
            str_detect(as.character(race_hispan_num), "^6\\d*000$") ~ 'Asian & Pacific Islander Non-Hispanic',
            race_hispan_num == 300000 ~ 'American Indian Non-Hispanic',
            race_hispan_num == 700000 ~ 'Other Non-Hispanic',
            str_detect(as.character(race_hispan_num), "^8\\d*000$") ~ 'Multi-racial Non-Hispanic',
            race != 999 & hispan != 0 ~ 'Hispanic',
            TRUE ~ 'Unknown/Missing'  # Catch any remaining cases
          ))
        )
      
      #html setup for industry codes
      suppressWarnings({
        read_html(ind1990Link) %>%
          html_element('head') %>%
          html_elements('script') -> html_list
        html_list[4] %>% html_text() -> html_string
        pattern <- 'categories:\\s*(.*?)\\\n      longSamplesHeader:'
        filtered_html_string <- regmatches(html_string,regexec(pattern,html_string))[[1]][2] 
        filtered_html_string %>% 
          str_split('\\},\\{') -> ind_code_list
        ind_code_list <- ind_code_list[[1]]
        
        ind_code_df <- data.frame(); category_id <- 0
        for(code in 1:length(ind_code_list)){
          str_split(ind_code_list[code],',')[[1]] %>%
            str_split(':') -> temp_html
          string_df <- data.frame(row_count=c(1,2))
          for(temp_string in temp_html){
            if(length(temp_string) > 2){
              temp_string <- temp_string[1:2]}
            temp_string_df <- as.data.frame(temp_string)
            colnames(temp_string_df) <- temp_string_df[1,]
            if(nrow(temp_string_df)==2){
              string_df <- cbind(string_df,temp_string_df)
              string_df <- string_df[-1,]}}
          string_df <- 
            string_df %>% 
            dplyr::select(-c(row_count)) %>%
            lapply(gsub, pattern = '"', replacement = '') %>%
            as.data.frame()
          colnames(string_df) <- gsub('X.','',colnames(string_df))
          colnames(string_df)[1] <- 'id.'
          ind_code_df <- rbind(ind_code_df,string_df %>% dplyr::select('id.','label.','indent.','code.','general.'))
        }
      })
      
      #extract industries
      header_ind_code_df <- 
        ind_code_df %>%
        dplyr::select(-c(general.,id.)) %>%
        mutate(`indent.` = case_when((`indent.` == 0 & code. == 'null') | 
                                       (indent.== 0 & label.=='NIU') |
                                       (indent.== 0 & label.=='Unknown') ~ 1,
                                     .default = 0),
               ind_category = cumsum(`indent.`),
               naics_code = case_when(ind_category == 1 | ind_category == 16 ~ 0,
                                      ind_category == 2 ~ 11,
                                      ind_category == 3 ~ 21,
                                      ind_category == 4 ~ 23,
                                      ind_category == 5 ~ 31,
                                      ind_category == 6 ~ 48,
                                      ind_category == 7 ~ 42,
                                      ind_category == 8 ~ 44,
                                      ind_category == 9 ~ 52,
                                      ind_category == 10 ~ 56,
                                      ind_category == 11 ~ 0,
                                      ind_category == 12 ~ 71,
                                      ind_category == 13 ~ 54,
                                      ind_category == 14 ~ 92,
                                      ind_category == 15 ~ 0,
                                      .default = 0)) %>%
        filter((indent.==1 & label.!='NIU')|(indent.==1 & label.=='NIU')) %>%
        rename(ind1990 = code.) %>%
        mutate(label. = case_when(label. == 'TRANSPORTATION' ~ 'TRANSPORTATION, COMMUNICATIONS, AND OTHER PUBLIC UTILITIES',
                                  label. == 'FINANCE' ~ 'FINANCE, INSURANCE, AND REAL ESTATE',
                                  .default = label.)) 
      
      #extract industry sub sectors
      body_ind_code_df <-
        ind_code_df %>%
        dplyr::select(-c(general.,id.)) %>%
        mutate(`indent.` = case_when((`indent.` == 0 & code. == 'null') | 
                                       (indent.== 0 & label.=='NIU') |
                                       (indent.== 0 & label.=='Unknown') ~ 1,
                                     .default = 0),
               ind_category = cumsum(`indent.`),
               naics_code = case_when(ind_category == 1 | ind_category == 16 ~ 0,
                                      ind_category == 2 ~ 11,
                                      ind_category == 3 ~ 21,
                                      ind_category == 4 ~ 23,
                                      ind_category == 5 ~ 31,
                                      ind_category == 6 ~ 48,
                                      ind_category == 7 ~ 42,
                                      ind_category == 8 ~ 44,
                                      ind_category == 9 ~ 52,
                                      ind_category == 10 ~ 56,
                                      ind_category == 11 ~ 0,
                                      ind_category == 12 ~ 71,
                                      ind_category == 13 ~ 54,
                                      ind_category == 14 ~ 92,
                                      ind_category == 15 ~ 0,
                                      .default = 0)) %>%
        filter((indent.==0 & label.!='NIU')|(indent.==1 & label.=='NIU')) %>%
        rename(ind1990 = code.) 
      
      #extract sub sector information
      body_ind_code_df %>%
        mutate(
          naics_code = case_when(str_detect(as.character(ind1990),"^(44|800|852|732)\\d*") ~ 51,
                                 str_detect(as.character(ind1990),"^(45|47)\\d*") ~ 22,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('712','742') ~ 53,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('842','850','851','860') ~ 61,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('812','820','821','822','830','831',
                                                '832','840','861','862','863','870','871') ~ 62,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('762','770','641') ~ 72,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('761','771','772','780','781','782',
                                                '790','791','881','750','751','752',
                                                '760','880','873') ~ 81,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('722','741','740','731','471') ~ 56,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('872') ~ 71,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('721') ~ 54,
                                 .default = naics_code),
          ind = case_when(naics_code == 11 ~ 'Agriculture, Forestry, Fishing and Hunting',
                          naics_code == 21 ~ 'Mining, Quarrying, and Oil and Gas Extraction',
                          naics_code == 22 ~ 'Utilities',
                          naics_code == 23 ~ 'Construction',
                          naics_code == 31 ~ 'Manufacturing',
                          naics_code == 42 ~ 'Wholesale Trade',
                          naics_code == 44 ~ 'Retail Trade',
                          naics_code == 48 ~ 'Transportation and Warehousing',
                          naics_code == 51 ~ 'Information',
                          naics_code == 52 ~ 'Finance and Insurance',
                          naics_code == 53 ~ 'Real Estate and Rental and Leasing',
                          naics_code == 54 ~ 'Professional, Scientific, and Technical Services',
                          naics_code == 56 ~ 'Administrative and Support and Waste Management and Remediation Services',
                          naics_code == 61 ~ 'Educational Services',
                          naics_code == 62 ~ 'Health Care and Social Assistance',
                          naics_code == 71 ~ 'Arts, Entertainment, and Recreation',
                          naics_code == 72 ~ 'Accommodation and Food Services',
                          naics_code == 81 ~ 'Other Services (except Public Administration)',
                          naics_code == 92 ~ 'Public Administration (not covered in economic census)',
                          .default = 'NIU')) %>%
        filter(ind1990!='null') %>%
        rename(subsector = label., ind_naics_code = naics_code) %>%
        group_by(ind_naics_code,ind1990,ind,subsector) %>%
        reframe(ind_naics_code,ind1990,ind,subsector) -> naics_code_df
      
      #include industry information to cps data
      cps_df <- merge(cps_df %>% mutate(ind1990 = as.character(ind1990)),naics_code_df,by='ind1990')
      
      #engineer educational attainment variable
      cps_df <-
        cps_df %>%
        mutate(educ = as.numeric(educ),
               educ = as.factor(case_when(educ <= 72 ~ 'a', #less than high school
                                          educ == 73 ~ 'b', #high school
                                          educ %in% c(81,100,121,122) ~ 'c', #some college
                                          educ %in% c(91,92,111) ~ 'd', #college degree
                                          educ %in% c(123,124,125) ~ 'e', #graduate degree
                                          .default = '0')))
      
      # Use data.table for robust entrepreneurship variable calculation
      setDT(cps_df)
      
      # Create lagged variables by individual (cpsidp)
      cps_df[, `:=`(
        prev_classwkr = shift(classwkr, 4, type = "lag"),
        prev_mish = shift(mish, 4, type = "lag")
      ), by = cpsidp]
      
      # entrepreneurship1: Transition to unincorporated or incorporated self-employment (classwkr 13 or 14)
      cps_df[, entrepreneurship1 := as.integer(
        !is.na(prev_classwkr) &
          !is.na(prev_mish) &
          mish >= 5 &
          prev_mish == (mish - 4) &
          !(prev_classwkr %in% c(13, 14)) &  # Not previously self-employed
          classwkr %in% c(13, 14)            # Now self-employed
      )]
      
      # entrepreneurship2: Transition to incorporated self-employment (classwkr 14)
      cps_df[, entrepreneurship2 := as.integer(
        !is.na(prev_classwkr) &
          !is.na(prev_mish) &
          mish >= 5 &
          prev_mish == (mish - 4) &
          !(prev_classwkr %in% c(14)) &      # Not previously incorporated
          classwkr == 14                     # Now incorporated
      )]
      
      # Convert back to data.frame for consistency
      cps_df <- as.data.frame(cps_df)
      
      #include hpi information
      if(!missing(hpiCountyLink) && hpiCountyLink != 'character'){
        #define a temporary file with the correct .xlsx extension
        hpi_tempFile <- tempfile(fileext = ".xlsx")
        #download the file
        GET(hpiCountyLink, write_disk(hpi_tempFile, overwrite = TRUE))
        #read the excel file, skipping the first 5 rows and preserving column names
        hpi_df <- read_excel(hpi_tempFile, skip = 5, .name_repair = "minimal")
        
        #merge hpi information
        cps_df <- cps_df %>%
          #convert cps county column to appropriate format for merge
          mutate(county=case_when(nchar(county)==4~paste0(0,county), #truncated fips codes...without leading zeros
                                  .default=as.character(county))) %>%
          merge(y=hpi_df,by.x=c('year','county'),by.y=c('Year','FIPS code'),all.x=TRUE) %>%
          rename('county_name'='County',
                 'state_code'='State',
                 'hpi_annual_pct_change'='Annual Change (%)',
                 'hpi_index'='HPI',
                 'hpi1990_index'='HPI with 1990 base',
                 'hpi2000_index'='HPI with 2000 base')
      }
      
      #return entrepreneurship df
      return(cps_df)
    },
    
    #entrepreneurship df from existing data (no re-import)
    entrepreneurship.df.from.existing = function(existing_df, ind1990Link='character',hpiCountyLink='character'){
      #use existing data instead of importing
      cps_df <- existing_df
      
      #required cps variables
      entrepreneurship.cols <- c('race','hispan','nchild','sex',
                                 'educ','ind1990','age','statefip',
                                 'county','individcc','classwkr','mish') 
      
      #base file column check
      if(mean(entrepreneurship.cols %in% colnames(cps_df)) != 1){
        return('valid cps variables (voi) required...entrepreneurship.df method expects the variables: race, hispan, nchild, sex, educ, ind1990, age, statefip, county, individcc, classwkr, & mish')
      }
      
      #engineer race variable - using consistent approach from df_wk.Rmd
      cps_df <- 
        cps_df %>%
        mutate(
          # Create race_hispan more safely
          race_hispan = case_when(
            hispan == 0 ~ as.character(paste0(race, "000")),
            TRUE ~ as.character(paste0(race, hispan))
          ),
          # Convert to numeric safely, handling any conversion issues
          race_hispan_num = suppressWarnings(as.numeric(race_hispan)),
          # Create race factor based on the numeric version
          race = as.factor(case_when(
            race_hispan_num == 100000 ~ 'White Non-Hispanic',
            race_hispan_num == 200000 ~ 'Black Non-Hispanic',
            str_detect(as.character(race_hispan_num), "^6\\d*000$") ~ 'Asian & Pacific Islander Non-Hispanic',
            race_hispan_num == 300000 ~ 'American Indian Non-Hispanic',
            race_hispan_num == 700000 ~ 'Other Non-Hispanic',
            str_detect(as.character(race_hispan_num), "^8\\d*000$") ~ 'Multi-racial Non-Hispanic',
            race != 999 & hispan != 0 ~ 'Hispanic',
            TRUE ~ 'Unknown/Missing'  # Catch any remaining cases
          ))
        )
      
      #html setup for industry codes
      suppressWarnings({
        read_html(ind1990Link) %>%
          html_element('head') %>%
          html_elements('script') -> html_list
        html_list[4] %>% html_text() -> html_string
        pattern <- 'categories:\\s*(.*?)\\\n      longSamplesHeader:'
        filtered_html_string <- regmatches(html_string,regexec(pattern,html_string))[[1]][2] 
        filtered_html_string %>% 
          str_split('\\},\\{') -> ind_code_list
        ind_code_list <- ind_code_list[[1]]
        
        ind_code_df <- data.frame(); category_id <- 0
        for(code in 1:length(ind_code_list)){
          str_split(ind_code_list[code],',')[[1]] %>%
            str_split(':') -> temp_html
          string_df <- data.frame(row_count=c(1,2))
          for(temp_string in temp_html){
            if(length(temp_string) > 2){
              temp_string <- temp_string[1:2]}
            temp_string_df <- as.data.frame(temp_string)
            colnames(temp_string_df) <- temp_string_df[1,]
            if(nrow(temp_string_df)==2){
              string_df <- cbind(string_df,temp_string_df)
              string_df <- string_df[-1,]}}
          string_df <- 
            string_df %>% 
            dplyr::select(-c(row_count)) %>%
            lapply(gsub, pattern = '"', replacement = '') %>%
            as.data.frame()
          colnames(string_df) <- gsub('X.','',colnames(string_df))
          colnames(string_df)[1] <- 'id.'
          ind_code_df <- rbind(ind_code_df,string_df %>% dplyr::select('id.','label.','indent.','code.','general.'))
        }
      })
      
      #extract industries
      header_ind_code_df <- 
        ind_code_df %>%
        dplyr::select(-c(general.,id.)) %>%
        mutate(`indent.` = case_when((`indent.` == 0 & code. == 'null') | 
                                       (indent.== 0 & label.=='NIU') |
                                       (indent.== 0 & label.=='Unknown') ~ 1,
                                     .default = 0),
               ind_category = cumsum(`indent.`),
               naics_code = case_when(ind_category == 1 | ind_category == 16 ~ 0,
                                      ind_category == 2 ~ 11,
                                      ind_category == 3 ~ 21,
                                      ind_category == 4 ~ 23,
                                      ind_category == 5 ~ 31,
                                      ind_category == 6 ~ 48,
                                      ind_category == 7 ~ 42,
                                      ind_category == 8 ~ 44,
                                      ind_category == 9 ~ 52,
                                      ind_category == 10 ~ 56,
                                      ind_category == 11 ~ 0,
                                      ind_category == 12 ~ 71,
                                      ind_category == 13 ~ 54,
                                      ind_category == 14 ~ 92,
                                      ind_category == 15 ~ 0,
                                      .default = 0)) %>%
        filter((indent.==1 & label.!='NIU')|(indent.==1 & label.=='NIU')) %>%
        rename(ind1990 = code.) %>%
        mutate(label. = case_when(label. == 'TRANSPORTATION' ~ 'TRANSPORTATION, COMMUNICATIONS, AND OTHER PUBLIC UTILITIES',
                                  label. == 'FINANCE' ~ 'FINANCE, INSURANCE, AND REAL ESTATE',
                                  .default = label.)) 
      
      #extract industry sub sectors
      body_ind_code_df <-
        ind_code_df %>%
        dplyr::select(-c(general.,id.)) %>%
        mutate(`indent.` = case_when((`indent.` == 0 & code. == 'null') | 
                                       (indent.== 0 & label.=='NIU') |
                                       (indent.== 0 & label.=='Unknown') ~ 1,
                                     .default = 0),
               ind_category = cumsum(`indent.`),
               naics_code = case_when(ind_category == 1 | ind_category == 16 ~ 0,
                                      ind_category == 2 ~ 11,
                                      ind_category == 3 ~ 21,
                                      ind_category == 4 ~ 23,
                                      ind_category == 5 ~ 31,
                                      ind_category == 6 ~ 48,
                                      ind_category == 7 ~ 42,
                                      ind_category == 8 ~ 44,
                                      ind_category == 9 ~ 52,
                                      ind_category == 10 ~ 56,
                                      ind_category == 11 ~ 0,
                                      ind_category == 12 ~ 71,
                                      ind_category == 13 ~ 54,
                                      ind_category == 14 ~ 92,
                                      ind_category == 15 ~ 0,
                                      .default = 0)) %>%
        filter((indent.==0 & label.!='NIU')|(indent.==1 & label.=='NIU')) %>%
        rename(ind1990 = code.) 
      
      #extract sub sector information
      body_ind_code_df %>%
        mutate(
          naics_code = case_when(str_detect(as.character(ind1990),"^(44|800|852|732)\\d*") ~ 51,
                                 str_detect(as.character(ind1990),"^(45|47)\\d*") ~ 22,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('712','742') ~ 53,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('842','850','851','860') ~ 61,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('812','820','821','822','830','831',
                                                '832','840','861','862','863','870','871') ~ 62,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('762','770','641') ~ 72,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('761','771','772','780','781','782',
                                                '790','791','881','750','751','752',
                                                '760','880','873') ~ 81,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('722','741','740','731','471') ~ 56,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('872') ~ 71,
                                 .default = naics_code),
          naics_code = case_when(ind1990 %in% c('721') ~ 54,
                                 .default = naics_code),
          ind = case_when(naics_code == 11 ~ 'Agriculture, Forestry, Fishing and Hunting',
                          naics_code == 21 ~ 'Mining, Quarrying, and Oil and Gas Extraction',
                          naics_code == 22 ~ 'Utilities',
                          naics_code == 23 ~ 'Construction',
                          naics_code == 31 ~ 'Manufacturing',
                          naics_code == 42 ~ 'Wholesale Trade',
                          naics_code == 44 ~ 'Retail Trade',
                          naics_code == 48 ~ 'Transportation and Warehousing',
                          naics_code == 51 ~ 'Information',
                          naics_code == 52 ~ 'Finance and Insurance',
                          naics_code == 53 ~ 'Real Estate and Rental and Leasing',
                          naics_code == 54 ~ 'Professional, Scientific, and Technical Services',
                          naics_code == 56 ~ 'Administrative and Support and Waste Management and Remediation Services',
                          naics_code == 61 ~ 'Educational Services',
                          naics_code == 62 ~ 'Health Care and Social Assistance',
                          naics_code == 71 ~ 'Arts, Entertainment, and Recreation',
                          naics_code == 72 ~ 'Accommodation and Food Services',
                          naics_code == 81 ~ 'Other Services (except Public Administration)',
                          naics_code == 92 ~ 'Public Administration (not covered in economic census)',
                          .default = 'NIU')) %>%
        filter(ind1990!='null') %>%
        rename(subsector = label., ind_naics_code = naics_code) %>%
        group_by(ind_naics_code,ind1990,ind,subsector) %>%
        reframe(ind_naics_code,ind1990,ind,subsector) -> naics_code_df
      
      #include industry information to cps data
      cps_df <- merge(cps_df %>% mutate(ind1990 = as.character(ind1990)),naics_code_df,by='ind1990')
      
      #engineer educational attainment variable
      cps_df <-
        cps_df %>%
        mutate(educ = as.numeric(educ),
               educ = as.factor(case_when(educ <= 72 ~ 'a', #less than high school
                                          educ == 73 ~ 'b', #high school
                                          educ %in% c(81,100,121,122) ~ 'c', #some college
                                          educ %in% c(91,92,111) ~ 'd', #college degree
                                          educ %in% c(123,124,125) ~ 'e', #graduate degree
                                          .default = '0')))
      
      # Use data.table for robust entrepreneurship variable calculation
      setDT(cps_df)
      
      # Create lagged variables by individual (cpsidp)
      cps_df[, `:=`(
        prev_classwkr = shift(classwkr, 4, type = "lag"),
        prev_mish = shift(mish, 4, type = "lag")
      ), by = cpsidp]
      
      # entrepreneurship1: Transition to unincorporated or incorporated self-employment (classwkr 13 or 14)
      cps_df[, entrepreneurship1 := as.integer(
        !is.na(prev_classwkr) &
          !is.na(prev_mish) &
          mish >= 5 &
          prev_mish == (mish - 4) &
          !(prev_classwkr %in% c(13, 14)) &  # Not previously self-employed
          classwkr %in% c(13, 14)            # Now self-employed
      )]
      
      # entrepreneurship2: Transition to incorporated self-employment (classwkr 14)
      cps_df[, entrepreneurship2 := as.integer(
        !is.na(prev_classwkr) &
          !is.na(prev_mish) &
          mish >= 5 &
          prev_mish == (mish - 4) &
          !(prev_classwkr %in% c(14)) &      # Not previously incorporated
          classwkr == 14                     # Now incorporated
      )]
      
      #include hpi information
      if(!missing(hpiCountyLink) && hpiCountyLink != 'character'){
        # Check if it's a local file or URL
        if(file.exists(hpiCountyLink)) {
          # Local file - read directly
          hpi_df <- read_excel(hpiCountyLink, skip = 5, .name_repair = "minimal")
        } else {
          # URL - try to download
          tryCatch({
            hpi_tempFile <- tempfile(fileext = ".xlsx")
            GET(hpiCountyLink, write_disk(hpi_tempFile, overwrite = TRUE))
            hpi_df <- read_excel(hpi_tempFile, skip = 5, .name_repair = "minimal")
          }, error = function(e) {
            warning("Could not download HPI data from URL. Please use a local file.")
            return(cps_df)  # Return without HPI data
          })
          
        
        #merge hpi information
        cps_df <- cps_df %>%
          #convert cps county column to appropriate format for merge
          mutate(county=case_when(nchar(county)==4~paste0(0,county), #truncated fips codes...without leading zeros
                                  .default=as.character(county))) %>%
          merge(y=hpi_df,by.x=c('year','county'),by.y=c('Year','FIPS code'),all.x=TRUE) %>%
          rename('county_name'='County',
                 'state_code'='State',
                 'hpi_annual_pct_change'='Annual Change (%)',
                 'hpi_index'='HPI',
                 'hpi1990_index'='HPI with 1990 base',
                 'hpi2000_index'='HPI with 2000 base')
      }
      
      #return entrepreneurship df
      return(cps_df)
    }
  ))