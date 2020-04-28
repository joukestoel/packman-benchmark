module cudf::Slicer

import cudf::AST;
import cudf::Unparser;

import util::Benchmarking;
import util::Statistics;
import util::Progress;

import util::MemoCacheClearer;

import IO;
import ValueIO;
import Set;
import List;

alias SlicedFileContent = tuple[set[Package] packages, Request req, Statistic stats];

SlicedFileContent slice(loc file, list[Package] packages, Request req) {
  println("PART 3 (of 6): Slicing problem");
  loc binFile = file.parent + "/output/" + file.file + "/sliced.bin";
  
  if (exists(binFile)) {
    println("Existing bin file with sliced packages found. Reading that");
    println("");
    
    return readBinaryValueFile(#SlicedFileContent, binFile);
  } else {
    println("No existing bin file with sliced packages found. Start slicing.");
    clearMemoCache({"cudf::Slicer"});
    
    
    tuple[set[Package] packages, int time] sr = bm(sliceAll, toSet(packages), req);
    tuple[set[Package] packages, int time] rnic = bm(removeNonInstalledConflicts, sr.packages);
    
    Statistic stats = slicing(size(rnic.packages), (sr.time+rnic.time)/1000000);
    
    int saveTime = bmWithPrint("Saving sliced result as binary file", writeBinaryValueFile, binFile, <rnic.packages, req, stats>);
    
    saveToCudf(file,toList(rnic.packages), req);
    
    println();
    
    return <sr.packages,req,stats>;
  }
}

void saveToCudf(loc origCudf, list[Package] packages, Request req) 
  = writeFile(origCudf.parent + "/output/" + origCudf.file + "/sliced.cudf", unparse(packages, req));

set[Package] sliceAll(set[Package] allPackages, Request req) {
  println("Sorting packages by name");  
  rel[str, Package] sortedPackages = {};
  for (Package p <- allPackages) {
    sortedPackages += <p.name, p>; 
  }

  set[Package] filtered = {p | Package p <- allPackages, p.installed};
  set[Package] dependsTodo = {};
  set[Package] conflictsTodo = {};

  @memo set[Package] findPotentialPackages(packageOnly(str name))          = {p | Package p <- sortedPackages[name]}; 
  @memo set[Package] findPotentialPackages(equal(str name, int version))   = {p | Package p <- sortedPackages[name], p.version == version};
  @memo set[Package] findPotentialPackages(inequal(str name, int version)) = {p | Package p <- sortedPackages[name], p.version != version};
  @memo set[Package] findPotentialPackages(gte(str name, int version))     = {p | Package p <- sortedPackages[name], p.version >= version};
  @memo set[Package] findPotentialPackages(gt(str name, int version))      = {p | Package p <- sortedPackages[name], p.version > version};
  @memo set[Package] findPotentialPackages(lte(str name, int version))     = {p | Package p <- sortedPackages[name], p.version <= version};
  @memo set[Package] findPotentialPackages(lt(str name, int version))      = {p | Package p <- sortedPackages[name], p.version < version};
  @memo set[Package] findPotentialPackages(or(set[PackageFormula] forms))  = ({} | it + findPotentialPackages(f) | f <- forms);
  
  void check(Package p) {
    if (p in filtered) {
      // already done, skip
      return;
    }
    
    filtered += p;
    
    // check dependencies
    for (PackageFormula form <- p.depends) { 
      dependsTodo += findPotentialPackages(form);
    }
    for (PackageFormula form <- p.conflicts) {
      conflictsTodo += findPotentialPackages(form);
    }
    
    for (normalized(set[PackageFormula] forms) := p.keep, PackageFormula pf <- forms) {
      dependsTodo += findPotentialPackages(pf);
    } 
  }
  
  dependsTodo = ({} | it + findPotentialPackages(inequal(p.name,p.version)) | p <- allPackages, p.installed) + 
                ({} | it + findPotentialPackages(p) | p <- req.install) + 
                ({} | it + findPotentialPackages(p) | p <- req.remove) + 
                ({} | it + findPotentialPackages(p) | p <- req.upgrade);
  
  sp = spinner(prefix = "Finding all referenced packages");
  while (dependsTodo != {} || conflictsTodo != {}) {
    sp.update("dependencies: <size(dependsTodo)>, conflicts: <size(conflictsTodo)>");
    
    for (d <- dependsTodo) {
      //println("Checking dependency <d.name> (v<d.version>)");
      dependsTodo -= d;
      check(d);
    }
    
    for (c <- conflictsTodo) {
      //println("Checking conflict <c.name> (v<c.version>)");
      conflictsTodo -= c;
      //check(c);
            
      if (c.installed) {
        // check which packages use this package and check whether it is installed
        set[Package] usedBy = findPotentialPackages(packageOnly(c.name));
        for (u <- usedBy) {
          if (u.installed) {
            check(u);
          } 
          //else {
            //filtered += u;
          //}
        }
      }
    }   
  }
  sp.finished();
  
  return filtered;
}

set[Package] removeNonInstalledConflicts(set[Package] packages) {
  rel[str, Package] sortedPackages = {};
  for (Package p <- packages) {
    sortedPackages += <p.name, p>; 
  }
  
  set[Package] filtered = {};
  
  int nrOfPackages = size(packages);
  pb = progressBar(nrOfPackages, length = 15, limit = 100, prefix = "Removing not installed conflicts");
  int i = 0;
  for (Package p <- packages) {
    pb.report("<i> of <nrOfPackages>");
  
    p.conflicts = visit (p.conflicts) {
      case PackageFormula pf => pf when sortedPackages[pf.name] != {}
    }
    
    filtered += p;
    i += 0;
  }
  pb.finished();
  
  return filtered;
} 

