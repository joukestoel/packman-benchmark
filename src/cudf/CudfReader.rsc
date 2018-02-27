module cudf::CudfReader

import cudf::AST;
import cudf::Parser;

import IO;
import ValueIO;
import List;
import String;

import util::Benchmarking;

@memo
list[str] properties() = ["package","version","depends","conflicts","provides","installed","keep"];

alias ParsedFileContent = tuple[list[Package] packages, Request req];

ParsedFileContent readAndParseCudfFile(loc file) {
  if (exists(file[extension="bin"])) {
    println("Existing bin file found.");
    
    return readBinaryValueFile(#ParsedFileContent, file[extension="bin"]);
        
  } else {
    println("No existing bin file found. Reading raw CUDF file.");
    
    tuple[str content, int time] rf = bmWithPrint("Reading CUDF file", readFile, file);
    tuple[list[str] parts, int time] sonl = bmWithPrint("Splinting raw CUDF file in seperate stanzas", splitOnNewLines, rf.content);
    println("Total nr of stanzas: <size(sonl.parts)>");
    
    tuple[tuple[list[str] packages, str request] cat, int time] sp = bmWithPrint("Reading and filtering the different properties", splitParts, sonl.parts);
    println("Nr of packages: <size(sp.cat.packages)>");
  
    tuple[list[Package] parsedPackages, int time] pp = bm(parsePackages, sp.cat.packages);
    println("Parsing and imploding took <pp.time / 1000000> ms");
    
    Request req = parseRequest(sp.cat.request);
    
    int saveTime = bmWithPrint("Saving imploded result as binary file", writeBinaryValueFile, file[extension="bin"], <pp.parsedPackages, req>);
    
    return <pp.parsedPackages, req>;
  }  
}

Request parseRequest(str req) = parseAndImplodeRequest(req);

list[Package] parsePackages(list[str] packages) {
  print("Start parsing packages");
  
  list[Package] parsedPackages = [];
  int size = size(packages);
  for (int i <- [0..size]) {
    if (i % (size / 10) == 0) {
      print("...<i / (size / 100)>%");
    }
     
    try {
      parsedPackages += parseAndImplodePackage(packages[i]);
    } catch ex: {
      println(packages[i]);
      fail;
    } 
  }
  
  print("..done\n");
  
  return parsedPackages;
}

list[str] splitOnNewLines(str content) = strippedParts
  when list[str] strippedParts := [trim(p) | str p <- split("\n\n",content)];

tuple[list[str] packages, str request] splitParts(list[str] parts) {
  list[str] packages = [];
  str request = "";
  
  for (str part <- parts) {
    if (startsWith(part, "preamble:")) {
      ;// do nothing
    }
    else if (startsWith(part, "package:")) {
      packages += filterPackage(part);
    } else if (startsWith(part, "request:")) {
      request = part;
    } else {
      throw "Unreckognizable part; not a package and not a request. Content: <part>";
    }
  }
  
  return <packages,request>;
} 

str filterPackage(str package) {  
  str filtered = "";
  
  for (str prop <- split("\n",package), keepProperty(split(":",prop)[0])) {
    filtered += "<prop>\n";
  }

  return trim(filtered);
}


bool keepProperty(str prop)  {
  for (str p <- properties(), prop == p) {
    return true;
  }
  
  return false;
}