module util::ChangeSetExtractor

import cudf::AST;
import cudf::CudfReader;

import IO;
import Set;

alias PackVer = tuple[str package, int version];

void extractChangeSet(loc origCudf, loc solutionCudf) {
  set[PackVer] orig = {<p.name,p.version> | p <- readAndParseCudfFile(origCudf).packages, p.installed};
  set[PackVer] sol =  {<p.name,p.version> | p <- readAndParseCudfFile(solutionCudf).packages, p.installed};
  
  // check everyting that is removed and installed
  set[PackVer] removed = {p | PackVer p <- orig, p notin sol};
  set[PackVer] installed = {p | PackVer p <- sol, p notin orig};
  
  set[str] installedPackages = {p.package | PackVer p <- installed};
  set[str] removedPackages = {p.package | PackVer p <- removed, p.package notin installedPackages};
  
  println("Removed packages:");
  for (p <- removedPackages) {
    println("* <p>");
  }
  
  println("Changed package + versions:");
  for (p <- (removed + installed)) {
    str action = p in removed ? "removed" : "installed";
    println("* <p.package> (<p.version>) (<action>)");
  }
  
  println("Total: removed packages = <size(removedPackages)>, changes = <size(removed+installed)>");
}

void testWithWinningSolution() = 
  extractChangeSet(|project://packman-benchmark/examples/debug/ab9005be-bacc-11e0-b0f6-00163e1e087d.cudf|, 
                   |project://packman-benchmark/examples/debug/ab9005be-bacc-11e0-b0f6-00163e1e087d.cudf.result|);

void testWithOwnSolution() = 
  extractChangeSet(|project://packman-benchmark/examples/debug/ab9005be-bacc-11e0-b0f6-00163e1e087d.cudf|, 
                   |project://packman-benchmark/examples/debug/output/ab9005be-bacc-11e0-b0f6-00163e1e087d/sol.cudf|);

