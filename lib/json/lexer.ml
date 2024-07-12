open Parser
open Sedlexing.Utf8

exception Lexer_unknown_token of string

let newline = [%sedlex.regexp? '\r' | '\n' | "\r\n"]
let whitespace = [%sedlex.regexp? Plus (' ' | '\t' | newline)]
let number = [%sedlex.regexp? Plus '0' .. '9']
let float = [%sedlex.regexp? number, Opt ('.', number)]
let string = [%sedlex.regexp? '"', Star (Compl '"'), '"']

let escaped_string =
  [%sedlex.regexp? '"', Star (Compl ('"' | '\\') | '\\', any), '"']

let rec tokenizer (buffer : Sedlexing.lexbuf) : token =
  match%sedlex buffer with
  | whitespace -> tokenizer buffer
  | "null" -> NULL
  | number -> INT (int_of_string (lexeme buffer))
  | "true" -> BOOL true
  | "false" -> BOOL false
  | float -> FLOAT (float_of_string (lexeme buffer))
  | escaped_string ->
      STRING (String.sub (lexeme buffer) 1 (String.length (lexeme buffer) - 2))
  | "," -> COMMA
  | ":" -> COLON
  | "{" -> LBRACE
  | "}" -> RBRACE
  | "[" -> LBRACKET
  | "]" -> RBRACKET
  | "//" -> single_comment buffer
  | "/*" -> multi_comment buffer
  | eof -> EOF
  | _ -> raise (Lexer_unknown_token (lexeme buffer))

and single_comment (buffer : Sedlexing.lexbuf) : token =
  print_string (lexeme buffer);
  match%sedlex buffer with
  | newline -> tokenizer buffer
  | any -> single_comment buffer
  | eof -> EOF
  | _ -> raise (Lexer_unknown_token (lexeme buffer))

and multi_comment (buffer : Sedlexing.lexbuf) : token =
  print_string (lexeme buffer);
  match%sedlex buffer with
  | "*/" -> tokenizer buffer
  | any -> multi_comment buffer
  | eof -> EOF
  | _ -> raise (Lexer_unknown_token (lexeme buffer))

let provider (buffer : Sedlexing.lexbuf) () :
    token * Lexing.position * Lexing.position =
  let token = tokenizer buffer in
  let start, stop = Sedlexing.lexing_positions buffer in
  (token, start, stop)

let from_string (parser : (token, 'a) MenhirLib.Convert.traditional)
    (str : string) : 'a =
  let buffer = from_string str in
  let provider = provider buffer in
  MenhirLib.Convert.Simplified.traditional2revised parser provider
