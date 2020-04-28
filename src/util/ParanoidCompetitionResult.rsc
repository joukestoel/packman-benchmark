module util::ParanoidCompetitionResult

import IO;
import ValueIO;
import lang::html::IO;
import List;
import String;
import util::Math;

data CompetitionResult 
  = satResult(int nrOfRemovals, int nrOfChanges, int winningTime)
  | unsatResult()
  ;
  
void scrapeResultPage() {
  map[str, CompetitionResult] results = ();
  
  page = readHTMLFile(|http://www.mancoosi.org/misc-2012/results/paranoid/|);
  if (/"div"([*_,"table"(list[node] tbodies, border="1")], id = "Center") := page) {
    
    for (/"tr"(["td"(["a"(["text"(str currentFile)], href=_)]),*otherTds]) := tbodies, /^.*[\/]<file:.*>$/ := currentFile) {
      if (/"td"(["text"(str result),*_],class="winsat") := otherTds, /^[\[][-]?<nrOfRemovals:[0-9]+>[,][-]?<nrOfChanges:[0-9]+>.*[\<]<winningTime:.*>[\>]$/ := trim(result)) {
        results[file] = satResult(toInt(nrOfRemovals), toInt(nrOfChanges), round(toReal(winningTime) * 1000));
      } else if (/"td"(_, class="fail") := otherTds) {
        results[file] = unsatResult();
      }
    }
  }
  
  writeBinaryValueFile(|project://packman-benchmark/lib/competionresults.bin|, results);
}

map[str,CompetitionResult] getCompetitionResults() {
  loc compResultsFile = |project://packman-benchmark/lib/competionresults.bin|;
  if (!exists(compResultsFile)) {
    scrapeResultPage();
  }
  
  return readBinaryValueFile(#map[str,CompetitionResult], compResultsFile);
}
