module util::Diff

import cudf::AST;
import cudf::CudfReader;

import IO;

void diff(loc leftCudf, loc rightCudf) {
  rel[str,int] leftPackages  = {<p.name,p.version> | p <- readAndParseCudfFile(leftCudf).packages};
  rel[str,int] rightPackages =  {<p.name,p.version> | p <- readAndParseCudfFile(rightCudf).packages};
  
  println("In \'<leftCudf>\' but not in \'<rightCudf>\'");
  for (<str pack, int ver> <- leftPackages, /<pack,ver> !:= rightPackages) {
    println("*  <pack> (<ver>)");
  }
  
  println("In \'<rightCudf>\' but not in \'<leftCudf>\'");
  for (<str pack, int ver> <- rightPackages, /<pack,ver> !:= leftPackages) {
    println("*  <pack> (<ver>)");
  }
}