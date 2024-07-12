val fetch_unread_notifications :
  churros_token:string ->
  subscriptionEndpoint:string ->
  startCursor:string option ->
  (string option * Notif.notif list) Lwt.t
(** Make an api call to churros to retrieve the last unread notifications
    @param churros_token the token used to connect to churros
    @param subscriptionEndpoint the web push subscriptionEndpoint (see about:serviceworkers)
    @param startCursor Some <string> to get the unread notification
    or None to get the latest one even if already read
    @return an option of the startcursor and the list of parsed notification,
    see Notif.graphql_json_parse
 *)

val send_notifications :
  string -> ((string * string) list * string) list -> unit Lwt.t
(** Send the notifications using ntfy.sh api
    @param parsed_notifs a list of notifications as returnd by fetch_unread_notifications
    or Notif.graphql_json_parse
 *)
