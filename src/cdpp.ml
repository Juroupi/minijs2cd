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
  
  and print_declaration name =
    Printf.fprintf out "let %s = ref (Value) `undefined in\n" name
  
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
      print_statements [ s2 ];
      Printf.fprintf out ") else (\n";
      print_statements [ s1 ];
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

  and print_expression = function
    | IdentifierExpression "Object" ->
      (* conflit : l'identifiant "Object" correspond à un type dans objects.cd *)
      Printf.fprintf out "(!__Object__)"
    | IdentifierExpression id ->
      Printf.fprintf out "(!%s)" id
    | ThisExpression ->
      Printf.fprintf out "this"
    | NumberExpression n ->
      Printf.fprintf out "(float_of \"%s\")" n
    | BigIntExpression n ->
      Printf.fprintf out "%s" n
    | StringExpression s ->
      Printf.fprintf out "\"%s\"" s
    | BooleanExpression true ->
      Printf.fprintf out "`true"
    | BooleanExpression false ->
      Printf.fprintf out "`false"
    | NullExpression ->
      Printf.fprintf out "`null"
    | UndefinedExpression ->
      Printf.fprintf out "`undefined"
    | AssignmentExpression (name, value) ->
      Printf.fprintf out "(let tmp = ";
      print_expression value;
      Printf.fprintf out " in %s := tmp; tmp)" name
    | MemberAccessExpression (obj, "__proto__") ->
      Printf.fprintf out "(get_prototype_of (";
      print_expression obj;
      Printf.fprintf out "))"
    | MemberAccessExpression (obj, member) ->
      Printf.fprintf out "(get_property (";
      print_expression obj;
      Printf.fprintf out ") __%s_prop__" member;
      Printf.fprintf out ")"
    | MemberAssignmentExpression (obj, "__proto__", value) ->
      Printf.fprintf out "(set_prototype_of (";
      print_expression obj;
      Printf.fprintf out ") (";
      print_expression value;
      Printf.fprintf out "))"
    | MemberAssignmentExpression (obj, member, value) ->
      Printf.fprintf out "(set_property (";
      print_expression obj;
      Printf.fprintf out ") __%s_prop__" member;
      Printf.fprintf out " (";
      print_expression value;
      Printf.fprintf out "))"
    | DeleteExpression (_, "") ->
      Printf.fprintf out "`true"
    | DeleteExpression (obj, member) ->
      Printf.fprintf out "(delete_property (";
      print_expression obj;
      Printf.fprintf out ") __%s_prop__)" member
    | MethodCallExpression (IdentifierExpression "console", "log", params) ->
      Printf.fprintf out "(print_sequence ";
      print_sequence params;
      Printf.fprintf out ")"
    | MethodCallExpression (obj, member, params) ->
      Printf.fprintf out "(let o = ";
      print_expression obj;
      Printf.fprintf out " in call (get_property o __%s_prop__) o " member;
      print_sequence params;
      Printf.fprintf out ")"
    | CallExpression (f, params) ->
      Printf.fprintf out "(call (";
      print_expression f;
      Printf.fprintf out ") global_this ";
      print_sequence params;
      Printf.fprintf out ")"
    | ObjectExpression properties ->
      Printf.fprintf out "{ properties = (ref {..} {";
      List.iter (fun (name, value) ->
        Printf.fprintf out " %s = (" name;
        print_expression value;
        Printf.fprintf out ")"
      ) properties;
      Printf.fprintf out "}) ";
      Printf.fprintf out "prototype = (ref (Object | `null) object_prototype) ";
      Printf.fprintf out "}"
    | FunctionExpression ([], body) ->
      Printf.fprintf out "{ ";
        Printf.fprintf out "properties = (ref {..} {}) ";
        Printf.fprintf out "prototype = (ref (Object | `null) function_prototype) ";
        Printf.fprintf out "call = (fun (this : Value) (_ : [Value*]) : Value = ";
          Printf.fprintf out "let _ = this in try\n";
            print_block body;
          Printf.fprintf out "with (`return, r & Value) -> r) ";
      Printf.fprintf out "}"
    | FunctionExpression (params, body) ->
      Printf.fprintf out "{ ";
        Printf.fprintf out "properties = (ref {..} {}) ";
        Printf.fprintf out "prototype = (ref (Object | `null) function_prototype) ";
        Printf.fprintf out "call = (fun (this : Value) (params : [Value*]) : Value = ";
          Printf.fprintf out "let _ = this in ";
          Printf.fprintf out "let f = fun ";
          List.iter (Printf.fprintf out "(%s : ref (Value)) ") params;
          Printf.fprintf out " : Value = ";
            Printf.fprintf out "try\n";
            print_block body;
            Printf.fprintf out "with (`return, r & Value) -> r";
          Printf.fprintf out " in match params with";
          print_params_pattern params;
        Printf.fprintf out ") ";
      Printf.fprintf out "}"
  
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