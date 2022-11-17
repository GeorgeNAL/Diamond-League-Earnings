# 2022 Diamond League Earnings: Within- and between-event differences

The purpose of this table is to show the within- and between-event distributions of prize money in the 2022 Diamond League, a professional track & field circuit, along with a look at which countries’ athletes earned the most money in each event. The table uses the [gt](https://gt.rstudio.com/) package, with important help from [purrr](https://purrr.tidyverse.org/), [glue](https://www.rdocumentation.org/packages/glue/versions/1.6.2) and [countrycode](https://www.rdocumentation.org/packages/countrycode/versions/1.4.0).  

### Table of contents
  * [Background](#background)
  * [Key goals for table display](#key-goals-for-table-display)
  * [Four key packages and functions](#four-key-packages-and-functions)
  * [Data preparation](#data-preparation)
  * [Key steps in building the table](#key-steps-in-building-the-table)
  * [Questions, areas for improvement and future directions](#questions-areas-for-improvement-and-future-directions)

## [Background](#Background)

The [Diamond League is a series of track meets](https://www.diamondleague.com/home/) for the top professional track & field athletes worldwide. Like circuits or tours in other individual (as opposed to team) sports, athletes don’t commit to all or a given number of Diamond League meets. The top athletes in each event can pick and choose which meets they want to compete in, and then the meet directors fill out the field by working down the list of athletes who request entry.

The Diamond League is unusual within track & field because there is a [standardized and transparent structure of prize money](https://www.diamondleague.com/rules/). Across all the meets, the 4th place finisher in the women’s pole vault will take home as much as the 4th place finisher in men’s discus, and the winner of the men’s 400 meter hurdles gets as much as the winner of the women’s long jump, and so on.

The combination of these two factors results in some unusual distributions of prize money within and between groups. 

The athlete who wins the most money in an event over the course of the season may not be the most athletically dominant in the event that year. They may have just competed in the most events and finished reasonably well in each. Or, maybe one or two athletes dominated the event for the year, leaving a large pool of other athletes divvying up the telescoping prize money for 2nd through 8th place.

For example, the highest earning athlete in women’s high jump won $77,250, while the 5th highest earner in that event took home $13,500. Meanwhile, the highest earner in the men’s 400m hurdles won $30,000 over the season, while the 5th highest earner in the men’s 400m (no hurdles) won $20,000. 

Aside from [fans and sports business journalists / junkies](https://nalathletics.com/blog/2022/10/03/diamond-league-earnings-table), this information could be quite relevant to coaches and agents as they plan their athletes’ seasons. This data shows where there may be opportunities for an up-and-coming athlete to win big, or for a well-established athlete to run the table. Alternatively, it could tell a coach or agent that they’d be better off entering their athletes in lower profile meets where they could win more money by winning the meet, as opposed to chasing the bright lights of the Diamond League and making less for hitting the same mark but finishing down the table.

## Key goals for table display

  * Color scale to immediately show the range of earnings across the top 5 earners in each event (rows), and the range of earnings among each finishing place (1st - 5th) across events.
  * Each cell contains not just the dollar amount, but the athlete’s name and nationality.
  * Use flags instead of country name or abbreviation to signify nationality, because it’s more visually appealing that way.

## Four key packages and functions

  * `gt`: Looking at the different table options out there, I chose `gt` because it seemed to offer the most convenience and flexibility in applying html to the cells.
- `purrr::nest`: I wanted multiple pieces of information in many of the cells. First, as mentioned above, I wanted the cells to contain the athlete’s name, nationality and season-long earnings. Second, I wanted cells that showed the top 3 highest earning countries for each event, with each cell containing the flag and combined amount. `purr::nest` allowed me to “stack” that data in each cell.
- `glue::glue` allowed me to combine the functionality of the two packages above, applying html to each cell to customize the look.
- `countrycode`: Wow, what a package! [countrycode let me take the three-letter country abbreviations](https://www.rdocumentation.org/packages/countrycode/versions/1.4.0/topics/countrycode) from my raw data (which I had to do some manually cleaning on), and use them to get the flag emoji – not a link to an icon, but the emoji! - to that country. Having tried to manually do the Unicode work myself before starting to put together a list of links to flag icons, discovering countrycode was a huge timesaver and made things so so so so sooooooooo much easier.

## Data preparation

The baseline data was this [PDF showing each athlete’s finish in each Diamond League event](https://static.sportresult.com/sports/at/data/2022/diamond_race/QualificationStanding.pdf). You can see here how I took in and processed this data to make it useful both as a standalone product and for further analysis. I had to do a separate processing on the results for the Diamond League’s final meet. For both the “regular season” meets and the final meet I then converted finishing place into prize money, given that the final meet had more money for each placing. 

Next, I created a dictionary, `country_dict`, to align the Diamond League’s three-letter country codes with ISO2C country codes.

Put all that together, `group_by` and `summarize` to get each athlete’s earnings in each event, and I had my base_frame for this analysis. 

## Key steps in building the table

My three goals for the table shaped the overall process of building the table, with the first two goals imposing the biggest constraints.

I wanted the color of the cells to map to Earnings, but I also wanted the cells to have multiple lines of data. To make this happen, I took a look at the structure of `gt()` tables. I decided to create a “shell” table, `base_table`, that “pre-colored” the cells. Since the color of the cells is independent of the value of the cells once you turn your dataframe into a `gt()` table, I could then just overwrite the cells with my multi-line text (which would actually be html!).

```
base_frame %>%
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
  ```

Similarly, I created a blank placeholder column that I’d use to show the top earning countries in each event, and a spacer column to improve the readability of the final column. 

From here, I used basically the same process to generate the information that would go into these columns.

First, I wrote a function that would take the contents of my nested columns and convert them to html. I used `glue:glue` to, well, glue together the html with the values I was referencing from the nested columns, then applied `gt::html` to ensure it would stay as html. Then, starting with base_frame, I did the necessary grouping, nesting, aggregating and pivoting, and then applied the “_to_html” functions to the data.

```
rank_to_html <- function(cell_info) {
  
  html_out <- glue::glue('<div style = "font-size: 16px;font-weight:600;">{unlist(cell_info)[1]}</div>
        <div style="line-height:18px;font-size: 16px;">{unlist(cell_info)[2]}</div>
        <div style="line-height:18px;font-size: 16px;">{unlist(cell_info)[3]}</div>')
  html_out <- map(html_out, gt::html)
  return(html_out)
}

emoji_to_html <- function(cell_info) {
  
  html_out <- glue::glue('<div style="font-size: 16px;float:left;">{unlist(cell_info)[1]}\t{unlist(cell_info)[2]}</div>')
  return(html_out)
}

base_frame %>%
  ...
  nest(flag_emoji, Earnings) %>%
  select(-Country) %>%
  mutate(country_top = map(data, emoji_to_html)) %>%
  summarize(country_top = paste(country_top, collapse = "<br>")) %>%
  ungroup() %>%
  mutate(country_top = map(country_top, gt::html)) %>%
  gt()
```

This gave me two gt tables, of which I only needed the data, not the styling. More specifically, I only needed the new_table$`_data` for each, which I could now just join onto the base frame’s $`_data`. 

```
athlete_info_data <- athlete_info$`_data`
country_earnings_data <- country_earnings$`_data`

base_table$`_data` <- base_table$`_data` %>%
 select(Event, Gender, earnings_spread, spacer) %>%
 left_join(., athlete_info_data, by = c("Event", "Gender")) %>%
 left_join(., country_earnings_data, by = c("Event", "Gender"))
```

The hard work being done, now it’s just a matter of ordering the columns, creating a spanner column, adding titles and the like.

```
base_table %>%
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
  ```

## Questions, areas for improvement and future directions

Easy question: Are there better ways of doing any of this? Absolutely damn right yes. The hackery will continue until my skills improve, which often entails stumbling upon a Stack Overflow post. 

For example, as I was looking up ways to format the title – one of the absolute last things I worked on - I discovered `gt::md()`. Could I have used that instead of my custom html functions, and would that have been easier? Maybe to both.

My usual go-to table package is [reactablefmtr](https://kcuilla.github.io/reactablefmtr/index.html). A key feature `reactablefmtr` has over `gt` is sortable columns. We’d only be able to sort three columns in this table: the three un-nested columns, arguably the ones that would be least interesting to sort by. The nesting and styling was much more important to me than sortability, which tilted my decision towards `gt`. Besides, I think the cell colors do more to show the within- and between-group relationships better than any simple sorting could (although, yes, it would be cool to click to see the highest-earning third-highest earner). Could a table that had “native” multi-line cells be sortable by an element of the list that makes up a nested cell?

As we showed here, and as the [reactablefmtr Cookbook](https://kcuilla.github.io/reactablefmtr/articles/reactablefmtr_cookbook.html) states explicitly, tables can be used as a data viz. The line between the two is increasingly blurry. Perhaps because tables make their information explicit, most table packages do not have the ability to show legends, color scales and the like. I was not able to figure out a way to create a `ggplot2`-style color palette legend bar to put next to above the table, so people could see at a glance what colors corresponded to what earnings amounts or ranges. 

Perhaps that's the resulted of an outdated conception of what tables are, do or could be. Which brings me to....

Finally, to my knowledge (refer back to the first paragraph of this conclusion), tables from both `gt` and `reactablefmtr` are not mobile responsive. The [reactablefmtr html tables that I currently have on websites](https://nalathletics.com/blog/2022/08/16/track-field-niche-sport-attendance-salaries) barely show a column or two on my phone. This is a big gap in the world of tables, not just on the package side but on the concept and design side. Tables lend themselves to bigger displays. How should we start approaching tables to make them more mobile friendly? These may be deeper questions into the theory behind and application of a “grammar of tables."
