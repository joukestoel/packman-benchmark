module cudf::Syntax

extend lang::std::Whitespace;

start syntax CUDF = Preamble? preamble Universe universe Request request;

syntax Preamble = "preamble" ":" Stanza stanza;

syntax Universe = Package* packages;

syntax Package = "package" ":" PackageName name PackageStanza stanza;

syntax Request = "request" ":" String name RequestStanza stanza;

syntax PackageStanza = PackageProperty* properties;
syntax RequestStanza = RequestProperty* properties;

syntax PackageProperty 
  = "version" ":" Int version
  | "depends" ":" {PackageFormula  ","}* formulas
  | "conflicts" ":" {PackageFormula ","}* formulas
  | "provides" ":" {PackageFormula ","}* formulas
  | "installed" ":" Bool b
  | "keep" ":" KeepValue kv 
  | "number" ":" String nr
  ;
  
syntax KeepValue 
  = "version" 
  | "package" 
  | "feature" 
  | "none"
  ;

syntax RequestProperty
  = "install" ":" {PackageFormula ","}* formulas
  | "remove" ":" {PackageFormula ","}* formulas
  | "upgrade" ":" {PackageFormula ","}* formulas
  ;

syntax PackageFormula 
  = PackageName name
  > PackageName name "=" Int version
  | PackageName name "!=" Int version
  | PackageName name "\>=" Int version
  | PackageName name "\>" Int version
  | PackageName name "\<=" Int version
  | PackageName name "\<" Int version
  > left PackageFormula lhs "|" PackageFormula rhs  
  ;

lexical PackageName = ([A-Za-z./@()%0-9] !<< [A-Za-z./@()%0-9][A-Za-z0-9\-+./@()%]* !>> [A-Za-z0-9\-+./@()%]) \ Int;
  
//lexical Id = [a-z] !<< [a-z][a-z0-9\-]* !>> [a-zA-Z\-];

lexical Bool = "true" | "false";
lexical Int = [+\-]?[0-9]+ !>> [0-9];
lexical String = ![\n\r]*;

layout Standard 
  = WhitespaceOrComment* !>> [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] !>> "//";
  
lexical Comment = @lineComment @category="Comment" "#" ![\n\r]* $;  

lexical WhitespaceOrComment 
  = whitespace: Whitespace
  | comment: Comment
  ; 

