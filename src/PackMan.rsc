module PackMan

import cudf::CudfReader;
import cudf::Normalizer;
import cudf::AST;

void performRequest(loc cudf) {
  ParsedFileContent pfc = readAndParseCudfFile(cudf);
  normalize(pfc.packages, pfc.req);
  
}
