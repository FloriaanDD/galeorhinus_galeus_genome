# FIGURE 2 - REPEAT CONTENT #

# Load libraries
library(tidyverse) 
library(readxl) 
library(here) 
library(ggsci) 
library(reticulate)
library(MetBrewer)

df <- read.table("repmask_stats.250527.tsv", header = T)

# Create new ID column combining OG ID and haplotype
df$ID <- paste(df$OG_id, df$haplotype, sep = "_")

# ---- MAJOR TE GROUPS ----
df_major <- df %>%
  select(ID, SINEs_pc, LINEs_pc, DNA_transposons_pc, LTR_elements_pc, Rolling.circles_pc, Unclassified_pc,
         Small_RNA_pc, Satellites_pc, Simple_repeats_pc, Low_complexity_pc) %>%
  arrange(ID) %>%
  pivot_longer(cols = -ID, names_to = "repeat_type", values_to = "percentage")

# option to plot only those representing >0.5% of the genome
df_major <- df %>%
  select(ID, SINEs_pc, LINEs_pc, DNA_transposons_pc, LTR_elements_pc, Unclassified_pc,
         Small_RNA_pc, Simple_repeats_pc, Low_complexity_pc) %>%
  arrange(ID) %>%
  pivot_longer(cols = -ID, names_to = "repeat_type", values_to = "percentage")

# create the plot
ggplot(df_major, aes(x = ID, y = percentage, fill = repeat_type)) +
  geom_bar(stat = "identity") +
  labs(x = "ID", y = "Percentage", title = "Stacked Bar Plot of Major Repeat Types") +
  scale_fill_manual(values = RdBu) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))