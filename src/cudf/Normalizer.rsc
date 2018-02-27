module cudf::Normalizer

import cudf::AST;
import util::Benchmarking;

import IO;
import Set;
import List;

void normalize(list[Package] packages, Request req) {
  println("Start analysing packages");
  tuple[rel[Package,str] provRel, int time] pr = bmWithPrint("Normalizing features", normalizeFeatures, packages);
}

list[Package] normalizeFeatures(list[Package] packages) {
  rel[str, Package] provides = {<pf.name, p> | Package p <- packages, /PackageFormula pf := p.provides}; 
  println("Nr of packages providing a feature: <size(provides)>");
 
  set[str] features = provides<0>;
 
  set[PackageFormula] getProviders(str feature) = {equal(pf.name, pf.version) | Package pf <- provides[feature]};  
  
  list[Package] normalizedPackages = [];
  int size = size(packages);
  
  println("Normalizing found features"); 
  for (int i <- [0..size], Package p := packages[i]) {
    if (i % (size / 10) == 0) {
      print("...<i / (size / 100)>%");
    }
    
    p.depends = visit(p.depends) {
      case PackageFormula pf => or(getProviders(pf.name)) when pf has name, pf.name in features 
    }
    
    for (PackageFormula pf <- p.conflicts, p has name, pf.name in features) {
      providers = getProviders(pf.name);
      p.conflicts = p.conflicts - pf + toList(providers);
    } 
    
    normalizedPackages += p;
  }
    
//  rel[Package,str] depending = {<p, pf.name> | Package p <- normalizedPackages, /PackageFormula pf := p.depends, pf has name, pf.name in features};
//  println("Nr of packages depending on a feature: <size(depending)>");
//
//  rel[Package,str] conflicting = {<p, pf.name> | Package p <- normalizedPackages, /PackageFormula pf := p.conflicts, pf has name, pf.name in features};
//  println("Nr of packages conflicting with a feature: <size(conflicting)>");
  
  return normalizedPackages;
}

