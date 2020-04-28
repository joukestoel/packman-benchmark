module util::Debugger

import cudf::CudfReader;
import cudf::AST;
import cudf::Normalizer;
import cudf::Slicer;
import cudf::Unparser;

import IO;

void check(loc cudfToCheck, loc correctCudf) {
  list[Package] correctUni = readAndParseCudfFile(correctCudf).packages; 
 
  tuple[set[Package] difference, list[Package] packages] parseResult = checkAfterParse(cudfToCheck, correctUni);
  if (parseResult.difference != {}) {
    writeFile(cudfTocheck[extension = "parsing.diff"], unparse(sliceResult.difference));    
    throw "Parsing the universe produces an incorrect package constellation";
  }
  
  tuple[set[Package] difference, list[Package] packages] normalizeResult = checkAfterNormalize(cudfToCheck, parseResult.packages, correctUni); 
  if (normalizeResult.difference != {}) {
    writeFile(cudfTocheck[extension = "normalizing.diff"], unparse(sliceResult.difference));    
    throw "Normalizing produced an incorrect package constellation";
  }

  tuple[set[Package] difference, set[Package] packages] sliceResult = checkAfterSlicing(cudfToCheck, normalizeResult.packages, correctUni); 
  if (sliceResult.difference != {}) {
    writeFile(cudfToCheck[extension = "slicing.diff"], unparse(sliceResult.difference));    
    throw "Slicing produced an incorrect package constellation, saved missing packages to file";
  }
}

tuple[set[Package], list[Package]] checkAfterParse(loc cudfToCheck, list[Package] correctUni) {
  uniToCheck = readAndParseCudfFile(cudfToCheck); 
  
  set[str] packagesInUniToCheck = {"<p.name>_<p.version>" | Package p <- uniToCheck.packages};
  set[Package] incompletePackages = {p | Package p <- correctUni, "<p.name>_<p.version>" notin packagesInUniToCheck};

  return <incompletePackages, uniToCheck.packages>;  
}

tuple[set[Package], list[Package]] checkAfterNormalize(loc cudfToCheck, list[Package] packagesToNormalize, list[Package] correctUni) {
  uniToCheck = normalize(cudfToCheck, packagesToNormalize, noRequest());
  
  set[str] packagesInUniToCheck = {"<p.name>_<p.version>" | Package p <- uniToCheck.packages};
  set[Package] incompletePackages = {p | Package p <- correctUni, "<p.name>_<p.version>" notin packagesInUniToCheck};

  return <incompletePackages, uniToCheck.packages>;  
}

tuple[set[Package], set[Package]] checkAfterSlicing(loc cudfToCheck, list[Package] packagesToSlice, list[Package] correctUni) {
  uniToCheck = slice(cudfToCheck, packagesToSlice, noRequest());
  
  set[str] packagesInUniToCheck = {"<p.name>_<p.version>" | Package p <- uniToCheck.packages};
  set[Package] incompletePackages = {p | Package p <- correctUni, "<p.name>_<p.version>" notin packagesInUniToCheck};

  return <incompletePackages, uniToCheck.packages>;  
}


void checkProblem() = check(|file:///Users/jouke/workspace/packman-benchmark/examples/debug/ab9005be-bacc-11e0-b0f6-00163e1e087d.cudf|, 
                            |file:///Users/jouke/workspace/packman-benchmark/examples/debug/ab9005be-bacc-11e0-b0f6-00163e1e087d.cudf.result|);
                                      