module cudf::Unparser

import cudf::AST;

import List;

str unparse(list[Package] packages, Request req) =
  "<for (p <- packages) {>
  '<unparse(p)>
  '<}>
  '<unparse(req)>";

str unparse(set[Package] packages) =
  "<for (p <- packages) {>
  '<unparse(p)>
  '<}>";  

str unparse(package(str name, int version, list[PackageFormula] depends, list[PackageFormula] conflicts, list[PackageFormula] provides, bool installed, KeepValue keep, str number)) =
  "package: <name>
  'version: <version>
  'number: <number>
  'depends: <intercalate(",", [unparse(f) | f <- depends])>
  'conflicts: <intercalate(",", [unparse(f) | f <- conflicts])>
  'provides: <intercalate(",", [unparse(f) | f <- provides])>
  'installed: <installed ? "true" : "false">
  'keep: <unparse(keep)>";
  
str unparse(request(str name, list[PackageFormula] install, list[PackageFormula] remove,  list[PackageFormula] upgrade)) =
  "request: <name>
  'install: <intercalate(",", [unparse(f) | f <- install])>
  'remove: <intercalate(",", [unparse(f) | f <- remove])>
  'upgrade: <intercalate(",", [unparse(f) | f <- upgrade])>";
  
str unparse(packageOnly(str name)) = name;
str unparse(equal(str name, version)) = "<name> = <version>";
str unparse(inequal(str name, version)) = "<name> != <version>";
str unparse(gte(str name, version)) = "<name> \>= <version>";
str unparse(gt(str name, version)) = "<name> \> <version>";
str unparse(lte(str name, version)) = "<name> \<= <version>";
str unparse(lt(str name, version)) = "<name> \< <version>";
str unparse(or(set[PackageFormula] forms)) = "<intercalate(" | ", [unparse(f) | f <- forms])>";

str unparse(version()) = "version";
str unparse(package()) = "package";
str unparse(feature()) = "feature";
str unparse(none()) = "none";
str unparse(normalized(set[PackageFormula] forms)) = "<intercalate(" | ", [unparse(f) | f<- forms])>";