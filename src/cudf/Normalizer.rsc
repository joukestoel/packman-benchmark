module cudf::Normalizer

import cudf::AST;
import util::Benchmarking;
import util::Statistics;
import util::Progress;

import IO;
import ValueIO;
import Set;
import List;

alias NormalizedFileContent = tuple[list[Package] packages, Request req, Statistic stats];

NormalizedFileContent normalize(loc file, list[Package] packages, Request req) {
  println("PART 2 (of 6): Normalizing the parsed stanzas");

  loc binFile = file.parent + "/output/" + file.file + "/normalized.bin";
  if (exists(binFile)) {
    println("Existing bin file with normalized packages found. Reading that");
    println();
    
    return readBinaryValueFile(#NormalizedFileContent, binFile);
  } else {
    println("No previous bin file found. Start analysing packages");
    
    tuple[list[Package] packages, int time] nf = bm(normalizeFeatures, packages);
    tuple[list[Package] packages, int time] nkv = bm(normalizeKeep, nf.packages);
    tuple[list[Package] packages, int time] nc = bm(normalizeSelfConflicts, nkv.packages);
    tuple[list[Package] packages, int time] ruc = bm(removeUnnecessaryConflicts, nc.packages);
    tuple[list[Package] packages, int time] rud = bm(removeUnnecessaryDependencies, ruc.packages);
  
    Statistic stats = normalizing((nf.time+nkv.time+nc.time+ruc.time+rud.time)/1000000);
  
    int saveTime = bmWithPrint("Saving normalized result as binary file", writeBinaryValueFile, binFile, <rud.packages, req, stats>);
    println();
    
    return <rud.packages,req,stats>;    
  }  
}

list[Package] normalizeFeatures(list[Package] packages) {
  rel[str, Package] provides = {<pf.name, p> | Package p <- packages, PackageFormula pf <- p.provides}; 
 
  set[str] features = provides<0>;
 
  set[PackageFormula] getProviders(str feature) = {equal(pf.name, pf.version) | Package pf <- provides[feature]};  
  
  list[Package] normalizedPackages = [];
  int nrOfPackages = size(packages);
  
  pb = progressBar(nrOfPackages, length = 15, limit = 100, prefix = "Normalizing features\t\t");
  
  for (int i <- [0..nrOfPackages], Package p := packages[i]) {
    pb.report("<i> of <nrOfPackages>");
        
    p.depends = visit(p.depends) {
      case PackageFormula pf => or(getProviders(pf.name)) when pf has name, pf.name in features 
    }
    
    // flatten the created nested ors
    while (/orig:or({or(nested), *others}) := p.depends) {
      p.depends = p.depends - orig + or(nested + others);
    //p.depends = visit(p.depends) {
    //  case or({or(nested), *others}) => or(others + nested) 
    }
    
    for (PackageFormula pf <- p.conflicts, p has name, pf.name in features) {
      providers = getProviders(pf.name);
      p.conflicts = p.conflicts - pf + toList(providers);
    } 
    
    normalizedPackages += p;
  }
  
  pb.finished();
    
  return normalizedPackages;
}

list[Package] normalizeKeep(list[Package] packages) {
  rel[str, Package] provides = {<pf.name, p> | Package p <- packages, PackageFormula pf <- p.provides}; 
  rel[str, Package] packageOnly = {<p.name, p> | Package p <- packages};
   
  list[Package] normalizedPackages = [];
  int nrOfPackages = size(packages);
  pb = progressBar(nrOfPackages, length = 15, limit = 100, prefix = "Normalizing keep values\t\t");

  for (int i <- [0..nrOfPackages], Package p := packages[i]) {
    pb.report("<i> of <nrOfPackages>");
    
    p.keep = visit(p.keep) {
      case version() => version()
      case package() => normalized({or({equal(p.name, other.version) | Package other <- packageOnly[p.name]})})
      case feature() => normalized({or({equal(other.name, other.version) | Package other <- provides[pf.name]}) | PackageFormula pf <- p.provides}) 
      case none() => none()
    }
    
    normalizedPackages += p;
  }
  
  pb.finished();
  
  return normalizedPackages;
}

list[Package] normalizeSelfConflicts(list[Package] packages) {
  list[Package] normalized = [];
  
  int nrOfPackages = size(packages);
  pb = progressBar(nrOfPackages, length = 15, limit = 100, prefix = "Normalizing self conflicts\t");
  
  for (int i <- [0..nrOfPackages], Package p := packages[i]) {
    pb.report("<i> of <nrOfPackages>");
    str pName = p.name;
   	int pVersion = p.version;
   	 
    p.conflicts = visit(p.conflicts) { 
      case packageOnly(pName) => inequal(pName, pVersion)
      case equal(pName,pVersion) => inequal(pName, pVersion)
    }
    
    normalized += p;
  }
  pb.finished();
  
  return normalized;
}

list[Package] removeUnnecessaryConflicts(list[Package] packages) {
  list[Package] normalized = [];
	
	int nrOfPackages = size(packages);
  pb = progressBar(nrOfPackages, length = 15, limit = 100, prefix = "Removing unnecessary conflicts\t");
	
  for (int i <- [0..nrOfPackages], Package p := packages[i]) {
    pb.report("<i> of <nrOfPackages>");

    for (inequal(str pName, int pVersion) <- p.conflicts) {
      p.conflicts = [c | c <- p.conflicts, equal(pName, int _) !:= c];
    }
    
    normalized += p;
  }
  pb.finished();
  
  return normalized;
}

list[Package] removeUnnecessaryDependencies(list[Package] packages) {
  list[Package] normalized = [];
  
  int nrOfPackages = size(packages);
  pb = progressBar(nrOfPackages, length = 15, limit = 100, prefix = "Removing unnecessary dep from or clauses\t");
  
  for (int i <- [0..nrOfPackages], Package p := packages[i]) {
    pb.report("<i> of <nrOfPackages>");

    p.depends = visit(p.depends) {
      case or(set[PackageFormula] clauses) => or(filtered) when packageOnly(str pName) <- clauses, set[PackageFormula] filtered := {c | c <- clauses, equal(pName, int _) !:= c}, filtered != clauses  
    }
    
    normalized += p;
  }
  pb.finished();
  
  return normalized;
}
