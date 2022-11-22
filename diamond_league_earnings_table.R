library(tidyverse)
library(gt)
library(countrycode)


dl_points <- readRDS("/home/georgemperry/Documents/Athletics_Data/diamond_league_points_results.rds")
country_dict <- read_csv("/home/georgemperry/Documents/Athletics_Data/country_code_master.csv")

dl_points <- dl_points %>%
  left_join(., country_dict, by = c("Country" = "Diamond_League_Country")) %>%
  mutate(flag_emoji  = countrycode(ISO2Code, 'iso2c', 'unicode.symbol')) %>%
  select(Rank, Name, Event, Country, Gender, Moneez, Discipline, flag_emoji)


base_frame <- dl_points %>%
  group_by(Name, Event) %>%
  summarise(Earnings = sum(Moneez, na.rm=TRUE),
            across()) %>%
  select(Name, Event, Gender, Earnings, flag_emoji, Country) %>%
  unique() 



base_table <- base_frame %>%
  group_by(Event, Gender) %>%
  mutate(Rank = rank(-Earnings, ties.method = "random")) %>%
  filter(Rank <= 5) %>%
  group_by(Event, Gender, Rank) %>%
  select(-Name, -flag_emoji, -Country) %>%  
  pivot_wider(names_from = Rank, values_from = Earnings, names_prefix = "Rank_") %>%
  ungroup() %>%
  mutate(country_top = "",
         earnings_spread = Rank_1 - Rank_5,
         spacer = "") %>%
  relocate(country_top, .after = Gender) %>%
  gt() %>%
  data_color(.,
             columns = c(starts_with("Rank"), earnings_spread),
             colors = scales::col_numeric(
               palette = c("#fcffa4", "#fac228", "#f57d15", "#d44842", "#9f2a63", "#65156e", "#280b53", "#000004"),
               domain = c(min(base_frame$Earnings), max(base_frame$Earnings))) 
  ) %>%
  cols_label(
    country_top = "Top earning countries",
    Rank_1 = "Highest earner",
    Rank_2 = "2nd",
    Rank_3 = "3rd",
    Rank_4 = "4th",
    Rank_5 = "5th",
    earnings_spread = "Top 5 earnings spread",
    spacer = ""
  )


rank_to_html <- function(cell_info) {
  
  html_out <- glue::glue('<div style = "font-size: 16px;font-weight:600;">{unlist(cell_info)[1]}</div>
        <div style="line-height:18px;font-size: 16px;">{unlist(cell_info)[2]}</div>
        <div style="line-height:18px;font-size: 16px;">{unlist(cell_info)[3]}</div>')
  html_out <- map(html_out, gt::html)
  return(html_out)
}


athlete_info <-  base_frame %>%
  select(-Country) %>%    # If anything goes wrong, blame this line
  group_by(Event, Gender) %>%
  mutate(Rank = rank(-Earnings, ties.method = "random"),
         Earnings = scales::dollar(Earnings)) %>%
  filter(Rank <= 5) %>%
  nest(Name, flag_emoji, Earnings) %>%
  pivot_wider(names_from = Rank, values_from = data, names_prefix = "Rank_") %>%
  mutate(across(.cols = starts_with("Rank"), .fns = rank_to_html)) %>%
  ungroup() %>%
  gt()


emoji_to_html <- function(cell_info) {
  
  html_out <- glue::glue('<div style="font-size: 16px;float:left;">{unlist(cell_info)[1]}\t{unlist(cell_info)[2]}</div>')
  return(html_out)
}

country_earnings <- base_frame %>%
  group_by(Event, Gender, Country, flag_emoji) %>%
  summarise(Earnings = sum(Earnings, na.rm=TRUE)) %>%
  group_by(Event, Gender) %>%
  slice_max(order_by = Earnings, n = 3) %>%
  mutate(Earnings = scales::dollar(Earnings)) %>%
  nest(flag_emoji, Earnings) %>%
  select(-Country) %>%
  mutate(country_top = map(data, emoji_to_html)) %>%
  summarize(country_top = paste(country_top, collapse = "<br>")) %>%
  ungroup() %>%
  mutate(country_top = map(country_top, gt::html)) %>%
  gt()



athlete_info_data <- athlete_info$`_data`
country_earnings_data <- country_earnings$`_data`

base_table$`_data` <- base_table$`_data` %>%
  select(Event, Gender, earnings_spread, spacer) %>%
  left_join(., athlete_info_data, by = c("Event", "Gender")) %>%
  left_join(., country_earnings_data, by = c("Event", "Gender"))


completed_table <- base_table %>%
  cols_move(., columns = Rank_1, after = country_top) %>%
  cols_move(., columns = Rank_4, after = Rank_3) %>%
  cols_move(., columns = spacer, after = Rank_5) %>%
  tab_spanner(.,
              label = "Top five earners per event",
              columns = c("Rank_1", "Rank_2", "Rank_3", "Rank_4", "Rank_5")) %>%
  fmt_currency(earnings_spread, decimals = 0) %>%
  cols_width(earnings_spread ~ pct(8),
             spacer ~ pct(2),
             country_top ~ px(150)) %>%
  cols_align(., align = "center", columns = c("Event", "Gender", "country_top", "earnings_spread")) %>%
  tab_header(.,
             title = md("<h3>2022 Diamond League: Top earning countries and athletes</h3>"),
             subtitle = md("<h4>Within vs. between groupd differences: All or nothing, or pretty close to it</h4>")) %>%
  tab_source_note(., "Source: https://www.diamondleague.com/home/") %>%
  opt_align_table_header(., align = "left")

completed_table
