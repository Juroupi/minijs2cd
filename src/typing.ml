open Minijs

let rec subtype t1 t2 =
  match t1, t2 with
  | ObjectType o1, ObjectType o2 -> o1 == o2
  | FunctionType o1, FunctionType o2 -> o1 == o2
  | UnionType (t11, t12), t2 -> subtype t11 t2 && subtype t12 t2
  | t1, UnionType (t21, t22) -> subtype t1 t21 || subtype t1 t22
  | _ -> t1 = t2

let rec make_union t1 t2 =
  match t1, t2 with
  | UnionType (t11, t12), t2 -> make_union t11 (make_union t12 t2)
  | BooleanType _, BooleanType _ -> BooleanType None
  | _ when subtype t2 t1 -> t1
  | _ when subtype t1 t2 -> t2
  | _ -> UnionType (t1, t2)


let rec mem_prop ?(n = 0) t name =
  (* None si on ne sait pas,
     -1 si on sait qu'elle n'existe pas,
     une valeur >= 0 si on sait qu'elle existe *)
  match t with
  | ObjectType { proto; optprops; props } ->
    begin match StringMap.find_opt name props with
    | Some value_type when StringSet.mem name optprops -> None
    | Some value_type -> Some n
    | None -> if proto = NullType then Some (-1) else mem_prop ~n:(n + 1) proto name
    end
  | UnionType (t1, t2) ->
    begin match mem_prop ~n t1 name, mem_prop ~n t2 name with
    | Some n1, Some n2 when n1 = n2 -> Some n1
    | _ -> None
    end
  | _ -> None

let type_prog prog =

  (* string -> value_type list ref *)
  let env = ref StringMap.empty in

  let merge_env env1 env2 =
    StringMap.merge (fun _ l1 l2 ->
      match l1, l2 with
      | None, None -> None
      | None, Some _ -> l2
      | Some _, None -> l1
      | Some { contents = l1 }, Some { contents = l2 } ->
        Some (ref (List.map2 (fun t1 t2 -> make_union t1 t2) l1 l2))
    ) env1 env2
  in

  let add_global name value_type =
    prog.globals <- (name, value_type) :: prog.globals
  in

  let add_decl ?(value_type = NoneType) name =
    match StringMap.find_opt name !env with
    | Some value_types -> value_types := value_type :: !value_types
    | None -> env := StringMap.add name (ref [ value_type ]) !env
  in

  let remove_decl name =
    match StringMap.find_opt name !env with
    | Some value_types when !value_types <> [] ->
      let res = List.hd !value_types in
      value_types := List.tl !value_types;
      res
    | _ ->
      AnyType
  in
  
  let update_decl name value_type =
    match StringMap.find_opt name !env with
    | Some value_types when !value_types <> [] ->
      let value_type' = List.hd !value_types in
      if value_type' = NoneType then
        value_types := value_type :: (List.tl !value_types)
      else
        value_types := (make_union value_type' value_type) :: (List.tl !value_types)
    | _ ->
      ()
  in

  let find_decl name =
    match StringMap.find_opt name !env with
    | Some value_types when !value_types <> [] ->
      List.hd !value_types
    | _ ->
      AnyType
  in

  let rec remove_prop t name =
    match t with
    | ObjectType o ->
      o.optprops <- StringSet.add name o.optprops
    | UnionType (t1, t2) ->
      remove_prop t1 name;
      remove_prop t2 name
    | _ ->
      ()
  in

  let rec find_prop t name =
    match t with
    | ObjectType { proto; optprops; props } ->
      begin match StringMap.find_opt name props with
      | Some value_type when StringSet.mem name optprops ->
        make_union value_type (find_prop proto name)
      | Some value_type -> value_type
      | None -> find_prop proto name
      end
    | UnionType (t1, t2) ->
      make_union (find_prop t1 name) (find_prop t2 name)
    | _ ->
      UndefinedType
  in

  let rec update_prop t name value_type =
    match t with
    | ObjectType o ->
      o.props <- StringMap.update name (function
        | Some value_type' ->
          Some (make_union value_type' value_type)
        | None ->
          o.optprops <- StringSet.add name o.optprops;
          Some value_type
      ) o.props;
    | UnionType (t1, t2) ->
      update_prop t1 name value_type;
      update_prop t2 name value_type
    | _ ->
      ()
  in

  let create_object proto =
    ObjectType { proto = proto; props = StringMap.empty; optprops = StringSet.empty }
  in

  let object_prototype = create_object NullType in
  let function_prototype = create_object object_prototype in
  let number_prototype = create_object object_prototype in
  let bigint_prototype = create_object object_prototype in
  let string_prototype = create_object object_prototype in
  let boolean_prototype = create_object object_prototype in

  add_global "object_prototype" object_prototype;

  let create_function () =
    create_object function_prototype
  in

  add_decl ~value_type:(create_function ()) "Object";
  add_decl ~value_type:(create_object object_prototype) "this";
  add_decl ~value_type:(create_object object_prototype) "globalThis";

  let rec find_proto = function
    | ObjectType o -> o.proto
    | FunctionType o -> o.proto
    | StringType -> string_prototype
    | NumberType -> number_prototype
    | BigIntType -> bigint_prototype
    | BooleanType _ -> boolean_prototype
    | AnyType -> AnyType
    | UnionType (t1, t2) -> make_union (find_proto t1) (find_proto t2)
    | _ -> failwith "Typing.find_proto"
  in

  let update_proto t value_type =
    match t, value_type with
    | ObjectType o, (ObjectType _ | NullType) -> o.proto <- make_union o.proto value_type
    | FunctionType o, (ObjectType _ | NullType) -> o.proto <- make_union o.proto value_type
    | _ -> ()
  in

  let rec type_block body =
    List.iter (fun decl -> add_decl decl.name) body.declarations;
    List.iter type_statement body.statements;
    List.iter (fun decl -> decl.total_type <- remove_decl decl.name) body.declarations
  
  and type_statement = function
    | ExpressionStatement e ->
      type_expression e
    | DeclarationStatement (name, e) ->
      type_expression e;
      update_decl name e.value_type
    | ReturnStatement e ->
      type_expression e
    | BlockStatement body ->
      type_block body
    | IfStatement (e, s1, s2) ->
      type_expression e;
      let prev_env = !env in
      type_statement s1;
      let s1_env = !env in
      env := prev_env;
      type_statement s2;
      let s2_env = !env in
      env := merge_env s1_env s2_env
    | WhileStatement (e, s) ->
      failwith "not implemented"
  
  and type_expression e =
    e.value_type <- _type_expression e.value

  and _type_expression = function
    | IdentifierExpression name -> find_decl name
    | ThisExpression -> AnyType
    | NumberExpression _ -> NumberType
    | BigIntExpression _ -> BigIntType
    | StringExpression _ -> StringType
    | BooleanExpression b -> BooleanType (Some b)
    | NullExpression -> NullType
    | UndefinedExpression -> UndefinedType
    | TypeofExpression e ->
      type_expression e;
      StringType
    | InExpression (member, e) ->
      type_expression e;
      BooleanType (Option.map (fun n -> n >= 0) (mem_prop e.value_type member))
    | BinaryExpression (e1, op, e2) ->
      type_expression e1;
      type_expression e2;
      type_operator op e1.value_type e2.value_type
    | AssignmentExpression (name, e) ->
      type_expression e;
      update_decl name e.value_type;
      e.value_type
    | MemberAccessExpression (obj, "__proto__") ->
      type_expression obj;
      find_proto obj.value_type
    | MemberAccessExpression (obj, member) ->
      type_expression obj;
      find_prop obj.value_type member
    | MemberAssignmentExpression (obj, "__proto__", e) ->
      type_expression obj;
      type_expression e;
      update_proto obj.value_type e.value_type;
      e.value_type
    | MemberAssignmentExpression (obj, member, e) ->
      type_expression obj;
      type_expression e;
      update_prop obj.value_type member e.value_type;
      e.value_type
    | DeleteExpression (obj, member) ->
      type_expression obj;
      let mem = mem_prop obj.value_type member <> None in
      remove_prop obj.value_type member;
      BooleanType (if mem then Some true else None)
    | ObjectExpression (proto, props) ->
      let proto =
        match proto with
        | None -> object_prototype
        | Some proto ->
          type_expression proto;
          proto.value_type
      in
      let props =
        List.fold_right (fun (name, e) props ->
          type_expression e;
          StringMap.add name e.value_type props
        ) props StringMap.empty
      in
      ObjectType { proto; props; optprops = StringSet.empty }
    | CallExpression (f, params) ->
      failwith "not implemented"
    | MethodCallExpression ({ value = IdentifierExpression "console" }, "log", params) ->
      List.iter type_expression params;
      UndefinedType
    | MethodCallExpression (obj, member, params) ->
      failwith "not implemented"
    | FunctionExpression (params, body) ->
      failwith "not implemented"
  
  and type_operator op t1 t2 =
    match op, t1, t2 with
    | _, UnionType (t11, t12), _ ->
      make_union (type_operator op t11 t2) (type_operator op t12 t2)
    | _, _, UnionType (t21, t22) ->
      make_union (type_operator op t1 t21) (type_operator op t1 t22)
    | _, (NoneType | AnyType), _ -> t1
    | _, _, (NoneType | AnyType) -> t2
    | AdditionOperator, _, _ -> type_addition_operator t1 t2
    | _ -> failwith "not implemented"

  and type_addition_operator t1 t2 =
    match t1, t2 with
    | (StringType | ObjectType _ | FunctionType _), _ -> StringType
    | _, (StringType | ObjectType _ | FunctionType _) -> StringType
    | BigIntType, BigIntType -> BigIntType
    | BigIntType, _ -> NoneType
    | _, BigIntType -> NoneType
    | _ -> NumberType
  in

  type_block prog.body