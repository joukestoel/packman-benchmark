module cudf::ProblemBuilder

import cudf::AST;
import util::Benchmarking;
import util::Statistics;
import util::Maybe;

import ide::Imploder;         // From AlleAlle
import translation::AST;      // From AlleAlle
import translation::Unparser; // From AlleAlle

import IO;
import Set; 
import List;

alias ProblemBuilderResult = tuple[Problem problem, Statistic stats];

ProblemBuilderResult buildProblem(loc origCudf, set[Package] universe, Request req, bool saveProblemToFile = false) {
  println("PART 4 (of 6): Building AlleAlle problem");
  tuple[list[RelationDef] relations, int time] br = bm(buildRelations, universe, req);	
  
  tuple[list[AlleFormula] const, int time] bc = bm(constraints,req);
  tuple[Maybe[ObjectiveSection] objSec, int time] bo = bm(constructObjectives, req);
    
  int getRelationSize(str name) = size({t | /AlleTuple t := rd.bounds}) 
    when RelationDef rd <- br.relations, rd.name == name;    
    
  Statistic stat = buildingProblem(getRelationSize("package"),getRelationSize("version"),getRelationSize("installed"), 
                     getRelationSize("toBeInstalled"),getRelationSize("toBeRemovedVersion"),getRelationSize("toBeRemovedPackage"), getRelationSize("toBeChanged"),
                     getRelationSize("depends"),getRelationSize("dependChoice"),getRelationSize("conflicts"), getRelationSize("keep"), 
                     (br.time + bc.time + bo.time) / 1000000);
  Problem p = problem(br.relations, bc.const, (), bo.objSec, nothing()); 

  if (saveProblemToFile) {
    println("Saving constructed AlleAlle specification to file");
    loc alleFile = origCudf.parent + "/output/" + origCudf.file + "/opt-pack-res.alle";
    writeFile(alleFile, unparse(p));
  }

  println("Done");  
  println();
  return <p, stat>;
}

list[RelationDef] buildRelations(set[Package] universe, Request req) = buildPackageRelations(universe) + buildRequestRelations(req);
 
list[RelationDef] buildRequestRelations(Request req) {
  RelationDef installReqRel = relation("installRequest", [header("pId",id()), header("version",intDom()), header("relop",intDom())], 
                                                          exact([tup(buildChoiceTuple(pf)) | PackageFormula pf <- req.install]));

  RelationDef removeReqRel  = relation("removeRequest",  [header("pId",id()), header("version",intDom()), header("relop",intDom())], 
                                                          exact([tup(buildChoiceTuple(pf)) | PackageFormula pf <- req.remove]));

  RelationDef upgradeReqRel = relation("upgradeRequest", [header("pId",id()), header("version",intDom()), header("relop",intDom())], 
                                                          exact([tup(buildChoiceTuple(pf)) | PackageFormula pf <- req.upgrade]));
  
  return [installReqRel, removeReqRel, upgradeReqRel];
}

