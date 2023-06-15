exception MissingArgument
exception TooManyArguments
exception OutputExtensionNotSupported

let () =

  let input_file = ref "" in
  let output_file = ref "" in

  let anon_fun file =
    if !input_file = "" then
      input_file := file
    else if !output_file = "" then
      output_file := file
    else
      raise TooManyArguments
  in

  let usage_msg  = "minijs2cd <input_file> <output_file>" in

  Arg.parse [] anon_fun usage_msg;

  if !input_file = "" then
    raise MissingArgument;

  if !output_file = "" then
    raise MissingArgument;

  let input_channel = open_in !input_file in

  let lexer_buffer = Lexing.from_channel input_channel in

  let minijs_prog = Parser.prog Lexer.token lexer_buffer in

  close_in input_channel;

  let output_channel = open_out !output_file in

  Cdpp.print output_channel minijs_prog;

  close_out output_channel