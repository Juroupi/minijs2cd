type prog = {
  properties : string list;
  body : block;
}

and block = {
  declarations : string list;
  statements : statement list;
}

and statement =
  | ExpressionStatement of expression
  | DeclarationStatement of string * expression
  | ReturnStatement of expression
  | BlockStatement of block
  | CondStatement of expression * statement * statement

and expression =
  | IdentifierExpression of string
  | ThisExpression
  | NumberExpression of string
  | BigIntExpression of string
  | StringExpression of string
  | BooleanExpression of bool
  | NullExpression
  | UndefinedExpression
  | AssignmentExpression of string * expression
  | MemberAccessExpression of expression * string
  | MemberAssignmentExpression of expression * string * expression
  | DeleteExpression of expression * string
  | ObjectExpression of (string * expression) list
  | CallExpression of expression * expression list
  | MethodCallExpression of expression * string * expression list
  | FunctionExpression of string list * block