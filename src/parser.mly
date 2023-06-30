%{
  open Minijs

  module StringSet = Set.Make(String)

  let all_properties = ref StringSet.empty

  let add_property name =
    all_properties := StringSet.add name !all_properties
%}

%token EOF LPAR RPAR LBRACE RBRACE COLON SEMI COMMA DOT EQUAL PLUS
%token TRUE FALSE NULL UNDEFINED FUNCTION LET DELETE RETURN THIS
%token IF ELSE WHILE TYPEOF IN EQUALITY INEQUALITY SEQUALITY SINEQUALITY
%token <string> STRING
%token <string> NUMBER
%token <string> BIGINT
%token <string> IDENT

%right EQUAL
%left EQUALITY INEQUALITY SEQUALITY SINEQUALITY
%left IN
%left PLUS
%nonassoc DELETE TYPEOF
%nonassoc LPAR
%left DOT

%start prog
%type <Minijs.prog> prog

%%

prog:
| body=block EOF { { properties = StringSet.elements !all_properties; body; } }
;

block:
| block=list(statement) { 
    let names, statements = List.split block in
    let declarations = List.filter_map (fun d -> d) names in
    if List.length (StringSet.elements (StringSet.of_list declarations)) <> List.length declarations then
      failwith "SyntaxError";
    { declarations; statements; }
  }
;

statement:
| e=non_statement_expression SEMI { None, ExpressionStatement e }
| LET name=IDENT EQUAL value=expression SEMI { Some name, DeclarationStatement (name, value) }
| LET name=IDENT SEMI { Some name, DeclarationStatement (name, UndefinedExpression) }
| RETURN e=expression SEMI { None, ReturnStatement e }
| LBRACE body=block RBRACE { None, BlockStatement body }
| IF LPAR cond=expression RPAR s1=statement ELSE s2=statement { None, IfStatement (cond, snd s1, snd s2) }
| WHILE LPAR cond=expression RPAR s=statement { None, WhileStatement (cond, snd s) }
;

non_statement_expression:
| LPAR e=expression RPAR { e }
| id=IDENT { IdentifierExpression id }
| THIS { ThisExpression }
| n=NUMBER { NumberExpression n }
| n=BIGINT { BigIntExpression n }
| s=STRING { StringExpression s }
| TRUE { BooleanExpression true }
| FALSE { BooleanExpression false }
| NULL { NullExpression }
| UNDEFINED { UndefinedExpression }
| TYPEOF e=expression { TypeofExpression e }
| e1=non_statement_expression op=binary_operator e2=expression { BinaryExpression (e1, op, e2) }
| name=STRING IN obj=expression { add_property name; InExpression (name, obj) }
| name=IDENT EQUAL value=expression { AssignmentExpression (name, value) }
| obj=non_statement_expression DOT name=IDENT { add_property name; MemberAccessExpression (obj, name) }
| obj=non_statement_expression DOT name=IDENT EQUAL value=expression { add_property name; MemberAssignmentExpression (obj, name, value) }
| DELETE e=expression { match e with MemberAccessExpression (obj, name) -> add_property name; DeleteExpression (obj, name) | _ -> DeleteExpression (e, "") }
| f=non_statement_expression LPAR params=separated_list(COMMA, expression) RPAR { match f with MemberAccessExpression (obj, member) -> add_property member; MethodCallExpression (obj, member, params) | _ -> CallExpression (f, params) }
| FUNCTION LPAR params=separated_list(COMMA, IDENT) RPAR LBRACE body=block RBRACE { FunctionExpression (params, body) }
;

expression:
| LPAR e=expression RPAR { e }
| id=IDENT { IdentifierExpression id }
| THIS { ThisExpression }
| n=NUMBER { NumberExpression n }
| n=BIGINT { BigIntExpression n }
| s=STRING { StringExpression s }
| TRUE { BooleanExpression true }
| FALSE { BooleanExpression false }
| NULL { NullExpression }
| UNDEFINED { UndefinedExpression }
| TYPEOF e=expression { TypeofExpression e }
| e1=expression op=binary_operator e2=expression { BinaryExpression (e1, op, e2) }
| name=STRING IN obj=expression { add_property name; InExpression (name, obj) }
| name=IDENT EQUAL value=expression { AssignmentExpression (name, value) }
| obj=expression DOT name=IDENT { add_property name; MemberAccessExpression (obj, name) }
| obj=expression DOT name=IDENT EQUAL value=expression { add_property name; MemberAssignmentExpression (obj, name, value) }
| DELETE e=expression { match e with MemberAccessExpression (obj, name) -> add_property name; DeleteExpression (obj, name) | _ -> DeleteExpression (e, "") }
| f=expression LPAR params=separated_list(COMMA, expression) RPAR { match f with MemberAccessExpression (obj, member) -> add_property member; MethodCallExpression (obj, member, params) | _ -> CallExpression (f, params) }
| FUNCTION LPAR params=separated_list(COMMA, IDENT) RPAR LBRACE body=block RBRACE { FunctionExpression (params, body) }
| LBRACE properties=separated_list(COMMA, separated_pair(IDENT, COLON, expression)) RBRACE { ObjectExpression properties }
;

%inline binary_operator:
| EQUALITY { EqualityOperator true }
| INEQUALITY { EqualityOperator false }
| SEQUALITY { StrictEqualityOperator true }
| SINEQUALITY { StrictEqualityOperator false }
| PLUS { AdditionOperator }
;