library(readxl)
library(dplyr)
library(stringr)
library(forestplot)
library(grid)

# 1️⃣ 读取数据
df <- read_excel("/Volumes/data_files/markov_codes/dates/formated_p_table.xlsx")

# 2️⃣ 解析 r(95%CI) 函数
parse_r_ci <- function(value) {
  m <- str_match(value, "([-.0-9]+) \\(([-.0-9]+) to ([-.0-9]+)\\)")
  if (is.na(m[1])) return(c(NA, NA, NA))
  as.numeric(m[2:4])
}

# 3️⃣ 获取所有癌症类型
cancer_types <- unique(df$`Cancer type`)

# 4️⃣ 设置输出路径
output_dir <- "/Volumes/data_files/markov_codes/dates/"

# 5️⃣ 循环绘制并保存
for (cancer in cancer_types) {
  cat("Processing:", cancer, "\n")
  
  # 筛选当前癌症类型数据
  df_c <- df %>%
    filter(`Cancer type` == cancer) %>%
    select(`transition_path_1`,
           `transition_path_2`,
           Biomarkers,
           `r(95%CI)`,
           `P-value`,
           `Transition probability`)
  
  # 构造 transition_to_cancer
  df_c <- df_c %>%
    mutate(
      transition_to_cancer = ifelse(
        is.na(`transition_path_2`) | `transition_path_2` == "",
        paste0(`transition_path_1`, " → ", cancer, " (",
               round(`Transition probability` * 100, 1), "%)"),
        paste0(`transition_path_1`, " → ", `transition_path_2`,
               " → ", cancer, " (",
               round(`Transition probability` * 100, 1), "%)")
      )
    )
  
  # 解析 r, lower, upper
  r_ci <- t(sapply(df_c$`r(95%CI)`, parse_r_ci))
  df_c <- df_c %>%
    mutate(
      r     = r_ci[, 1],
      lower = r_ci[, 2],
      upper = r_ci[, 3]
    )
  
  # ✅ 关键：按 transition_to_cancer 组内 r 从大到小排序
  df_c <- df_c %>%
    group_by(transition_to_cancer) %>%
    arrange(desc(r), .by_group = TRUE) %>%
    ungroup()
  
  # ✅ 让“Transition to Cancer”列只显示一次
  df_c <- df_c %>%
    mutate(
      transition_to_cancer_display = ifelse(
        duplicated(transition_to_cancer), "",
        transition_to_cancer
      )
    )
  
  # 构造 label 矩阵
  label_mat <- rbind(
    c("Transition to Cancer (probability)",
      "Biomarker",
      "r (95% CI)",
      "P-value"),
    cbind(
      df_c$transition_to_cancer_display,
      df_c$Biomarkers,
      df_c$`r(95%CI)`,
      sprintf("%.4f", df_c$`P-value`)
    )
  )
  
  # 表头行标识
  is_summary <- c(TRUE, rep(FALSE, nrow(df_c)))
  
  # ✅ 绘制分组间的虚线（每组最后一行）
  group_rows <- split(2:(nrow(label_mat)), df_c$transition_to_cancer)
  last_row_per_group <- sapply(group_rows, max)
  
  hrzl_lines <- list("2" = gpar(lwd = 2, col = "black"))
  for (row in last_row_per_group) {
    hrzl_lines[[as.character(row + 1)]] <-
      gpar(lwd = 1, col = "#2457ca", lty = "dashed")
  }
  
  # 输出文件路径
  file_name <- paste0(
    gsub("[^a-zA-Z0-9]", "_", cancer),
    "_forestplot.pdf"
  )
  file_path <- file.path(output_dir, file_name)
  
  # 打开PDF设备
  pdf(file = file_path, width = 13, height = 12)
  
  # 绘制森林图
  p <- forestplot(
    labeltext   = label_mat,
    mean        = c(NA, df_c$r),
    lower       = c(NA, df_c$lower),
    upper       = c(NA, df_c$upper),
    is.summary  = is_summary,
    lineheight  = unit(6, "mm"),
    hrzl_lines  = hrzl_lines,
    zero        = 0,
    xlab        = "Rank-Biserial Correlation (r, 95% CI)",
    xlim = c(-1, 1),
    col         = fpColors(
      box     = "#1E90FF",
      line    = "#4682B4",
      summary = "#87CEFA"
    ),
    boxsize     = 0.2,
    graph.pos   = 3,
    lwd.zero    = 2,
    lwd.ci      = 2,
    ci.vertices = TRUE,
    align       = c("l", "l", "l", "l"),
    colgap      = unit(2, "mm"),
    hjust       = 0,
    txt_gp      = fpTxtGp(
      label   = gpar(cex = 0.85),
      summary = gpar(cex = 1, fontface = "bold"),
      ticks   = gpar(cex = 0.9),
      xlab    = gpar(cex = 1.1),
      title   = gpar(cex = 1.5)
    )
  )
  
  print(p)
  dev.off()
  
  cat("✅ Saved to:", file_path, "\n\n")
}