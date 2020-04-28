module cudf::ModelFinder

import util::Statistics;

import translation::AST;           // From AlleAlle
import ModelFinder;                // From AlleAlle
import translation::SMTInterface;  // From AlleAlle
import smtlogic::Core;             // From AlleAlle
import smtlogic::Ints;             // From AlleAlle

import IO;
import ValueIO;
import List;
import String;
import Set;

alias PackageVersion = rel[str package, int version];

alias FindModelResult = tuple[bool sat, PackageVersion toBeInstalled, PackageVersion toBeRemoved, Statistic stats];

FindModelResult findSolution(loc file, Problem p) {
  println("PART 5 (of 6): Finding solution");
  loc binFile = file.parent + "/output/" + file.file + "/finder.bin";
  
  if (exists(binFile)) {
    println("Existing bin file with model finder result found. Reading that");
    println();
    
    return readBinaryValueFile(#FindModelResult, binFile);
  } else {

    println("Finding optimal solution");
    
    // first, save created problem
    //writeFile(file.parent + "/output/" + file.file + "/problem.allee", unparse(p));
    
    ModelFinderResult mfr = checkInitialSolution(p);
    
    FindModelResult result;
    if (sat(Model currentModel, Model (Domain) nextModel, void () stop) :=  mfr) {
      mfr.stop();
  
      tuple[PackageVersion toBeInstalled, PackageVersion toBeRemoved, PackageVersion toBeChanged] es = extractSolution(currentModel);
      //printSolution(es.toBeInstalled, es.toBeRemoved);
  
      int nrOfRemovedPackages = size({pa | pa <- es.toBeRemoved, es.toBeInstalled[pa.package] == {}});
  
      Statistic stat = solvingProblem(mfr.translationTime, mfr.solvingTime, true, nrOfRemovedPackages, size(es.toBeChanged));
      result = <true, es.toBeInstalled, es.toBeRemoved, stat>;
       
    } else if (unsat(set[Formula] unsatCore) := mfr || trivialUnsat() := mfr) {
      println("No solution possible");
      Statistic stat = solvingProblem(mfr.translationTime, mfr.solvingTime, false, 0, 0);
      result = <false, {}, {}, stat>;
    }
    
    writeBinaryValueFile(binFile,result);
    println();
    return result;
  }
}

tuple[PackageVersion toBeInstalled, PackageVersion toBeRemoved, PackageVersion toBeChanged] extractSolution(Model currentModel) {
  tuple[str,int] extractVersion(idAttribute(str name, str packVer)) = <pack,toInt(ver)> when name == "vId", /^<pack:.*>[_]<ver:[0-9]+>$/ := packVer;

  PackageVersion extractVersion(ModelRelation r) = {<pack,ver> | ModelTuple t <- r.tuples, ModelAttribute a <- t.attributes, <pack,ver> := extractVersion(a)}; 
  
  map[str, ModelRelation] relations = (r.name:r | r <- currentModel.relations);
  
  PackageVersion toBeInstalled = extractVersion(relations["toBeInstalled"]);
  PackageVersion toBeRemoved   = extractVersion(relations["toBeRemovedVersion"]);
  PackageVersion toBeChanged   = extractVersion(relations["toBeChanged"]);
  
  return <toBeInstalled, toBeRemoved, toBeChanged>;
}

void printSolution(PackageVersion toBeInstalled, PackageVersion toBeRemoved) {
  void printPackageVersions(PackageVersion pv) = print(intercalate("\n", ["* <pack> (<ver>)" | <pack,ver> <- pv]));
  
  println("");
  println("Optimal solution:");
  println("=================");
  println("To be installed:");
  printPackageVersions(toBeInstalled);
  println("");
  println("To be removed:");
  printPackageVersions(toBeRemoved);
  println("");
}