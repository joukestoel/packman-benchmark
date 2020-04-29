module PackMan

import cudf::CudfReader;
import cudf::Normalizer;
import cudf::Slicer;
import cudf::ProblemBuilder;
import cudf::ModelFinder;
import cudf::SolutionChecker;

import util::Statistics;

import IO;

void runAllFilesInDir(loc problemDir) {
  if (!isDirectory(problemDir)) {
    throw "Supplied location must be a directory";
  }

  str failureLog = "";
  loc resultsDir = problemDir + "/result/";
  Statistics stats = ();
  
  for (str file <- listEntries(problemDir), (problemDir + file).extension == "cudf") {
    try {
      stats[file] = performRequest(problemDir + file);
      saveToCSV(stats, resultsDir + "results.csv");
    } catch ex: {
      failureLog += "Unable to perform request for file \'<file>\', reason: <ex>\n";
      writeFile(resultsDir + "failures.log", failureLog);
    }
  }
}

// Point the cudfSolCheckerExec to your locally build version of the cudf checker
Statistic performRequest(loc cudf, str cudfSolCheckerExec = "/Users/jouke/workspace/packman-benchmark/lib/main_cudf_check.native") {
  println("Start checking \'<cudf>\'");
  println();
  
  ParsedFileContent pfc     = readAndParseCudfFile(cudf);
  NormalizedFileContent nfc = normalize(cudf, pfc.packages, pfc.req);
  SlicedFileContent sfc     = slice(cudf, nfc.packages, nfc.req);
  ProblemBuilderResult pbr  = buildProblem(cudf, sfc.packages, sfc.req, saveProblemToFile = false); 
  FindModelResult fmr       = findSolution(cudf, pbr.problem);
  SolutionCheckerResult scr = checkSolution(cudf, fmr.sat, pfc.packages, fmr.toBeInstalled, fmr.toBeRemoved,cudfSolCheckerExec, checkExternalCorrectness = true);

  println("Done checking \'<cudf>\'");
  println();    
  return complete(pfc.stats, nfc.stats, sfc.stats, pbr.stats, fmr.stats, scr.stats);
}
