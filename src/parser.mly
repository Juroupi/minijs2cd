%{
  open Minijs

  module StringSet = Set.Make(String)

  let all_properties = ref StringSet.empty

  let add_property name =
    all_properties := StringSet.add name !all_properties
  
  let make_typed_expression value = { value_type = AnyType; value }

  let make_object_expression properties =
    let prototype, properties =
      List.fold_right (fun (name, value) (prototype, properties) ->
        match name with
        | "__proto__" -> (Some value, properties)
        | _ -> (prototype, (name, value) :: properties)
      ) properties (None, [])
    in ObjectExpression (prototype, properties)

  let empty_statement =
    BlockStatement { declarations = []; statements = []; }

%}

%token EOF LPAR RPAR LBRACE RBRACE COLON SEMI COMMA DOT EQUAL PLUS
%token TRUE FALSE NULL UNDEFINED FUNCTION LET DELETE RETURN THIS
%token IF ELSE WHILE TYPEOF IN EQUALITY INEQUALITY SEQUALITY SINEQUALITY
%token <string> STRING
%token <string> NUMBER
%token <string> BIGINT
%token <string> IDENT

%nonassoc NOELSE
%nonassoc ELSE

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
| body=block EOF { { properties = StringSet.elements !all_properties; body; globals = [] } }
;

block:
| block=list(statement) { 
    let names, statements = List.split block in
    let declarations = List.filter_map (fun d -> d) names in
    if List.length (StringSet.elements (StringSet.of_list declarations)) <> List.length declarations then
      failwith "SyntaxError";
    let declarations = List.map (fun name -> { name; total_type = AnyType }) declarations in
    { declarations; statements; }
  }
;

statement:
| e=non_statement_typed_expression SEMI { None, ExpressionStatement e }
| LET name=IDENT EQUAL value=typed_expression SEMI { Some name, DeclarationStatement (name, value) }
| LET name=IDENT SEMI { Some name, DeclarationStatement (name, make_typed_expression UndefinedExpression) }
| RETURN e=typed_expression SEMI { None, ReturnStatement e }
| LBRACE body=block RBRACE { None, BlockStatement body }
| IF LPAR cond=typed_expression RPAR s1=statement ELSE s2=statement { None, IfStatement (cond, snd s1, snd s2) }
| IF LPAR cond=typed_expression RPAR s1=statement %prec NOELSE { None, IfStatement (cond, snd s1, empty_statement) }
| WHILE LPAR cond=typed_expression RPAR s=statement { None, WhileStatement (cond, snd s) }
;

non_statement_typed_expression:
| LPAR e=typed_expression RPAR { e }
| e=non_statement_expression { make_typed_expression e }
;

non_statement_expression:
| id=IDENT { IdentifierExpression id }
| THIS { ThisExpression }
| n=NUMBER { NumberExpression n }
| n=BIGINT { BigIntExpression n }
| s=STRING { StringExpression s }
| TRUE { BooleanExpression true }
| FALSE { BooleanExpression false }
| NULL { NullExpression }
| UNDEFINED { UndefinedExpression }
| TYPEOF e=typed_expression { TypeofExpression e }
| e1=non_statement_typed_expression op=binary_operator e2=typed_expression { BinaryExpression (e1, op, e2) }
| name=STRING IN obj=typed_expression { add_property name; InExpression (name, obj) }
| name=IDENT EQUAL value=typed_expression { AssignmentExpression (name, value) }
| obj=non_statement_typed_expression DOT name=IDENT { add_property name; MemberAccessExpression (obj, name) }
| obj=non_statement_typed_expression DOT name=IDENT EQUAL value=typed_expression { add_property name; MemberAssignmentExpression (obj, name, value) }
| DELETE e=typed_expression { match e with { value = MemberAccessExpression (obj, name) } -> add_property name; DeleteExpression (obj, name) | _ -> DeleteExpression (e, "") }
| f=non_statement_typed_expression LPAR params=separated_list(COMMA, typed_expression) RPAR { match f with { value = MemberAccessExpression (obj, member) } -> add_property member; MethodCallExpression (obj, member, params) | _ -> CallExpression (f, params) }
| FUNCTION LPAR params=separated_list(COMMA, IDENT) RPAR LBRACE body=block RBRACE { FunctionExpression (params, body) }
;

typed_expression:
| LPAR e=typed_expression RPAR { e }
| e=expression { make_typed_expression e }
;

expression:
| id=IDENT { IdentifierExpression id }
| THIS { ThisExpression }
| n=NUMBER { NumberExpression n }
| n=BIGINT { BigIntExpression n }
| s=STRING { StringExpression s }
| TRUE { BooleanExpression true }
| FALSE { BooleanExpression false }
| NULL { NullExpression }
| UNDEFINED { UndefinedExpression }
| TYPEOF e=typed_expression { TypeofExpression e }
| e1=typed_expression op=binary_operator e2=typed_expression { BinaryExpression (e1, op, e2) }
| name=STRING IN obj=typed_expression { add_property name; InExpression (name, obj) }
| name=IDENT EQUAL value=typed_expression { AssignmentExpression (name, value) }
| obj=typed_expression DOT name=IDENT { add_property name; MemberAccessExpression (obj, name) }
| obj=typed_expression DOT name=IDENT EQUAL value=typed_expression { add_property name; MemberAssignmentExpression (obj, name, value) }
| DELETE e=typed_expression { match e with { value = MemberAccessExpression (obj, name) } -> add_property name; DeleteExpression (obj, name) | _ -> DeleteExpression (e, "") }
| f=typed_expression LPAR params=separated_list(COMMA, typed_expression) RPAR { match f with { value = MemberAccessExpression (obj, member) } -> add_property member; MethodCallExpression (obj, member, params) | _ -> CallExpression (f, params) }
| FUNCTION LPAR params=separated_list(COMMA, IDENT) RPAR LBRACE body=block RBRACE { FunctionExpression (params, body) }
| LBRACE properties=separated_list(COMMA, separated_pair(IDENT, COLON, typed_expression)) RBRACE { make_object_expression properties }
;

%inline binary_operator:
| EQUALITY { EqualityOperator true }
| INEQUALITY { EqualityOperator false }
| SEQUALITY { StrictEqualityOperator true }
| SINEQUALITY { StrictEqualityOperator false }
| PLUS { AdditionOperator }
;