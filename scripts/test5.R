url <- "https://p3m.dev/cran/2023-10-30"
con <- url(url)
t0 <- Sys.time()
res <- try(readLines(con, n = 10), silent = TRUE)
t1 <- Sys.time()
close(con)

print(res)
print(t1 - t0)