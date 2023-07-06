open Minijs

let print out prog =

  let rec print_prog prog =
    Printf.fprintf out "include \"../src/objects.cd\"\n";
    List.iter (fun prop ->
      Printf.fprintf out "let __%s_prop__ = " prop;
      print_property_accessor prop;
      Printf.fprintf out "\n"
    ) prog.properties;
    Printf.fprintf out "let _ = (\n";
    List.iter print_declaration prog.body.declarations;
    print_statements prog.body.statements;
    Printf.fprintf out ")"

  and print_object_init_value obj =
    Printf.fprintf out "{ uid=0 properties=(ref {";
    print_properties print_type ~optprops:obj.optprops obj.props;
    Printf.fprintf out " } {";
    print_properties print_init_value obj.props;
    Printf.fprintf out " }) prototype=(ref (";
    print_type obj.proto;
    Printf.fprintf out ") (";
    print_init_value obj.proto;
    Printf.fprintf out ")) }"

  and print_init_value = function
    | StringType -> Printf.fprintf out "\"\""
    | NumberType -> Printf.fprintf out "(float_of \"0\")"
    | BigIntType -> Printf.fprintf out "0"
    | BooleanType _ -> Printf.fprintf out "`false"
    | ObjectType obj -> print_object_init_value obj
    | FunctionType obj -> print_object_init_value obj
    | NoneType -> failwith "Cdpp.print_init_value"
    | AnyType -> Printf.fprintf out "`undefined"
    | NullType -> Printf.fprintf out "`null"
    | UndefinedType -> Printf.fprintf out "`undefined"
    | UnionType (t1, _) -> print_init_value t1
  
  and print_properties print ?(optprops = StringSet.empty) props =
    StringMap.iter (fun name value_type ->
      let opt = if StringSet.mem name optprops then "?" else "" in
      Printf.fprintf out " %s=%s(" name opt;
      print value_type;
      Printf.fprintf out ")"
    ) props;
  
  and print_object_type obj =
    Printf.fprintf out "{ uid=Int properties=(ref {";
    print_properties print_type ~optprops:obj.optprops obj.props;
    Printf.fprintf out " }) prototype=(ref (";
    print_type obj.proto;
    Printf.fprintf out ")) }"
  
  and print_type = function
    | NullType -> Printf.fprintf out "`null"
    | UndefinedType -> Printf.fprintf out "`undefined"
    | BooleanType _ -> Printf.fprintf out "Bool"
    | NumberType -> Printf.fprintf out "Float"
    | BigIntType -> Printf.fprintf out "Int"
    | StringType -> Printf.fprintf out "String"
    | ObjectType obj -> print_object_type obj
    | FunctionType obj -> print_object_type obj
    | NoneType -> Printf.fprintf out "Empty"
    | AnyType -> Printf.fprintf out "Value"
    | UnionType (t1, t2) ->
      print_type t1;
      Printf.fprintf out " | ";
      print_type t2
  
  and print_declaration { name; total_type } =
    Printf.fprintf out "let %s = ref (" name;
    print_type total_type;
    Printf.fprintf out ") (";
    print_init_value total_type;
    Printf.fprintf out ") in\n"
  
  and print_block body =
    List.iter print_declaration body.declarations;
    print_statements body.statements

  and print_statements statements =
    match statements with
    | [] ->
      Printf.fprintf out "`undefined\n"
    | ExpressionStatement e :: statements ->
      Printf.fprintf out "let _ = ";
      print_expression e;
      Printf.fprintf out " in\n";
      print_statements statements
    | DeclarationStatement (name, value) :: statements ->
      Printf.fprintf out "let _ = %s := " name;
      print_expression value;
      Printf.fprintf out " in\n";
      print_statements statements
    | ReturnStatement e :: _ ->
      Printf.fprintf out "raise (`return, ";
      print_expression e;
      Printf.fprintf out ")\n"
    | BlockStatement body :: statements ->
      Printf.fprintf out "let _ = (";
      print_block body;
      Printf.fprintf out ") in\n";
      print_statements statements
    | IfStatement (cond, s1, s2) :: statements ->
      Printf.fprintf out "let _ = (if to_boolean (";
      print_expression cond;
      Printf.fprintf out ") then (\n";
      print_statements [ s1 ];
      Printf.fprintf out ") else (\n";
      print_statements [ s2 ];
      Printf.fprintf out ")) in\n";
      print_statements statements
    | WhileStatement (cond, s) :: statements ->
      Printf.fprintf out "let _ = (fun loop (_ : []) : [] = (if to_boolean (";
      print_expression cond;
      Printf.fprintf out ") then (let _ = \n";
      print_statements [ s ];
      Printf.fprintf out "in loop []) else [])) [] in\n";
      print_statements statements
  
  and print_sequence l =
    Printf.fprintf out "[ ";
    List.iter (fun e ->
      Printf.fprintf out "(";
      print_expression e;
      Printf.fprintf out ") "
    ) l;
    Printf.fprintf out "]"
  
  and string_of_binary_operator = function
    | EqualityOperator true -> "is_loosely_equal"
    | EqualityOperator false -> "is_loosely_inequal"
    | StrictEqualityOperator true -> "is_strictly_equal"
    | StrictEqualityOperator false -> "is_strictly_inequal"
    | AdditionOperator -> "operator_add"
  
  and ignore_expression e res =
    Printf.fprintf out "(let _ = ";
    print_expression e;
    Printf.fprintf out " in %s)" res

  and print_expression te =
    match te.value, te.value_type with

    | IdentifierExpression "Object", _ ->
      (* conflit : l'identifiant "Object" correspond à un type dans objects.cd *)
      Printf.fprintf out "(!__Object__)"
    | IdentifierExpression id, _ ->
      Printf.fprintf out "(!%s)" id

    | ThisExpression, _ ->
      Printf.fprintf out "this"

    | NumberExpression n, _ ->
      Printf.fprintf out "(float_of \"%s\")" n
    | BigIntExpression n, _ ->
      Printf.fprintf out "%s" n
    | StringExpression s, _ ->
      Printf.fprintf out "\"%s\"" s
    | BooleanExpression true, _ ->
      Printf.fprintf out "`true"
    | BooleanExpression false, _ ->
      Printf.fprintf out "`false"
    | NullExpression, _ ->
      Printf.fprintf out "`null"
    | UndefinedExpression, _ ->
      Printf.fprintf out "`undefined"

    | TypeofExpression { value_type = UndefinedType }, _ ->
      Printf.fprintf out "\"undefined\""
    | TypeofExpression { value_type = NullType }, _ ->
      Printf.fprintf out "\"object\""
    | TypeofExpression { value_type = BigIntType }, _ ->
      Printf.fprintf out "\"bigint\""
    | TypeofExpression { value_type = NumberType }, _ ->
      Printf.fprintf out "\"number\""
    | TypeofExpression { value_type = StringType }, _ ->
      Printf.fprintf out "\"string\""
    | TypeofExpression { value_type = BooleanType _ }, _ ->
      Printf.fprintf out "\"boolean\""
    | TypeofExpression { value_type = FunctionType _ }, _ ->
      Printf.fprintf out "\"function\""
    | TypeofExpression { value_type = ObjectType _ }, _ ->
      Printf.fprintf out "\"object\""
    | TypeofExpression e, _ ->
      Printf.fprintf out "(type_of ";
      print_expression e;
      Printf.fprintf out ")"

    | BinaryExpression (e1, op, e2), _ ->
      Printf.fprintf out "(%s (" (string_of_binary_operator op);
      print_expression e1;
      Printf.fprintf out ") (";
      print_expression e2;
      Printf.fprintf out "))"

    | InExpression (_, obj), BooleanType (Some true) ->
      ignore_expression obj "`true"
    | InExpression (_, obj), BooleanType (Some false) ->
      ignore_expression obj "`false"    
    | InExpression (member, obj), _ ->
      Printf.fprintf out "(contains_property (";
      print_expression obj;
      Printf.fprintf out ") __%s_prop__" member;
      Printf.fprintf out ")"

    | AssignmentExpression (name, value), _ ->
      Printf.fprintf out "(let tmp = ";
      print_expression value;
      Printf.fprintf out " in %s := tmp; tmp)" name
    
    | MemberAccessExpression (obj, "__proto__"), AnyType ->
      Printf.fprintf out "(get_prototype_of (";
      print_expression obj;
      Printf.fprintf out "))"
    | MemberAccessExpression (obj, "__proto__"), _ ->
      Printf.fprintf out "(!(!(";
      print_expression obj;
      Printf.fprintf out ")).prototype)"

    | MemberAccessExpression (obj, member), _ ->
      let rec print_member_access n =
        if n <= 0 then begin
          Printf.fprintf out "(";
          print_expression obj;
          Printf.fprintf out ")"
        end else begin
          Printf.fprintf out "(!";
          print_member_access (n - 1);
          Printf.fprintf out ".prototype)"
        end
      in
      begin match obj.value_type = AnyType, Typing.mem_prop obj.value_type member with
      | false, Some mem ->
        Printf.fprintf out "((!";
        print_member_access mem;
        Printf.fprintf out ".properties).%s)" member
      | _ ->
        Printf.fprintf out "(get_property (";
        print_expression obj;
        Printf.fprintf out ") __%s_prop__" member;
        Printf.fprintf out ")"
      end

    | MemberAssignmentExpression (obj, "__proto__", value), AnyType ->
      Printf.fprintf out "(set_prototype_of (";
      print_expression obj;
      Printf.fprintf out ") (";
      print_expression value;
      Printf.fprintf out "))"
    | MemberAssignmentExpression (obj, "__proto__", value), _ ->
      Printf.fprintf out "(let tmp = ";
      print_expression value;
      Printf.fprintf out " in (";
      print_expression obj;
      Printf.fprintf out ").prototype := tmp; tmp)"
      
    | MemberAssignmentExpression ({ value_type = ObjectType _ } as obj, member, value), _ ->
      Printf.fprintf out "let tmp = ";
      print_expression obj;
      Printf.fprintf out " in tmp.properties := (!tmp.properties) + { %s=(" member;
      print_expression value;
      Printf.fprintf out ") }"
    | MemberAssignmentExpression (obj, member, value), _ ->
      Printf.fprintf out "(set_property (";
      print_expression obj;
      Printf.fprintf out ") __%s_prop__" member;
      Printf.fprintf out " (";
      print_expression value;
      Printf.fprintf out "))"

    | DeleteExpression (obj, ""), _ ->
      ignore_expression obj "`true"
    | DeleteExpression (obj, member), AnyType ->
      Printf.fprintf out "(delete_property (";
      print_expression obj;
      Printf.fprintf out ") __%s_prop__)" member
    | DeleteExpression (obj, member), _ ->
      Printf.fprintf out "(let tmp = ";
      print_expression obj;
      Printf.fprintf out " in tmp.properties := !(tmp.properties) \\ %s; `true)" member

    | MethodCallExpression ({ value = IdentifierExpression "console" }, "log", params), _ ->
      Printf.fprintf out "(print_sequence ";
      print_sequence params;
      Printf.fprintf out ")"

    | MethodCallExpression (obj, member, params), _ ->
      Printf.fprintf out "(let o = ";
      print_expression obj;
      Printf.fprintf out " in call (get_property o __%s_prop__) o " member;
      print_sequence params;
      Printf.fprintf out ")"

    | CallExpression (f, params), _ ->
      Printf.fprintf out "(call (";
      print_expression f;
      Printf.fprintf out ") global_this ";
      print_sequence params;
      Printf.fprintf out ")"

    | ObjectExpression properties, ObjectType obj ->
      Printf.fprintf out "{ uid=(new_uid []) properties=(ref {";
      print_properties print_type ~optprops:obj.optprops obj.props;
      Printf.fprintf out " } {";
      List.iter (fun (name, value) ->
        Printf.fprintf out " %s=(" name;
        print_expression value;
        Printf.fprintf out ")"
      ) properties;
      Printf.fprintf out " }) prototype=(ref (";
      print_type obj.proto;
      Printf.fprintf out ") (";
      print_init_value obj.proto;
      Printf.fprintf out ")) }"
    | ObjectExpression properties, _ ->
      Printf.fprintf out "(create_object {";
      List.iter (fun (name, value) ->
        Printf.fprintf out " %s = (" name;
        print_expression value;
        Printf.fprintf out ")"
      ) properties;
      Printf.fprintf out "} object_prototype)"

    | FunctionExpression ([], body), _ ->
      Printf.fprintf out "(create_function {} (fun (this : Value) (_ : [Value*]) : Value = ";
        Printf.fprintf out "let _ = this in try\n";
          print_block body;
        Printf.fprintf out "with (`return, r & Value) -> r))"
    | FunctionExpression (params, body), _ ->
      Printf.fprintf out "(create_function {} (fun (this : Value) (params : [Value*]) : Value = ";
        Printf.fprintf out "let _ = this in ";
        Printf.fprintf out "let f = fun ";
        List.iter (Printf.fprintf out "(%s : ref (Value)) ") params;
        Printf.fprintf out " : Value = ";
          Printf.fprintf out "try\n";
          print_block body;
          Printf.fprintf out "with (`return, r & Value) -> r";
        Printf.fprintf out " in match params with";
        print_params_pattern params;
      Printf.fprintf out "))"
  
  and print_params_pattern params =
    let rec list_rev_iter f = function
      | [] -> ()
      | elt :: l' -> list_rev_iter f l'; f elt
    in
    let rec print_params_pattern nparams dparams =
      match nparams with
      | nparam :: nparams' ->
        Printf.fprintf out " | [";
        list_rev_iter (Printf.fprintf out " %s") nparams;
        Printf.fprintf out " _* ] -> f";
        list_rev_iter (Printf.fprintf out " (ref (Value) %s)") nparams;
        List.iter (fun _ -> Printf.fprintf out " (ref (Value) `undefined)") dparams;
        print_params_pattern nparams' (nparam :: dparams)
      | _ ->
        Printf.fprintf out " | [] -> f";
        List.iter (fun _ -> Printf.fprintf out " (ref (Value) `undefined)") dparams
    in print_params_pattern (List.rev params) []

  and print_property_accessor name =
    Printf.fprintf out "%s" ("{ " ^
      "get = (fun (obj : Object) : (Value | `nil) = match !(obj.properties) with { " ^ name ^ " = " ^ name ^ " & Value ..} -> " ^ name ^ " | _ -> `nil) " ^
      "set = (fun (obj : Object) (prop : Value) : [] = obj.properties := !(obj.properties) + { " ^ name ^ " = prop }) " ^
      "delete = (fun (obj : Object) : [] = obj.properties := !(obj.properties) \\ " ^ name ^ ") }")
  in

  print_prog prog