list[RelationDef] buildPackageRelations(set[Package] universe) {
  rel[str, Package] sortedPackages = {};
  for (Package p <- universe) {
    sortedPackages += <p.name, p>; 
  }
  
  RelationDef packageRel = relation("package", [header("pId",id())], exact([tup([idd(pName)]) | str pName <- sortedPackages<0>]));  

  list[AlleTuple] versionTups = [];
  list[AlleTuple] installedTups = [];
  list[AlleTuple] dependTups = [];
  list[AlleTuple] dependChoiceTups = [];
  list[AlleTuple] conflictTups = [];
  list[AlleTuple] toBeInstalledTups = [];
  list[AlleTuple] toBeRemovedVersionTups = [];
  list[AlleTuple] toBeRemovedPackageTups = [];
  list[AlleTuple] toBeChangedTups = [];
  
  set[set[PackageFormula]] keepForms = {};
  
  for (str pName <- sortedPackages<0>, Package p <- sortedPackages[pName]) {
    AlleValue pId = idd("<p.name>");
    AlleValue vId = idd("<p.name>_<p.version>");
    
    versionTups += tup([vId, pId, alleLit(intLit(p.version))]);
    
    for (int i <- [0..size(p.depends)]) {
      PackageFormula pf = p.depends[i];
      
      AlleValue dcId = idd("<p.name>_<p.version>_dc<i>");
            
      if (or(set[PackageFormula] clauses) := pf) {
        for (PackageFormula clause <- clauses) {
          dependChoiceTups += buildDependChoiceTuple(dcId, clause);
        }
      } else {
        dependChoiceTups += buildDependChoiceTuple(dcId, pf);
      }
      
      dependTups += tup([vId, dcId]);
    }

    for (PackageFormula pf <- p.conflicts) {
      conflictTups += buildConflictTuple(vId, pf);
    }
       
    toBeChangedTups += tup([vId]);    
    if (p.installed) {
      installedTups += tup([vId]);
      if (p.keep != version()) {
        if (tup([pId]) notin toBeRemovedPackageTups) {
          toBeRemovedPackageTups += tup([pId]);
        }       
        toBeRemovedVersionTups += tup([vId]);
      }
      
      for (normalized(set[PackageFormula] outer) := p.keep, or(set[PackageFormula] inner) <- outer) {
        set[PackageFormula] kf = {pf | PackageFormula pf <- inner};
        keepForms += {kf};
      }
      
    } else {
      toBeInstalledTups += tup([vId]);
    }
  }
  
  RelationDef versionRel = relation("version", [header("vId",id()), header("pId",id()), header("nr",intDom())], exact(versionTups));
  RelationDef installedRel = relation("installed", [header("vId",id())], exact(installedTups));
  RelationDef toBeInstalledRel = relation("toBeInstalled", [header("vId",id())], atMost(toBeInstalledTups));
  RelationDef toBeRemovedVersionRel = relation("toBeRemovedVersion", [header("vId",id())], atMost(toBeRemovedVersionTups));
  RelationDef toBeRemovedPackageRel = relation("toBeRemovedPackage", [header("pId",id())], atMost(toBeRemovedPackageTups));
  RelationDef toBeChangedRel = relation("toBeChanged", [header("vId",id())], atMost(toBeChangedTups));
  RelationDef dependsRel = relation("depends", [header("vId",id()), header("dcId",id())], exact(dependTups));
  RelationDef dependChoicesRel = relation("dependChoice", [header("dcId",id()), header("pId",id()), header("version",intDom()), header("relop",intDom())], exact(dependChoiceTups));
  RelationDef conflictRel = relation("conflicts", [header("vId",id()), header("pId",id()), header("version",intDom()), header("relop",intDom())], exact(conflictTups));
  
  list[AlleTuple] keepTups = [];
  int keepInt = 1;
  for (set[PackageFormula] forms <- keepForms) {
    for (equal(str kName, int kVersion) <- forms) {
      keepTups += tup([idd("_k<keepInt>"), idd("<kName>_<kVersion>")]);
    }
    keepInt += 1;
  }
  RelationDef keepRel = relation("keep", [header("kId",id()),header("vId",id())], exact(keepTups));
  
  return [packageRel, versionRel, installedRel, toBeInstalledRel, toBeRemovedVersionRel, toBeRemovedPackageRel, toBeChangedRel, dependsRel, dependChoicesRel, conflictRel, keepRel];
} 

AlleTuple buildDependChoiceTuple(AlleValue dcId, PackageFormula pf) = tup(dcId + buildChoiceTuple(pf));
AlleTuple buildConflictTuple(AlleValue vId, PackageFormula pf) = tup(vId + buildChoiceTuple(pf));

list[AlleValue] buildChoiceTuple(packageOnly(str name)) = [idd("<name>"), alleLit(intLit(0)), alleLit(intLit(0))]; 
list[AlleValue] buildChoiceTuple(equal(str name, int version)) = [idd("<name>"), alleLit(intLit(version)), alleLit(intLit(1))]; 
list[AlleValue] buildChoiceTuple(inequal(str name, int version)) = [idd("<name>"), alleLit(intLit(version)), alleLit(intLit(2))];
list[AlleValue] buildChoiceTuple(gte(str name, int version)) = [idd("<name>"), alleLit(intLit(version)), alleLit(intLit(3))];
list[AlleValue] buildChoiceTuple(gt(str name, int version)) = [idd("<name>"), alleLit(intLit(version)), alleLit(intLit(4))];
list[AlleValue] buildChoiceTuple(lte(str name, int version)) = [idd("<name>"), alleLit(intLit(version)), alleLit(intLit(5))];
list[AlleValue] buildChoiceTuple(lt(str name, int version)) = [idd("<name>"), alleLit(intLit(version)), alleLit(intLit(6))];

