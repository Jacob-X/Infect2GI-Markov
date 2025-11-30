library(tidyverse)
library(readxl)
library(scales)

# 文件路径
file_path <- "/Volumes/data_files/markov_codes/dates/s3_tp.xlsx"

# 输出 PDF 文件路径
output_pdf <- "/Volumes/data_files/markov_codes/dates/disease_transition_bubble_heatmaps.pdf"

# 获取所有 sheet 名称
sheet_names <- excel_sheets(file_path)
print(sheet_names)

# 打开 PDF 保存
pdf(output_pdf, width = 12, height = 10)

for(sheet_name in sheet_names){
  
  # 读取数据
  df <- read_excel(file_path, sheet = sheet_name)
  df <- df %>% rename(Disease = 1)
  
  # 找到 Cancer 列
  cancer_cols <- colnames(df)[str_detect(colnames(df), regex("Cancer", ignore_case = TRUE))]
  
  # 去掉 Cancer 行，但保留 Cancer 列
  df_infection <- df %>% filter(!str_detect(Disease, regex("Cancer", ignore_case = TRUE)))
  
  # 提取 Cancer 列
  cancer_data <- df_infection %>% select(all_of(cancer_cols))
 
  # 转为 long 格式
  mat_long <- df_infection %>%
    pivot_longer(cols = -Disease, names_to = "To", values_to = "prob") %>%
    rename(From = Disease)
  
  # 绘制气泡热力图
  p <- ggplot(mat_long, aes(x = To, y = From)) +
    geom_point(aes(size = prob, fill = prob), shape = 21, color = "black") +
    scale_fill_gradient(low = "white", high = "#ef8a62",
                        name = "Transition probability",
                        limits = c(0, max(mat_long$prob)),
                        oob = scales::squish) +
    scale_size(range = c(1, 8), name = "Transition probability") +
    theme_minimal(base_size = 12) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.text.y = element_text(size = 10),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
    )
  
  print(p)
}

dev.off()
