type header = string * string
type notif = header list * string

val print_notif_curl : (string * string) list * string -> string
(** Print the curl command to run to send the parsed notif passed in parameter
    using ntfy.sh api
    @param ntfy_notif a parsed notif, for example: using graphql_json_parse
    @return the string containing the curl command to send notification
    within the shell
 *)

val graphql_json_parse : string -> string option * notif list
(** Parse the the graphql response from churros api to get values
    to make a post request to ntfy.sh 
    @param graphql_response the graphql response parsed to json
    @return (startCursor, ntfy_notifs) an option that contains "startCursor",
    should be present if notifications are to send
    \+ the list of given notifications converted to be sent to ntfy.sh
  *)

val notifs_debug_print : string option -> notif list -> unit
(** Simple debug display in the terminal of the complete output of
    graphql_json_parse
    @param startCursor the string option returned by graphql_response
    @param parse_notif the list of parsed notifications returned by graphql_json_parse
  *)