list[AlleFormula] constraints(Request req) {
  str constraints = "let installedAfter = (toBeInstalled ∪ (installed ∖ toBeRemovedVersion)) |
                    '  (∀ ir ∈ installRequest | some (ir ⨝ version ⨝ installedAfter) where ((relop = 0) || (relop = 1 && version = nr) || (relop = 2 && version != nr) || (relop = 3 && nr \>= version) || (relop = 4 && nr \> version) || (relop = 5 && nr \<= version) || (relop = 6 && nr \< version))) ∧ 
                    '  (∀ ur ∈ upgradeRequest | some (ur ⨝ version ⨝ installedAfter) where ((relop = 0) || (relop = 1 && version = nr) || (relop = 2 && version != nr) || (relop = 3 && nr \>= version) || (relop = 4 && nr \> version) || (relop = 5 && nr \<= version) || (relop = 6 && nr \< version)))
                    '
                    '∀ rr ∈ removeRequest | some (rr ⨝ version ⨝ toBeRemovedVersion) where ((relop = 0) || (relop = 1 && version = nr) || (relop = 2 && version != nr) || (relop = 3 && nr \>= version) || (relop = 4 && nr \> version) || (relop = 5 && nr \<= version) || (relop = 6 && nr \< version)) 
                    '
                    'let installedAfter = (toBeInstalled ∪ (installed ∖ toBeRemovedVersion)) |
                    '  ∀ d ∈ depends | (d[vId] ⊆ installedAfter) ⇒ let possibleInstalls = (d ⨝ dependChoice)[pId,version,relop] ⨝ (version ⨝ installedAfter) | 
                    '    (some (possibleInstalls where ((relop = 0) ||(relop = 1 && nr = version)) || (relop = 2 && nr != version) || (relop = 3 && nr \>= version) ||(relop = 4 && nr \> version) || (relop = 5 && nr \<= version) || (relop = 6 && nr \< version))[vId] ∩ installedAfter)
                    '
                    'let installedAfter = (toBeInstalled ∪ (installed ∖ toBeRemovedVersion)) |
                    '  ∀ c ∈ conflicts | (c[vId] ⊆ installedAfter) ⇒ let possibleConflicts = c[pId,version,relop] ⨝ (version ⨝ installedAfter) |
                    '    no (possibleConflicts where ((relop = 0) || (relop = 1 && nr = version) || (relop = 2 && nr != version) || (relop = 3 && nr \>= version) || (relop = 4 && nr \> version) || (relop = 5 && nr \<= version) || (relop = 6 && nr \< version))[vId] ∩ installedAfter)
                    '
                    'let installedAfter = (toBeInstalled ∪ (installed ∖ toBeRemovedVersion)) | ∀ k ∈ keep[kId] | some k ⨝ keep ⨝ installedAfter
                    '
                    '<if (req.upgrade != []) {>
                    '∀ v ∈ ((toBeInstalled ∪ (installed ∖ toBeRemovedVersion)) ⨝ version) | one (v ⨝ package) <}>
                    '
                    'toBeRemovedPackage = (toBeRemovedVersion ⨝ version)[pId] ∖ (toBeInstalled ⨝ version)[pId]
                    'toBeChanged = (toBeInstalled ∪ toBeRemovedVersion)";

  return implodeProblem(constraints).constraints;                    
}

Maybe[ObjectiveSection] constructObjectives(Request req) {
  str obj = "objectives: minimize toBeRemovedPackage[count()], minimize toBeChanged[count()]<if (req.upgrade != []) {>, maximize (toBeChanged ⨝ version)[sum(nr)]<}>"; //[pId,latestVersion/max(nr)]";

  return implodeProblem(obj).objectiveSec;
}
