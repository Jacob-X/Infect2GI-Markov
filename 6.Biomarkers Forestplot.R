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
    ungroup() # 排序完先解开，下面重新分组计算位置
  
  # 🚀 修改开始：让标签显示在每一组的“中间行”，实现垂直居中效果
  df_c <- df_c %>%
    group_by(transition_to_cancer) %>%
    mutate(
      # 计算当前组有多少行
      n_rows = n(),
      # 生成行号 (1, 2, 3...)
      row_idx = row_number(),
      # 计算中间行的位置 (向上取整，例如3行就在第2行，2行就在第1行)
      middle_idx = ceiling(n_rows / 2),
      
      # 只有当当前行是中间行时，才显示文字，否则为空
      transition_to_cancer_display = ifelse(
        row_idx == middle_idx, 
        transition_to_cancer, 
        ""
      )
    ) %>%
    ungroup()
  # 🚀 修改结束
  # -------------------------------------------------------------------
  # 🚀 修改部分开始：构造 labeltext 列表而非矩阵，以支持特殊格式
  # -------------------------------------------------------------------
  
  # 第1列：居中 + 粗体 (Header + Body)
  col1 <- c("Transition to Cancer (probability)", df_c$transition_to_cancer_display)
  
  # 第2列：修改名称 Name of second column --> Clinical Biomarker
  col2 <- c("Clinical Biomarker", df_c$Biomarkers)
  
  # 第3列
  col3 <- c("r (95% CI)", df_c$`r(95%CI)`)
  
  # 第4列：P-value --> small italicized p-value
  # 使用 list 混合 expression 和 string
  p_val_header <- expression(bolditalic("p") * bold("-value"))
  p_val_body   <- sprintf("%.4f", df_c$`P-value`)
  col4 <- c(list(p_val_header), as.list(p_val_body))
  
  # 将4列组合成一个 list 传给 forestplot (对应4列)
  label_list <- list(col1, col2, col3, col4)
  
  # -------------------------------------------------------------------
  # 🚀 修改部分结束
  # -------------------------------------------------------------------
  
  # 表头行标识
  total_rows <- length(col1)
  is_summary <- c(TRUE, rep(FALSE, total_rows - 1))
  
  # ✅ 绘制分组间的虚线
  group_rows <- split(2:total_rows, df_c$transition_to_cancer)
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
    labeltext   = label_list,  # 使用列表
    mean        = c(NA, df_c$r),
    lower       = c(NA, df_c$lower),
    upper       = c(NA, df_c$upper),
    is.summary  = is_summary,
    lineheight  = unit(6, "mm"),
    hrzl_lines  = hrzl_lines,
    zero        = 0,
    xlab        = "Rank-Biserial Correlation (r, 95% CI)",
    xlim        = c(-1, 1),
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
    
    # 🚀 修改部分：设置对齐方式
    # "c" = Center (第1列), "l" = Left (第2,3,4列)
    align       = c("c", "c", "c", "c"),
    
    colgap      = unit(4, "mm"), # 稍微增加一点列间距
    hjust       = 0,
    
    # 🚀 修改部分：精细控制字体样式
    txt_gp      = fpTxtGp(
      # label 控制数据行（非表头）的样式
      # 使用 list 对应每一列：
      # 第1列: bold, 第2-4列: plain
      label   = list(
        gpar(cex = 0.85, fontface = "bold"), 
        gpar(cex = 0.85), 
        gpar(cex = 0.85), 
        gpar(cex = 0.85)
      ),
      # summary 控制表头行的样式
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