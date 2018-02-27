module cudf::AST

data Package = package(str name, int version, list[PackageFormula] depends, list[PackageFormula] conflicts, list[PackageFormula] provides, bool installed, KeepValue keep);

data Request = request(str name, list[RequestProperty] properties);

data PackageProperty 
  = version(int version)
  | depends(list[PackageFormula] formulas)
  | conflicts(list[PackageFormula] formulas)
  | provides(list[PackageFormula] formulas)
  | installed(bool b)
  | keep(KeepValue kv)
  ;

data RequestProperty
  = install(list[PackageFormula] formulas)
  | remove(list[PackageFormula] formulas)
  | upgrade(list[PackageFormula] formulas)
  ;

data PackageFormula 
  = packageOnly(str name)
  | equal(str name, int version)
  | inequal(str name, int version)
  | gte(str name, int version)
  | gt(str name, int version)
  | lte(str name, int version)
  | lt(str name, int version)
  | or(set[PackageFormula] forms)  
  ;

PackageFormula or(PackageFormula lhs, or(set[PackageFormula] others)) = or({lhs,*others});
PackageFormula or(or(set[PackageFormula] others), PackageFormula rhs) = or({rhs,*others});
default PackageFormula or(PackageFormula lhs, PackageFormula rhs) = or({lhs,rhs});

data KeepValue 
  = version() 
  | package() 
  | feature()
  | none()
  ;