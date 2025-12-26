install.packages("tidyr")
install.packages("tidyverse")
install.packages("markovchain")
library(tidyr)
library(tidyverse)
library(markovchain)

### Construct the Markov chain ###
###	1.	读取输入文件（每行可能是一个病人的疾病序列，例如 "Infection Cancer"）；
###	2.	把所有疾病状态序列提取出来；
###	3.	使用 markovchainFit() 拟合 马尔可夫链模型；
###	4.	得到疾病之间的 转移概率矩阵（transition matrix），

# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Set input and output file paths
# args[1] - Input file path
# args[2] - Output file path
input_file <- ifelse(length(args) >= 1, args[1], "test data mapping.txt")
output_file <- ifelse(length(args) >= 2, args[2], "Colorectal Cancer transitionMatrix.csv")

# Set the working directory.
setwd(dirname(input_file))

# Load the data.
SC_data <- read.csv(file = input_file, header = FALSE, fill = FALSE)

# Construct the Markov chain
data_colorectal <- SC_data %>%
  pull(V1) %>%
  strsplit(" ") %>%
  unlist()
fit_markov_colorectal <- markovchainFit(data_colorectal)

# Extract the transition matrix and save it to a CSV file.
data <- fit_markov_colorectal$estimate@transitionMatrix
write.csv(data, file = output_file)



### 1.	读取一个过滤过的转移概率文件（如 "0.05.csv"），
### 只保留 转移概率 > 0.05 的疾病对；
### 2.	使用 igraph 构建有向图（疾病 → 疾病）；
### 	3.	计算多种 中心性指标（centrality measures）：
### 	•	degree: 连接数量（疾病与多少疾病有直接关系）；
### 	•	betweenness: 疾病在进展路径中作为“桥梁”的程度；
### 	•	closeness: 疾病与其他疾病的距离（越短越“中心”）；
### 	•	eigen_centrality: 网络影响力（连接有影响力节点的节点也有高影响力）；
### 4.	输出所有疾病节点的中心性结果表



### Network graph analysis ###
install.packages("igraph")
library(igraph)
# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Set input and output file paths
input_file <- ifelse(length(args) >= 1, args[1], "0.05.csv") #The 0.05.csv file contains specific transition data selected from the transition matrix obtained in the previous step, including only transitions with probabilities greater than 0.05 that are related to cancer.
output_file <- ifelse(length(args) >= 2, args[2], "Colorectal_cancer_network_centrality_results_without_Prion.csv")

# Set the working directory dynamically based on input file directory
setwd(dirname(input_file))

# Read in the input file
GD_file <- read.csv(input_file, header = TRUE, stringsAsFactors = FALSE)
GD <- graph_from_data_frame(GD_file, directed = TRUE)

# Add edge weight as width
E(GD)$width <- E(GD)$weight

# Calculating node centrality, excluding self-loops, as they can affect the overall network centrality
de <- degree(GD, normalize = TRUE) # Vertex degree 
de_out <- degree(GD, mode = "out", normalize = TRUE) # Node out-degree
de_in <- degree(GD, mode = "in", normalized = TRUE) # Node in-degree
be <- betweenness(GD, normalized = TRUE) # Node Betweenness
cl <- closeness(GD, normalized = TRUE) # Node Closeness
cl_out <- closeness(GD, mode = "out", normalized = TRUE) # Node out-closeness
cl_in <- closeness(GD, mode = "in", normalized = TRUE) # Node in-closeness
ed <- eigen_centrality(GD) # Node Eigen-centrality
ed_sort <- sort(ed$vector, decreasing = TRUE) # Sort data in descending order

# Create a data frame with the centrality measures
GD_network <- data.frame(degree = de, 
                         degree_out = de_out, 
                         degree_in = de_in, 
                         betweenness = be, 
                         closeness = cl, 
                         closeness_out = cl_out, 
                         closeness_in = cl_in, 
                         eigen_centrality = ed$vector)

# Write the results to a CSV file
write.csv(GD_network, file = output_file)



  # 1.	用两个示例向量（x、y）模拟两组人（如癌症 vs 对照）的生化指标；
	# 2.	进行 Wilcoxon 秩和检验（非参数检验，类似于 Mann–Whitney U 检验）；
	# 3.	用 rank_biserial() 计算 效应量 (effect size)；
	# 4.	输出结果，用于衡量两组之间差异的方向和强度。
### Biochemical indicators Wilcoxon rank-sum test analysis ###
install.packages("effectsize")
library(effectsize)

x <- c(5.1, 7.3, 6.8, 8.0, 6.2) #For testing purposes only. For data requests, please contact the respective database administrator
y <- c(4.9, 5.5, 6.1, 5.7, 5.3) #For testing purposes only. For data requests, please contact the respective database administrator

result <- wilcox.test(x, y, exact = FALSE)
r_value <- rank_biserial(result)
print(r_value)

