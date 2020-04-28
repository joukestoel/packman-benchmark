module util::Statistics

import IO;
import Map;
import List;

import lang::csv::IO;

alias Statistics = map[str, Statistic];

data Statistic  
  = parsing(int nrOfPackages, bool installRequest, bool removeRequest, bool upgradeRequest, int time)
  | normalizing(int time)
  | slicing(int nrOfPackages, int time)
  | buildingProblem(int nrOfPackages, int nrOfVersions, int nrOfInstalledPackages, int nrOfToBeInstalled, int nrOfToBeRemovedVersions, int nrOfToBeRemovedPackages, int nrOfToBeChanged, int nrOfDependencies, int nrOfDependencyChoices, int nrOfConflicts, int nrOfKeeps, int time)
  | solvingProblem(int translationTime, int solvingTime, bool sat, int nrOfRemovedPackages, int nrOfChanges)
  | checkingSolution(bool outcome, bool optimal, int winningSolvingTime, int time)
  | complete(Statistic parsing, Statistic normalizing, Statistic slicing, Statistic problemBuilding, Statistic problemSolving, Statistic solutionChecking)
  ;
  
void saveToCSV(Statistics stats, loc output) {
  rel[str file,
      int nr_of_packages_after_parsing, bool contains_install_requests, bool contains_remove_requests, bool constains_upgrade_request, int parsing_time,
      int normalizing_time,
      int nr_of_packages_after_slicing, int slicing_time,
      int nr_of_packages_in_problem, int nr_of_versions_in_problem, int nr_of_installed_packages_in_problem, int nr_of_to_be_installed_in_problem, int nr_of_to_be_removed_versions_in_problem, int nr_of_to_be_packages_versions_in_problem, int nr_of_to_be_changed_in_problem, int nr_of_dependencies_in_problem, int nr_of_depency_choices_in_problem, int nr_of_conflicts_in_problem, int nr_of_keep_in_problem, int constructing_problem_time,
      int translation_time, int solving_time, bool sat, int nr_of_removed_packages, int nr_of_changes,
      bool solution_correct, bool solution_optimal, int winning_solving_time_in_competition, int checking_time,
      int total_time_not_translation_or_solving, int total_time] allStats = {};
      
  for (str file <- stats, complete(Statistic parsing, Statistic normalizing, Statistic slicing, Statistic problemBuilding, Statistic problemSolving, Statistic solutionChecking) := stats[file]) {
    allStats += <file,
                 parsing.nrOfPackages, parsing.installRequest, parsing.removeRequest, parsing.upgradeRequest, parsing.time,
                 normalizing.time,
                 slicing.nrOfPackages, slicing.time,
                 problemBuilding.nrOfPackages, problemBuilding.nrOfVersions, problemBuilding.nrOfInstalledPackages, problemBuilding.nrOfToBeInstalled, problemBuilding.nrOfToBeRemovedVersions, problemBuilding.nrOfToBeRemovedPackages, problemBuilding.nrOfToBeChanged, problemBuilding.nrOfDependencies, problemBuilding.nrOfDependencyChoices, problemBuilding.nrOfConflicts, problemBuilding.nrOfKeeps, problemBuilding.time,
                 problemSolving.translationTime, problemSolving.solvingTime, problemSolving.sat, problemSolving.nrOfRemovedPackages, problemSolving.nrOfChanges,
                 solutionChecking.outcome, solutionChecking.optimal, solutionChecking.winningSolvingTime, solutionChecking.time,
                 parsing.time + normalizing.time + slicing.time + problemBuilding.time + solutionChecking.time,parsing.time + normalizing.time + slicing.time + problemBuilding.time + solutionChecking.time + problemSolving.translationTime + problemSolving.solvingTime>;
                 
  }
      
  writeCSV(allStats,output);   
}
