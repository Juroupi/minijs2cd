module StringMap = Map.Make(String)
module StringSet = Set.Make(String)

type prog = {
  properties : string list;
  body : block;
  mutable globals : (string * value_type) list;
}

and declaration = {
  name : string;
  mutable total_type : value_type;
}

and block = {
  declarations : declaration list;
  statements : statement list;
}

and statement =
  | ExpressionStatement of typed_expression
  | DeclarationStatement of string * typed_expression
  | ReturnStatement of typed_expression
  | BlockStatement of block
  | IfStatement of typed_expression * statement * statement
  | WhileStatement of typed_expression * statement

and expression =
  | IdentifierExpression of string
  | ThisExpression
  | NumberExpression of string
  | BigIntExpression of string
  | StringExpression of string
  | BooleanExpression of bool
  | BinaryExpression of typed_expression * binary_operator * typed_expression
  | NullExpression
  | UndefinedExpression
  | TypeofExpression of typed_expression
  | InExpression of string * typed_expression
  | AssignmentExpression of string * typed_expression
  | MemberAccessExpression of typed_expression * string
  | MemberAssignmentExpression of typed_expression * string * typed_expression
  | DeleteExpression of typed_expression * string
  | ObjectExpression of typed_expression option * (string * typed_expression) list
  | CallExpression of typed_expression * typed_expression list
  | MethodCallExpression of typed_expression * string * typed_expression list
  | FunctionExpression of string list * block

and value_type =
  | NoneType
  | AnyType
  | NumberType
  | BigIntType
  | StringType
  | BooleanType of bool option
  | NullType
  | UndefinedType
  | ObjectType of object_type
  | FunctionType of object_type
  | UnionType of value_type * value_type

and object_type = {
  mutable proto : value_type;
  mutable props : value_type StringMap.t;
  mutable optprops : StringSet.t;
}

and typed_expression = {
  mutable value_type : value_type;
  value : expression;
}

and binary_operator =
  | EqualityOperator of bool
  | StrictEqualityOperator of bool
  | AdditionOperator