exception MissingArgument
exception TooManyArguments
exception OutputExtensionNotSupported

let () =

  let input_file = ref "" in
  let output_file = ref "" in
  let typing = ref false in

  let anon_fun = function
    | arg when !input_file = "" -> input_file := arg
    | arg when !output_file = "" -> output_file := arg
    | _ -> raise TooManyArguments
  in

  let speclist = [
    ("-t", Arg.Unit (fun () -> typing := true), "Enable typing")
  ] in

  let usage_msg  = "minijs2cd [-t] <input_file> <output_file>" in

  Arg.parse speclist anon_fun usage_msg;

  if !input_file = "" then
    raise MissingArgument;

  if !output_file = "" then
    raise MissingArgument;

  let input_channel = open_in !input_file in

  let lexer_buffer = Lexing.from_channel input_channel in

  let minijs_prog = Parser.prog Lexer.token lexer_buffer in

  close_in input_channel;

  if !typing then
    Typing.type_prog minijs_prog;

  let output_channel = open_out !output_file in

  Cdpp.print output_channel minijs_prog;

  close_out output_channel