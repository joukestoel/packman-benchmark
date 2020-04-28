module cudf::SolutionChecker

import cudf::AST;
import cudf::Unparser;

import util::Statistics;
import util::Benchmarking;
import util::ParanoidCompetitionResult;

import IO;
import ValueIO;
import util::ShellExec;
import String; 
import Set;

alias SolutionCheckerResult = tuple[Statistic stats];

SolutionCheckerResult checkSolution(loc file, bool sat, list[Package] packages, rel[str,int] toBeInstalled, rel[str,int] toBeRemoved, str solCheckerExec) {
  println("PART 6 (of 6): Checking found solution");  
  
  loc binFile = file.parent + "/output/" + file.file + "/sol.bin";
  
  if(!exists(binFile)) {
    SolutionCheckerResult result;
    if (sat) {
      tuple[bool solutionCorrect, int time] csc = bm(checkSolutionCorrectness, solCheckerExec, file, packages, toBeInstalled, toBeRemoved);
      tuple[tuple[bool optimal, int winningTime] result, int time] cso = bm(checkSolutionOptimal, file, toBeInstalled, toBeRemoved);   
      
      result = <checkingSolution(csc.solutionCorrect, cso.result.optimal, cso.result.winningTime, (csc.time+cso.time)/1000000)>;
    } else {
      result = <checkingSolution(checkSolutionFailedInComp(file), true, -1,0)>;
    }
    
    writeBinaryValueFile(binFile, result);     
    println(); 
    return result;
  } else {
    println("Existing bin file with solution found. Reading that");
    println();
    return readBinaryValueFile(#SolutionCheckerResult, binFile);
  }
}

loc getSolutionLoc(loc cudfFile) = cudfFile.parent + "/output/" + cudfFile.file + "/sol.cudf";

bool solutionExists(loc cudfFile) = exists(getSolutionLoc(cudfFile));

bool checkSolutionFailedInComp(loc file) {
  map[str,CompetitionResult] compResult = getCompetitionResults();
  return compResult[file.file] == unsatResult();
}

tuple[bool, int] checkSolutionOptimal(loc file, rel[str,int] toBeInstalled, rel[str,int] toBeRemoved) {
  print("Checking is optimal...");
  
  map[str,CompetitionResult] compResult = getCompetitionResults();
  
  if (file.file notin compResult) {
    throw "Unkown file. Not in competition result";
  }
  
  if (unsatResult() := compResult[file.file]) {
    throw "In the competion all solvers failed to find a solution for this problem";
  }
  else {  
    int nrOfRemovedPackages = size({p | p <- toBeRemoved, toBeInstalled[p<0>] == {}});
    int nrOfChanges = size(toBeInstalled + toBeRemoved);
  
    bool isOptimal = compResult[file.file].nrOfRemovals == nrOfRemovedPackages && compResult[file.file].nrOfChanges == nrOfChanges;
    
    println("<isOptimal ? "found solution is OPTIOMAL" : "found solution is NOT OPTIMAL">");
    
    return <isOptimal,compResult[file.file].winningTime>;
  }   
}

bool checkSolutionCorrectness(str solCheckerExec, loc file, list[Package] packages, rel[str,int] toBeInstalled, rel[str,int] toBeRemoved) {
  print("Checking correctness...");
  loc solFile = getSolutionLoc(file);

  rel[str,int] newUniverse = toBeInstalled + {<p.name,p.version> |  p <- packages, p.installed == true, toBeRemoved[p.name] == {}}; 
  writeFile(solFile, buildNewUniverse(newUniverse));
  bool correct = isSolutionCorrect(solCheckerExec, file, solFile);
  
  println("<correct ? "found solution is CORRECT" : "found solution is INCORRECT">");
  
  return correct;
}
  
bool isSolutionCorrect(str solCheckerExec, loc origFile, loc solFile) {
  str output = exec(solCheckerExec, args=["-cudf", "<origFile.path>", "-sol" , "<solFile.path>"]);
  
  return contains(output, "original installation status consistent") && contains(output, "is_solution: true");
}

str buildNewUniverse(rel[str,int] uni) =
  "<for (<pack,ver> <- uni) {>
  'package: <pack>
  'version: <ver>
  'installed: true
  '<}>";