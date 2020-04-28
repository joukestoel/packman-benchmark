module util::CsvToLatexConverter

import lang::csv::IO;

import IO;
import String;
import List;

void convert() = convert(|project://packman-benchmark/benchmark/misc2012/paranoid/problems/real/result/results.csv|, |file:///Users/jouke/workspace/papers/gpce218/benchmark/packman_result_total.tex|, |file:///Users/jouke/workspace/papers/gpce218/benchmark/packman_result_abr.tex|);

void convert(loc statisticsCsv, loc outputTotal, loc outputAbr) {
  rel[str file,
      int nr_of_packages_after_parsing, bool contains_install_requests, bool contains_remove_requests, bool contains_upgrade_request, int parsing_time,
      int normalizing_time,
      int nr_of_packages_after_slicing, int slicing_time,
      int nr_of_packages_in_problem, int nr_of_versions_in_problem, int nr_of_installed_packages_in_problem, int nr_of_to_be_installed_in_problem, int nr_of_to_be_removed_versions_in_problem, int nr_of_to_be_packages_versions_in_problem, int nr_of_to_be_changed_in_problem, int nr_of_dependencies_in_problem, int nr_of_depency_choices_in_problem, int nr_of_conflicts_in_problem, int nr_of_keep_in_problem, int constructing_problem_time,
      int translation_time, int solving_time, bool sat, int nr_of_removed_packages, int nr_of_changes,
      bool solution_correct, bool solution_optimal, int winning_solving_time_in_competition, int checking_time,
      int total_time_not_translation_or_solving, int total_time] stats = readCSV(#rel[str,int,bool,bool,bool,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int,bool,int,int,bool,bool,int,int,int,int], statisticsCsv);
  
  str resTot = "\\begin{table}[h!]
               '  \\centering
               '  \\scalebox{0.8}{
               '  \\begin{tabular}{@{}llrrrrccr@{}} \\toprule
               '    \\thead{Problem name} & \\thead{Request type} & \\thead{\\# of Packages \\\\ in CUDF} & \\thead{\\# dependencies} & \\thead{\\alle translation \\\\ time (in sec)} & \\thead{\\z3 solving \\\\ time (in sec)}  & \\thead{Best 2012 competition \\\\ solving time (in sec)} & \\thead{Correct?} & \\thead{Optimal?} \\\\ \\midrule
               '    <for (s <- stats, !skip(s.contains_install_requests,s.contains_remove_requests,s.contains_upgrade_request)) {> <replaceLast(s.file, ".cudf", "")> & <requestType(s.contains_install_requests,s.contains_remove_requests,s.contains_upgrade_request)> & <s.nr_of_packages_after_parsing> & <s.nr_of_depency_choices_in_problem> & <toSec(s.translation_time)> & <toSec(s.solving_time)> & <toSec(s.winning_solving_time_in_competition)> & <toStr(s.solution_correct)> & <toStr(s.solution_optimal)> \\\\ 
               '    <}>
               '  \\bottomrule \\end{tabular}}
               '  \\label{tab:packman_total}
               '\\end{table}
               '";
  
  int i = 0;
  
  str resAbr = "\\begin{table}
               '  \\centering
               '  \\caption{First 10 results of the translation and solving times of the optimal dependency resolution problem with \\alle according to the \\textit{paranoid} criteria. Full results can be found in~\\ref{apx:packman_full}}
               '  \\scalebox{0.80}{
               '  \\begin{tabular}{@{}llrrrrr@{}} \\toprule
               '    \\thead{Problem} & \\thead{Request} & \\thead{\\# Packages \\\\ in CUDF} & \\thead{\\# dep.} & \\thead{\\alle \\\\ trans. time \\\\ (in sec)} & \\thead{\\z3 \\\\ sol. time \\\\ (in sec)} & \\thead{Comp. 2012 \\\\ best sol. time \\\\ (in sec)}\\\\ \\midrule
               '    <for (s <- stats, i < 10, !skip(s.contains_install_requests,s.contains_remove_requests,s.contains_upgrade_request)) { i += 1;> <substring(s.file, 0, 8)> & <requestType(s.contains_install_requests,s.contains_remove_requests,s.contains_upgrade_request)> & <s.nr_of_packages_after_parsing> & <s.nr_of_depency_choices_in_problem> & <toSec(s.translation_time)> & <toSec(s.solving_time)> & <toSec(s.winning_solving_time_in_competition)>\\\\ 
               '    <}>
               '   ... & ... & ... & ... & ... & ...  \\\\ \\bottomrule
               '  \\end{tabular}}
               '  \\label{tab:packman_abr}
               '\\end{table}
               '";
                 
  writeFile(outputTotal,resTot);
  writeFile(outputAbr,resAbr);  
}

str toSec(int ms) = "<ms / 1000>.<left("<(ms % 1000) / 10>",2,"0")>";

str toStr(bool b) = b ? "yes" : "no";

bool skip(bool install, bool removal, bool upgrade) = !(install || removal || upgrade);

str requestType(bool install, bool removal, bool upgrade) {
  list[str] rt = [];
  if (install) rt += "install";
  if (removal) rt += "removal";
  if (upgrade) rt += "upgrade";  
  
  return intercalate(",",rt); 
}