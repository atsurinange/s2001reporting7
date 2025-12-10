#!/usr/bin/env Rscript
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#Reading sas7bdat, searching and generate csv file
#!/usr/bin/env Rscript
# 入力: <input.sas7bdat> <column> <value> <output_xpt>
# 出力: <output_base>.xpt（中間ファイル）
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

### Initialize Script Information ###
current_script_name <- "filter_sas_to_xpt.R"
#actual_executor <- "Kitagawa, Atsushi:B06823"

### Using Logger: Initialize ###
if (!exists(".app_logger_initialized", inherits=TRUE)) {
  try(.local_init_app_logger(), silent=TRUE)
}
################################

uid <- current_user_id()
sid <- current_session_id()

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4) {
  #cat("Usage: Rscript filter_sas_to_xpt.R <input.sas7bdat> <column> <value> <output.xpt>\n")
  #  quit(status=1)
  message("Usage: Rscript filter_sas_to_xpt.R <input.sas7bdat> <column> <value> <output_xpt> <run_user>")
  
  ### Using Logger: Argument error ###
  log_error("Invalid arguments", action="arg_parse", expected="input,column,value,output", got=args)
  ####################################
  quit(status=1)
}

in_path <- args[1]; col <- args[2]; val <- args[3]; out_xpt <- args[4]; actual_executor <- args[5]
#in_path <- "/studies/STD0001/s1reporting1_beatrice/01_input/ae.sas7bdat"
#col <- "AETERM"
#val <- "発熱"
#out_xpt <- "/studies/STD0001/s1reporting1_beatrice/02_output/fever.xpt"
#actual_executor <- "Kitagawa, Atsushi:B06823"

### Using Logger: Start ###
log_info("Script starts!!", action="script_start", user_id=uid, session_id=sid)
###########################


### Using Logger: Arguments information ###
log_info("Arguments detail", action="arg_parse", input=in_path, column=col, searchValue=val, output=out_xpt, run_user=actual_executor)
###########################################

req_pkgs <- c("haven", "dplyr")
missing <- req_pkgs[!req_pkgs %in% installed.packages()[, "Package"]]
if (length(missing) > 0) install.packages(missing, repos = "https://cloud.r-project.org")
#install.packages(c("haven","dplyr","readr"))

suppressPackageStartupMessages({ library(haven); library(dplyr) })


#stopifnot(file.exists(in_path))
if(!file.exists(in_path)) {
  message("Caution: Input file does not exist")
  
  ### Using Logger: Argument error ###
  log_error("Input not found", action="input_check", expected="Input must exist as an actual file", input=in_path)
  ####################################
  
  quit(status=2,save="no")
}


### Using Logger: Hash info for input file ###
in_hash <- hash_file(in_path, "sha256")
log_info("Confirm input file", action="input_verify", path=in_path, sha256=in_hash)
##############################################

start1 <- Sys.time()

df <- read_sas(in_path)

# 文字列列を Shift_JIS とみなして UTF-8 に変換
# iconv で変換できない文字は NA にする（sub=""で除去することも可）
#df <- df %>%
#  mutate(across(
#    where(is.character),
#    ~ iconv(.x, from = "CP932", to = "UTF-8", sub = NA)
#  ))

#if (!col %in% names(df)) stop(sprintf("Column %s not found.", col))
if (!col %in% names(df)) {
  #stop(sprintf("Column %s not found.", col))
  message(sprintf("Caution: Column %s not found.", col))
  
  ### Using Logger: Argument error ###
  log_error("Invalid column", action="column_check", msgtext="Designated column not found", column=col)
  ####################################
  
  quit(status=3,save="no")
} 

trim_ws <- function(x) if (is.character(x)) trimws(x) else x
df <- df %>% mutate(across(where(is.character), trimws))
filtered <- dplyr::filter(df, .data[[col]] == val)
#filtered <- df

dir.create(dirname(out_xpt), showWarnings = FALSE, recursive = TRUE)
write_xpt(filtered, out_xpt, version = 8)  # v5/v8選択可
cat("Wrote XPT: ", out_xpt, "\n")

elapsed1_ms <- as.integer(difftime(Sys.time(), start1, units="secs")*1000)

if(!file.exists(out_xpt)) {
  message("Caution: Output file does not exist")
  
  ### Using Logger: Argument error ###
  log_error("Output not found", action="output_check", expected="Output must be generated as an actual csv file", output=out_xpt)
  ####################################
  
  quit(status=2,save="no")
}

### Using Logger: output hash ###
out_hash <- hash_file(out_xpt, "sha256")
log_info("Output completed", action="output_generate", path=out_xpt, 
         duration_ms=elapsed1_ms, sha256=out_hash, format="xpt")
#################################

### Using Logger: End ###
log_info("Script ends", action="script_end", user_id=uid, session_id=sid)
#########################
