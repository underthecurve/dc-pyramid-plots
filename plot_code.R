library('tidyverse')
library('waffle')

dc.18 <- read_csv('dc_2010_2018.csv')

# combine race groups and calculate percentage for population pyramid graphic
dc.18 <- dc.18 %>% 
  filter(AGEGRP != 0 & race != 'all') %>% 
  mutate(race_cat = case_when(race_name == 'American Indian and Alaska Native' |
                              race_name == 'Multiple' |
                              race_name == 'Native Hawaiian and Other Pacific Islander' ~ 'MultipleOther',
                              TRUE ~ race_name)) %>%
  group_by(YEAR) %>%
  mutate(total.pop = sum(value)) %>%
  ungroup() %>%
  group_by(YEAR, race_cat, sex) %>%
  mutate(total.by.race_sex = sum(value)) %>%
  mutate(perc = (value/total.by.race_sex) * 100,
         race.f = factor(race_cat, 
                         levels = c('Black', 'White', 
                                    'Hispanic', 'Asian', 'MultipleOther')))
dc.18 <- dc.18 %>% 
  mutate(perc2 = ifelse(sex == 'MALE', perc*-1, perc),
         age_name = gsub('age_','', age_name))

ggplot(dc.18 %>% filter(year_name == 2018)) +
  geom_bar(aes(x = age_name, y = perc2, 
               fill = sex), stat = 'identity') +
  geom_hline(yintercept = 0, color = 'darkgrey', size = .8) +
  facet_wrap(~race.f, nrow = 1) + 
  coord_flip() + 
  scale_fill_manual(values = c('#22487f',
                               '#0079af')) +
  labs(x = 'age range\n', y = '\npopulation') +
  theme(panel.grid.minor.y = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.x = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(size = 18, face = 'bold'),
        legend.position = 'top',
        legend.title = element_blank(),
        panel.spacing = unit(1.5, "lines"),
        axis.text = element_text(size = 13)) +
  labs(x='', y='')

ggsave('dc_race_age.eps', width = 15, height = 4)

# export for interpolation of median age
dc.18 %>% ungroup() %>% filter(year_name == 2018) %>%
  select(age_name, race_cat, n = value) %>% 
  separate(age_name, into = c('min',
                              'max'), remove = F) %>%
  mutate(min = as.numeric(min),
         max = as.numeric(max)) %>% write_csv('dc_age2018.csv')


#racial composition of DC in 2018
dc.18.race <- 
  dc.18 %>% 
  filter(year_name == 2018) %>%
  group_by(CTYNAME, race_cat, race.f) %>%
  summarise(pop = sum(value)) %>%
  ungroup() %>%
  mutate(total = sum(pop),
         perc = (pop/total) * 100) %>% 
  arrange(desc(perc))

dc.18.race

# racial composotion of the 25-34 age category
dc.18.25_34 <- dc.18 %>% group_by(age_name, 
                                  race_cat, 
                                  year_name) %>% 
  summarise(value = sum(value))  %>% filter(age_name == '25-29' | 
                                              age_name == '30-34') %>%
  ungroup() %>% 
  group_by(year_name) %>% 
  mutate(tot.25_34 = sum(value)) %>%
  ungroup() %>% group_by(race_cat, year_name, tot.25_34) %>% 
  summarise(tot.race.25_34 = sum(value)) %>% 
  mutate(perc = (tot.race.25_34/tot.25_34) * 100)

# # waffles: see https://github.com/underthecurve/bars-pies-waffles
# dc.18.race <- dc.18.race %>% mutate(perc.round = round((pop/total) * 100),
#                                     chart.perc = 100-perc.round) # where chart.perc is everybody else
# 
# make_waffle_chart <- function(race_grp) {
#   waffle(dc.18.race %>% filter(race_cat == race_grp) %>% ungroup() %>% 
#          select(perc.round, chart.perc),
#          rows = 10, size = 0.2, flip = T, legend_pos = 'none',
#          colors = c("#4d4d4d", '#E7E7E7'))
# }
# 
# for (i in unique(dc.18.race$race_cat)) { 
#   make_waffle_chart(i)
#   ggsave(paste0( 
#     i, '.eps'), 
#     device = 'eps')
# }
