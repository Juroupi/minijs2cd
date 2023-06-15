{
  open Minijs
  open Lexing
  open Parser

  exception UnknownCharacter of string
  exception UnfinishedComment

  let ident_token =
    let keywords = Hashtbl.create 32 in
    List.iter (fun (n, k) -> Hashtbl.add keywords n k) [
      "true", TRUE; "false", FALSE; "null", NULL; "undefined", UNDEFINED;
      "function", FUNCTION; "let", LET; "delete", DELETE; "return", RETURN;
      "this", THIS; 
    ];
    fun n ->
      try Hashtbl.find keywords n
      with Not_found -> IDENT(n)
}

let digit = ['0'-'9']
let nzdigit = ['1'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let ident = (alpha | '_') (alpha | '_' | digit)*
let number = ("0" | (nzdigit digit* ))

rule token = parse
  | ['\n'] { new_line lexbuf; token lexbuf }
  | [' ' '\t' '\r']+ { token lexbuf }
  | "/*" _* "*/" { token lexbuf }
  | "\"" (([^'"']*) as s) "\"" { STRING s }
  | "'" (([^'\'']*) as s) "'" { STRING s }
  | ident as i { ident_token i }
  | number as v "n" { BIGINT(v) }
  | number as v { NUMBER(v) }
  | "(" { LPAR }
  | ")" { RPAR }
  | "{" { LBRACE }
  | "}" { RBRACE }
  | ":" { COLON }
  | ";" { SEMI }
  | "," { COMMA }
  | "." { DOT }
  | "=" { EQUAL }
  | eof { EOF }
  | _ { raise (UnknownCharacter (lexeme lexbuf)) }