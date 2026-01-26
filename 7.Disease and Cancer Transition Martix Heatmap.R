library(tidyverse)
library(readxl)
library(scales)
library(cowplot) 
library(grid)    

file_path <- "/Volumes/data_files/markov_codes/dates/s3_tp.xlsx"


output_heatmap_pdf <- "/Volumes/data_files/markov_codes/dates/disease_transition_bubble_heatmaps_no_legend.pdf"

output_legend_pdf <- "/Volumes/data_files/markov_codes/dates/disease_transition_legend_only.pdf"


sheet_names <- excel_sheets(file_path)
print(sheet_names)

global_max_prob <- 0

pdf(output_heatmap_pdf, width = 15, height = 12)

for(sheet_name in sheet_names){

  df <- read_excel(file_path, sheet = sheet_name)
  df <- df %>% rename(Disease = 1)
  

  df_infection <- df %>% filter(!str_detect(Disease, regex("Cancer", ignore_case = TRUE)))
  
  mat_long <- df_infection %>%
    pivot_longer(cols = -Disease, names_to = "To", values_to = "prob") %>%
    rename(From = Disease)

  current_max <- max(mat_long$prob, na.rm = TRUE)

  if(current_max > global_max_prob) {
    global_max_prob <- current_max
  }
  

  p <- ggplot(mat_long, aes(x = To, y = From)) +
    geom_point(aes(size = prob, fill = prob), shape = 21, color = "black") +
    
    scale_fill_gradient(low = "white", high = "#ef8a62",
                        name = "Transition probability",
                        limits = c(0, current_max), 
                        oob = scales::squish,
                        guide = "legend") +
    
    scale_size(range = c(1, 8), 
               name = "Transition probability") +
    
    theme_minimal(base_size = 12) +
    theme(
      axis.text.x = element_text(angle = 45,size = 14, hjust = 1),
      axis.text.y = element_text(size = 14),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      legend.position = "none" 
    )

  
  print(p)
}

dev.off() 

print("热图 PDF 生成完毕。正在生成图例 PDF...")



dummy_data <- data.frame(To = 1, From = 1, prob = c(0, global_max_prob))

p_legend_base <- ggplot(dummy_data, aes(x = To, y = From)) +
  geom_point(aes(size = prob, fill = prob), shape = 21, color = "black") +
  scale_fill_gradient(low = "white", high = "#ef8a62",
                      name = "Transition probability",
                      limits = c(0, global_max_prob), 
                      oob = scales::squish,
                      guide = "legend") +
  scale_size(range = c(1, 8), 
             name = "Transition probability",
             limits = c(0, global_max_prob)) + 
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 16),
    legend.key.height = unit(1, "cm")
  )


legend_object <- get_legend(p_legend_base)

pdf(output_legend_pdf, width = 4, height = 6) 
grid.newpage()
grid.draw(legend_object)
dev.off()

print(paste0("finished, save to: ", output_legend_pdf))