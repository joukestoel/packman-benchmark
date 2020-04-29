module cudf::CudfReader

import cudf::AST;
import cudf::Parser;

import IO;
import ValueIO;
import List;
import String;

import util::Benchmarking;
import util::Statistics;
import util::Progress;

@memo
set[str] properties() = {"package","version","depends","conflicts","provides","installed","keep","number"};

alias ParsedFileContent = tuple[list[Package] packages, Request req, Statistic stats];

ParsedFileContent readAndParseCudfFile(loc file) {
  loc binFile = file.parent + "/output/" + file.file + "/parsed.bin";
  
  println("PART 1 (of 6): Reading and parsing CUDF file");
  if (exists(binFile)) {
    println("Existing bin file with parsed packages found. Reading that");
    println();
    
    return readBinaryValueFile(#ParsedFileContent, binFile);        
  } else {
    println("Reading raw CUDF file (No existing bin file with parsed packages found)");
    
    println("Reading CUDF file");
    tuple[str content, int time] rf = bm(readFile, file);

    str lineEnding = findLineEnding(rf.content);

    println("Splitting raw CUDF file in seperate stanzas");
    tuple[list[str] parts, int time] sonl = bm(splitOnNewLines, rf.content, lineEnding);
    
    tuple[tuple[list[str] packages, str request] cat, int time] sp = bm(splitParts, sonl.parts, lineEnding);
  
    tuple[list[Package] parsedPackages, int time] pp = bm(parsePackages, sp.cat.packages);
    
    Request req = parseRequest(sp.cat.request);
    
    Statistic stats = parsing(size(sp.cat.packages), req has install && req.install != [], req has remove && req.remove != [], req has upgrade && req.upgrade != [], (rf.time + sonl.time + sp.time + pp.time) / 1000000);
    
    println("Saving imploded result as binary file");
    writeBinaryValueFile(binFile, <pp.parsedPackages, req, stats>);
    println();
        
    return <pp.parsedPackages, req, stats>;
  }  
}

str findLineEnding(str content) {
  // Three different possibilities
  // 1: Unix style '\n'
  // 2: Windows style '\r\n'
  // 3: Old, weird style '\r'
  int r = findFirst(content, "\r");
  int n = findFirst(content, "\n");
  
  switch (<r,n>) {
    case <-1,_>: return "\n";
    case <_,-1>: return "\r"; 
    case <i,j>:  return j == i + 1 ? "\r\n" : "\n";
    default: throw "Unable to determine line ending character";
  }
}

Request parseRequest(str req) = parseAndImplodeRequest(req) when trim(req) != "";
default Request parseRequest(str req) = noRequest(); 

list[Package] parsePackages(list[str] packages) {
  list[Package] parsedPackages = [];
  int nrOfPackages = size(packages);
  
  pb = progressBar(nrOfPackages, length = 15, limit = 100, prefix = "Parsing filtered stanzas\t");
  
  for (int i <- [0..nrOfPackages]) {
    pb.report("<i> of <nrOfPackages>");
    try {
      parsedPackages += parseAndImplodePackage(packages[i]);
    } catch: {
      println(packages[i]);
      fail;
    } 
  }
  
  pb.finished();

  return parsedPackages;
}

list[str] splitOnNewLines(str content, str lineEnding) = [trim(p) | str p <- split("<lineEnding><lineEnding>",content)];

tuple[list[str] packages, str request] splitParts(list[str] parts, str lineEnding) {
  list[str] packages = [];
  str request = "";
  
  int i = 0;
  int nrOfParts = size(parts);
  pb = progressBar(nrOfParts, length = 15, limit = 100, prefix = "Reading different stanzas\t");

  for (str part <- parts) {
    i += 1;
    pb.report("<i> of <nrOfParts>");
    if (startsWith(part, "preamble:")) {
      ;// do nothing
    }
    else if (startsWith(part, "package:")) {
      packages += filterPackage(part, lineEnding);
    } else if (startsWith(part, "request:")) {
      request = trim(part);
    } else if (startsWith(part, "#")) {
      ; // comment, skip
    } else {
      throw "Unreckognizable part; not a package and not a request. Content: <part>";
    }
  }
  pb.finished();
  
  return <packages,request>;
} 

str filterPackage(str package, str lineEnding) {  
  str filtered = "";
  
  for (str prop <- split("\n",package), keepProperty(split(":",prop)[0])) {
    filtered += "<prop><lineEnding>";
  }

  return trim(filtered);
}

bool keepProperty(str prop) = prop in properties(); 
