## hatena2.R
args <- commandArgs(trailingOnly=TRUE)  #引数受け取り  
a <- as.integer(args[1])  #数値に変換  
b <- as.integer(args[2])   
c <- sqrt(a + b)    
print(c)
