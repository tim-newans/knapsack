library(lpSolveAPI)
library(tidyverse)
judgevotes <- 5
players <- 7
{
 data <-  data.frame(Judge = rep(c(rep("A",judgevotes),rep("B",judgevotes)),players),
                     Player =c(rep("Libba",judgevotes*2),rep("Macrae",judgevotes*2),rep("Bont",judgevotes*2),rep("Weightman",judgevotes*2),
                     rep("Parish",judgevotes*2),rep("Naughton",judgevotes*2),rep("Ridley",judgevotes*2)),
                     Votes = rep(1:judgevotes,players*2),
                     Libba = c(rep(1:judgevotes,2),rep(0,(players-1)*judgevotes*2)),
                     Macrae = c(rep(0,judgevotes*2),rep(1:judgevotes,2),rep(0,(players-2)*judgevotes*2)),
                     Bont = c(rep(0,judgevotes*2*2),rep(1:judgevotes,2),rep(0,(players-3)*judgevotes*2)),
                     Weightman = c(rep(0,judgevotes*2*3),rep(1:judgevotes,2),rep(0,(players-4)*judgevotes*2)),
                     Parish = c(rep(0,judgevotes*2*4),rep(1:judgevotes,2),rep(0,(players-5)*judgevotes*2)),
                     Naughton = c(rep(0,judgevotes*2*5),rep(1:judgevotes,2),rep(0,(players-6)*judgevotes*2)),
                     Ridley = c(rep(0,judgevotes*2*6),rep(1:judgevotes,2)))

  knapsack <- make.lp(0, nrow(data))

  ## Add Brownlow Point Constraints
  add.constraint(knapsack, data$Libba, "=", 7)
  add.constraint(knapsack, data$Macrae, "=", 6)
  add.constraint(knapsack, data$Bont, "=", 5)
  add.constraint(knapsack, data$Weightman, "=", 5)
  add.constraint(knapsack, data$Parish, "=", 4)
  add.constraint(knapsack, data$Naughton, "=", 2)
  add.constraint(knapsack, data$Ridley, "=", 1)
  
  ## Add Judge constraints
  judgea1 <- ifelse(data$Judge == "A" & data$Votes == 1, 1, 0)
  judgea2 <- ifelse(data$Judge == "A" & data$Votes == 2, 1, 0)
  judgea3 <- ifelse(data$Judge == "A" & data$Votes == 3, 1, 0)
  judgea4 <- ifelse(data$Judge == "A" & data$Votes == 4, 1, 0)
  judgea5 <- ifelse(data$Judge == "A" & data$Votes == 5, 1, 0)
  judgeb1 <- ifelse(data$Judge == "B" & data$Votes == 1, 1, 0)
  judgeb2 <- ifelse(data$Judge == "B" & data$Votes == 2, 1, 0)
  judgeb3 <- ifelse(data$Judge == "B" & data$Votes == 3, 1, 0)
  judgeb4 <- ifelse(data$Judge == "B" & data$Votes == 4, 1, 0)
  judgeb5 <- ifelse(data$Judge == "B" & data$Votes == 5, 1, 0)
  add.constraint(knapsack, judgea1, "=", 1)
  add.constraint(knapsack, judgea2, "=", 1)
  add.constraint(knapsack, judgea3, "=", 1)
  add.constraint(knapsack, judgea4, "=", 1)
  add.constraint(knapsack, judgea5, "=", 1)
  add.constraint(knapsack, judgeb1, "=", 1)
  add.constraint(knapsack, judgeb2, "=", 1)
  add.constraint(knapsack, judgeb3, "=", 1)
  add.constraint(knapsack, judgeb4, "=", 1)
  add.constraint(knapsack, judgeb5, "=", 1)
  
  ## Add Player Constraints
  libba <- ifelse(data$Player == "Libba", 1, 0)
  macrae <- ifelse(data$Player == "Macrae", 1, 0)
  bont <- ifelse(data$Player == "Bont", 1, 0)
  weightman <- ifelse(data$Player == "Weightman", 1, 0)
  parish <- ifelse(data$Player == "Parish", 1, 0)
  naughton <- ifelse(data$Player == "Naughton", 1, 0)
  ridley <- ifelse(data$Player == "Ridley", 1, 0)
  add.constraint(knapsack, libba, "<=", 2)
  add.constraint(knapsack, macrae, "<=", 2)
  add.constraint(knapsack, bont, "<=", 2)
  add.constraint(knapsack, weightman, "<=", 2)
  add.constraint(knapsack, parish, "<=", 2)
  add.constraint(knapsack, naughton, "<=", 2)
  add.constraint(knapsack, ridley, "<=", 2)

  ## Make sure the decision variables are binary
  set.type(knapsack, seq(1, nrow(data), by=1), type = c("binary"))
  
  ## Solve the model, if this returns 0 an optimal solution is found
  rc<-solve(knapsack)
  sols<-list()
  obj0<-get.objective(knapsack)
  # find more solutions
  while(TRUE) {
    sol <- round(get.variables(knapsack))
    sols <- c(sols,list(sol))
    add.constraint(knapsack,2*sol-1,"<=", sum(sol)-1)
    rc<-solve(knapsack)
    if (rc!=0) break;
    if (get.objective(knapsack)<obj0-1e-1) break;
  }
  sols  
}

## Get the players on the team

full_team <- subset(as.data.frame(data), unlist(sols[1]) == 1)
full_team <- full_team %>% select(-Judge) %>% arrange(Player,Votes)
full_team$Sol <- paste(paste(full_team$Player,collapse = ""),paste(full_team$Votes,collapse = ""))
full_team$SolID <- 1

for (i in 2:length(sols)) {
  team_select <- subset(as.data.frame(data), unlist(sols[i]) == 1)
  team_select <- team_select %>% select(-Judge) %>% arrange(Player,Votes)
  team_select$Sol <- paste(paste(team_select$Player,collapse = ""),paste(team_select$Votes,collapse = ""))
  team_select$SolID <- i
  full_team <- bind_rows(full_team, team_select)
}

unique <- full_team[!duplicated(full_team %>% select(-SolID)),]
nested_unique <- unique %>%
  select(Player,Votes,SolID) %>%
  nest(data = c(Player,Votes))
