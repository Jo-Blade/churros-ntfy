type header = string * string
type notif = header list * string

(** Print the curl command to run to send the parsed notif passed in parameter
    using ntfy.sh api
    @param ntfy_notif a parsed notif, for example: using graphql_json_parse
    @return the string containing the curl command to send notification
    within the shell
 *)
let print_notif_curl (headers, body) =
  "curl \\\n"
  ^ List.fold_left
      (fun acc (h_key, h_val) ->
        acc ^ Printf.sprintf "  -H \"%s: %s\" \\\n" h_key h_val)
      "" headers
  ^ Printf.sprintf "  -d \"%s\" \\\n%s\n" body "ntfy.sh/example_uri"

(** Custom operator to return the first value that is not None
   @param option_a first option to check
   @param option_b second option to check
   @return option_a if not None, option_b otherwise
 *)
let ( || ) option_a option_b =
  match option_a with Some _ -> option_a | None -> option_b

(** Parse one attribute of the Json notification object
    @param notif_attribute one attribute of the notification
    (channel, title, body…)
    @return (ntfy_headers, ntfy_body) the headers and the body to pass
    to the ntfy post api that correspond to this attribute
  *)
let parse_notif_attribute = function
  | Json.{ key = "channel"; value = J_String chann } -> (
      match chann with
      | "Articles" ->
          ([ ("Tags", "tada,loudspeaker"); ("Priority", "high") ], "")
      | "Comments" ->
          ([ ("Tags", "mailbox_with_mail"); ("Priority", "high") ], "")
      | "Other" -> ([ ("Tags", "spiral_notepad"); ("Priority", "low") ], "")
      | "Shotguns" ->
          ([ ("Tags", "tada,loudspeaker"); ("Priority", "high") ], "")
      | _ -> ([ ("Tags", "pushpin"); ("Priority", "default") ], ""))
  | Json.{ key = "title"; value = J_String title } -> ([ ("Title", title) ], "")
  | Json.{ key = "body"; value = J_String body } -> ([], body)
  | _ -> ([], "")

(** Parse one notification Json object from the graphql response
    @param notif_json a child of the "nodes" Json object in graphql response
    @return (ntfy_headers, ntfy_body) the headers and the body to pass
    to the ntfy post api to send this notification
  *)
let parse_notif : Json.t_json -> notif = function
  | Json.J_Object notif ->
      List.fold_left
        (fun (acc_h, acc_b) el ->
          let h, b = parse_notif_attribute el in
          (h @ acc_h, b ^ acc_b))
        ([], "") notif
  | _ -> ([], "")

(** Parse a child of the "data" Json object in graphql response
    @param data_json_child a child element of the "data" element
    @return (startCursor, ntfy_notifs) an option that contains "startCursor"
    value if present in this element or the list of parsed notifications
    if present in this object
  *)
let parse_data_el = function
  | Json.{ key = "pageInfo"; value = J_Object page_info } ->
      ( List.fold_left
          (fun acc el ->
            acc
            ||
            match el with
            | Json.{ key = "startCursor"; value = J_Null } -> None
            | Json.{ key = "startCursor"; value = J_String start } -> Some start
            | _ -> None)
          None page_info,
        [] )
  | Json.{ key = "nodes"; value = J_Array notifs_list } ->
      (None, List.map parse_notif notifs_list)
  | _ -> (None, [])

let create_error_notif error_message =
  ( [
      ("Title", "Notification error !");
      ("Priority", "urgent");
      ("Tags", "warning,skull");
    ],
    "Error" ^ error_message )

(** Parse the the graphql response from churros api to get values
    to make a post request to ntfy.sh 
    @param graphql_response the graphql response parsed to json
    @return (startCursor, ntfy_notifs) an option that contains "startCursor",
    should be present if notifications are to send
    \+ the list of given notifications converted to be sent to ntfy.sh
  *)
let graphql_json_parse graphql_response =
  Lexer.from_string Parser.file graphql_response |> function
  | Some
      (Json.J_Object
        [
          {
            key = "data";
            value =
              Json.J_Object
                [
                  { key = "notifications"; value = Json.J_Object medatada_list };
                ];
          };
        ]) -> (
      List.fold_left
        (fun (acc_stCursor, acc_notifs) el ->
          let stCursor, notifs = parse_data_el el in
          (stCursor || acc_stCursor, notifs @ acc_notifs))
        (None, []) medatada_list
      |> function
      | None, _ :: _ ->
          ( None,
            [
              create_error_notif
                "response contain notifs but no startcursor, risk of resending \
                 old notifs";
            ] )
      | x, y -> (x, y))
  | Some _ -> (None, [ create_error_notif "invalid response format" ])
  | None -> (None, [ create_error_notif "failed to parse graphql_response" ])

(** Simple debug display in the terminal of the complete output of
    graphql_json_parse
    @param startCursor the string option returned by graphql_response
    @param parse_notif the list of parsed notifications returned by graphql_json_parse
  *)
let notifs_debug_print startCursor parsed_notifs =
  let text =
    List.fold_left
      (fun acc x -> acc ^ Printf.sprintf "\n%s" (print_notif_curl x))
      "" parsed_notifs
  in
  (match startCursor with
  | Some s -> Printf.printf "startCursor=%s\n\n" s
  | None -> ());
  print_endline text
