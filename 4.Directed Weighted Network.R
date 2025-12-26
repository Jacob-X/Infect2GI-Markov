library(readr)
library(ggraph)
library(tidygraph)
library(dplyr)
library(readxl)
library(tidyr)
library(ggplot2)

# =========================================================
# 1. 设置文件路径与输出路径
# =========================================================
# input_dir <- "/Volumes/data_files/markov_codes/dates/"
input_dir <- "/Volumes/data_files/markov_codes/dates/transition_probility_datas"
output_dir <- file.path(input_dir, "plots_pdf")
if (!dir.exists(output_dir)) dir.create(output_dir)

# =========================================================
# 2. 获取所有 *_trans.xlsx 文件（排除临时和补充文件）
# =========================================================
files <- list.files(input_dir, pattern = "_trans\\.xlsx$", full.names = TRUE)
files <- files[!grepl("~\\$|Supplementary", files)]

# =========================================================
# 3. 遍历每个癌症类型
# =========================================================
for (f in files) {
  if (grepl("multi_trans", f)) next
  
  # 提取癌症名称（去掉 _trans.xlsx）
  cancer_name <- gsub("_trans\\.xlsx$", "", basename(f))
  message("Processing: ", cancer_name)
  
  # 转换为带空格的形式，用于匹配 Excel 里的名称
  cancer_display_name <- gsub("_", " ", cancer_name)
  
  # 匹配 multi 文件
  multi_file <- file.path(input_dir, paste0(cancer_name, "_multi_trans.xlsx"))
  if (!file.exists(multi_file)) {
    warning("No matching multi_trans file found for ", cancer_name)
    next
  }
  
  # =========================================================
  # 4. 读取 direct 与 multi 数据
  # =========================================================
  direct_data <- read_excel(f)
  direct_data <- direct_data %>%
    separate(`transitions 1`, into = c("Source", "Target"), sep = "\\s*→\\s*") %>%
    select(Source, Target, `Transition probability`)
  
  multi_data <- read_excel(multi_file)
  multi_data <- multi_data %>%
    separate(`transitions 1`, into = c("Transition_1", "Transition_2"), sep = "\\s*→\\s*", extra = "merge") %>%
    separate(`transitions 2`, into = c("dummy", "Cancer"), sep = "\\s*→\\s*", extra = "merge", fill = "right") %>%
    select(
      Transition_1,
      Transition_2,
      Cancer,
      Transition_probability_1 = `Transition_probability_1`,
      Transition_probability_2 = `Transition_probability_2`
    )
  
  # =========================================================
  # 5. 拆分 multi 数据并合并
  # =========================================================
  multi_part1 <- multi_data %>%
    select(Source = Transition_1,
           Target = Transition_2,
           `Transition probability` = Transition_probability_1)
  
  multi_part2 <- multi_data %>%
    select(Source = Transition_2,
           Target = Cancer,
           `Transition probability` = Transition_probability_2)
  
  combined_data <- bind_rows(direct_data, multi_part1, multi_part2)
  
  # =========================================================
  # 6. 构建网络图
  # =========================================================
  graph <- as_tbl_graph(combined_data, directed = TRUE)
  
  # =========================================================
  # 7. 绘制图形
  # =========================================================
  set.seed(333)
  if (cancer_display_name == "Colorectal Cancer") {
    target_nodes <- c("Cellulitis", "Spirochetal Infection", "Fungal Infection", "Parasitic Infection","Helicobacter Pylori Infection","Hepatitis A")
  } else if (cancer_display_name == "Gastric Cancer") {
    target_nodes <- c("Hepatitis B", "Spirochetal Infection", "Gastrointestinal Infection", "Parasitic Infection","Helicobacter Pylori Infection","Hepatitis A")
  } else if (cancer_display_name == "Pancreatic Cancer") {
    target_nodes <- c("General Bacterial Infection", "Escherichia Coli Infection", "Hepatitis A", "Other Viral Hepatitis","Parasitic Infection","Helicobacter Pylori Infection","Hepatitis A")
  } else if (cancer_display_name == "Liver Cancer") {
    target_nodes <- c("Escherichia Coli Infection", "UTI","Parasitic Infection","Helicobacter Pylori Infection","Hepatitis A")
  } else if (cancer_display_name == "Esophageal Cancer") {
    target_nodes <- c("Protozoan Infection", "Fungal Infection","Parasitic Infection","Helicobacter Pylori Infection","Hepatitis A")
  } else {
    target_nodes <- c() # 默认空集
  }
  
  
  p <- ggraph(graph, layout = "fr", niter = 2000, area = 10^6) + 
    geom_edge_link(aes(width = `Transition probability`,
                       color = `Transition probability`),
                   arrow = arrow(length = unit(8, 'mm')),
                   end_cap = circle(6, 'mm')) + 
    geom_node_point(aes(fill = name),
                    size = 8, 
                    shape = 21,
                    color = "black",
                    stroke = 0.1,
                    show.legend = FALSE) +
    scale_fill_manual(
      values = setNames("#e57373", cancer_display_name),  # ✅ 匹配带空格名称
      na.value = "#BEB8DC"
    ) +
    geom_node_text(aes(label = name,
                      
                      # 1. 字体粗细
                      fontface = ifelse(name %in% target_nodes | name == cancer_display_name, "bold", "plain"),
                      
                      # 2. 字体大小 (标红的稍微大一点点，设为5)
                      size = ifelse(name == cancer_display_name, 6, 
                                    ifelse(name %in% target_nodes, 5, 4.5)),
                      
                      # 3. 字体颜色
                      color = ifelse(name %in% target_nodes, "#B95955", "black")
                      
    ), repel = TRUE, max.overlaps = 30) +
    scale_size_identity() +
    scale_color_identity()+
    theme_void() +
    scale_edge_width(range = c(0.5, 2.5), 
                     breaks = c(0.10, 0.30, 0.50),
                     labels = c("0.10", "0.30", "0.50")) + 
    scale_edge_color_gradient(low = "#deebf7", high = "#99ccff", name = "Transition probability") +
    guides(edge_alpha = "none", edge_width = "none") +
    theme(
      legend.position = "right",
      legend.direction = "vertical",
      legend.title = element_text(angle = 90, hjust = 0.5, vjust = 0.5, size = 12), 
      legend.text = element_text(size = 10),
      plot.title = element_blank()   # ✅ 去掉左上角标题
    ) +
    ggtitle(cancer_display_name)
  
  # =========================================================
  # 8. 保存为 PDF
  # =========================================================
  out_file <- file.path(output_dir, paste0(cancer_name, "_network.pdf"))
  ggsave(out_file, p, width = 8, height = 8, dpi = 300)
  
  message("✅ Saved PDF: ", out_file)
}

message("🎉 所有癌症类型的 PDF 网络图已生成！")