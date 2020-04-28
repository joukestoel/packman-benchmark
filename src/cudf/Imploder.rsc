module cudf::Imploder

import cudf::Syntax;
import cudf::AST;

import String;

cudf::AST::Package implode(cudf::Syntax::Package p) = package("<p.name>", getVersion(props), getDepends(props), getConflicts(props), getProvides(props), getInstalled(props), getKeepValue(props), getNumber(props))
   when list[PackageProperty] props := [implode(prop) | prop <- p.stanza.properties];
   
cudf::AST::Request implode(cudf::Syntax::Request r) = request("<r.name>", getInstallRequest(props), getRemoveRequest(props), getUpgradeRequest(props)) 
  when list[RequestProperty] props := [implode(prop) | prop <- r.stanza.properties];

int getVersion(list[PackageProperty] properties) = ver when version(int ver) <- properties;

list[PackageFormula] getDepends(list[PackageProperty] properties) = forms when depends(list[PackageFormula] forms) <- properties; 
default list[PackageFormula] getDepends(list[PackageProperty] properties) = []; 

list[PackageFormula] getConflicts(list[PackageProperty] properties) = forms when conflicts(list[PackageFormula] forms) <- properties; 
default list[PackageFormula] getConflicts(list[PackageProperty] properties) = []; 

list[PackageFormula] getProvides(list[PackageProperty] properties) = forms when provides(list[PackageFormula] forms) <- properties;
default list[PackageFormula] getProvides(list[PackageProperty] properties) = [];
 
bool getInstalled(list[PackageProperty] properties) = inst when installed(bool inst) <- properties;
default bool getInstalled(list[PackageProperty] properties) = false;

KeepValue getKeepValue(list[PackageProperty] properties) = kv when keep(KeepValue kv) <- properties;
default KeepValue getKeepValue(list[PackageProperty] properties) = KeepValue::none(); 

str getNumber(list[PackageProperty] properties) = nr when number(str nr) <- properties;
default str getNumber(list[PackageProperty] properties) = "<getVersion(properties)>"; 

 
list[PackageFormula] getInstallRequest(list[RequestProperty] properties) = forms when install(list[PackageFormula] forms) <- properties;
default list[PackageFormula] getInstallRequest(list[RequestProperty] properties) = [];

list[PackageFormula] getRemoveRequest(list[RequestProperty] properties) = forms when remove(list[PackageFormula] forms) <- properties;
default list[PackageFormula] getRemoveRequest(list[RequestProperty] properties) = [];

list[PackageFormula] getUpgradeRequest(list[RequestProperty] properties) = forms when upgrade(list[PackageFormula] forms) <- properties;
default list[PackageFormula] getUpgradeRequest(list[RequestProperty] properties) = [];
 
cudf::AST::PackageProperty implode((PackageProperty)`version: <Int v>`) = version(toInt("<v>"));
cudf::AST::PackageProperty implode((PackageProperty)`depends: <{PackageFormula ","}* formulas>`) = depends([implode(f) | f <- formulas]);
cudf::AST::PackageProperty implode((PackageProperty)`conflicts: <{PackageFormula ","}* formulas>`) = conflicts([implode(f) | f <- formulas]);
cudf::AST::PackageProperty implode((PackageProperty)`provides: <{PackageFormula ","}* formulas>`) = provides([implode(f) | f <- formulas]);
cudf::AST::PackageProperty implode((PackageProperty)`installed: <Bool b>`) = installed("<b>" == "true");
cudf::AST::PackageProperty implode((PackageProperty)`keep: <KeepValue kv>`) = keep(implode(kv));
cudf::AST::PackageProperty implode((PackageProperty)`number: <String nr>`) = number("<nr>");

cudf::AST::KeepValue implode((KeepValue)`version`) = version();
cudf::AST::KeepValue implode((KeepValue)`package`) = package();
cudf::AST::KeepValue implode((KeepValue)`feature`) = feature();
cudf::AST::KeepValue implode((KeepValue)`none`) = none();

cudf::AST::RequestProperty implode((RequestProperty)`install: <{PackageFormula ","}* formulas>`) = install([implode(f) | f <- formulas]);
cudf::AST::RequestProperty implode((RequestProperty)`remove: <{PackageFormula ","}* formulas>`) = remove([implode(f) | f <- formulas]);
cudf::AST::RequestProperty implode((RequestProperty)`upgrade: <{PackageFormula ","}* formulas>`) = upgrade([implode(f) | f <- formulas]);

cudf::AST::PackageFormula implode((PackageFormula)`<PackageName name>`) = packageOnly("<name>");
cudf::AST::PackageFormula implode((PackageFormula)`<PackageName name> = <Int version>`) = equal("<name>", toInt("<version>"));
cudf::AST::PackageFormula implode((PackageFormula)`<PackageName name> != <Int version>`) = inequal("<name>", toInt("<version>"));
cudf::AST::PackageFormula implode((PackageFormula)`<PackageName name> \>= <Int version>`) = gte("<name>", toInt("<version>"));
cudf::AST::PackageFormula implode((PackageFormula)`<PackageName name> \> <Int version>`) = gt("<name>", toInt("<version>"));
cudf::AST::PackageFormula implode((PackageFormula)`<PackageName name> \<= <Int version>`) = lte("<name>", toInt("<version>"));
cudf::AST::PackageFormula implode((PackageFormula)`<PackageName name> \< <Int version>`) = lt("<name>", toInt("<version>"));
cudf::AST::PackageFormula implode((PackageFormula)`<PackageFormula lhs> | <PackageFormula rhs>`) = or(implode(lhs), implode(rhs));
