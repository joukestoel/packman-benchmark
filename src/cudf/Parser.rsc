module cudf::Parser

import cudf::Syntax;
import cudf::AST;
import cudf::Imploder;

import ParseTree;

cudf::AST::Package parseAndImplodePackage(str p) = implode(parse(#cudf::Syntax::Package, p));
cudf::AST::Request parseAndImplodeRequest(str r) = implode(parse(#cudf::Syntax::Request, r));