open Lwt.Infix

let req_body subscriptionEndpoint startCursor =
  let pagination =
    match startCursor with
    | Some s -> Printf.sprintf "before: \"%s\"" s
    | None -> "first: 1"
  in
  let graphql =
    Printf.sprintf
      {|
  {
    notifications(%s, subscriptionEndpoint: "%s") {
      nodes {
        id
        channel
        title
        body
        updatedAt
      }
      pageInfo {
        startCursor
      }
    }
  }
|}
      pagination subscriptionEndpoint
  in
  Printf.sprintf
    {|
  {
    "query":"%s",
    "extensions":{}
  }
|}
    (String.escaped graphql)

(** Make an api call to churros to retrieve the last unread notifications
    @param churros_token the token used to connect to churros
    @param subscriptionEndpoint the web push subscriptionEndpoint (see about:serviceworkers)
    @param startCursor Some <string> to get the unread notification
    or None to get the latest one even if already read
    @return an option of the startcursor and the list of parsed notification,
    see Notif.graphql_json_parse
 *)
let fetch_unread_notifications ~churros_token ~subscriptionEndpoint ~startCursor
    =
  Cohttp_lwt_unix.Client.post
    ~headers:
      ( Cohttp.Header.init_with "Content-Type" "application/json" |> fun h ->
        Cohttp.Header.add h "Authorization"
          (Printf.sprintf "Bearer %s" churros_token) )
    ~body:
      (Cohttp_lwt.Body.of_string (req_body subscriptionEndpoint startCursor))
    (Uri.of_string "https://churros.inpt.fr/graphql")
  >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string >>= fun x ->
  Lwt.return (Notif.graphql_json_parse x)

(** Send the notifications using ntfy.sh api
    @param parsed_notifs a list of notifications as returnd by fetch_unread_notifications
    or Notif.graphql_json_parse
 *)
let send_notifications ntfy_uri parsed_notifs =
  (* Actually send the notif using ntfy.sh api *)
  List.fold_left
    (fun _ (headers, body) ->
      let%lwt _ =
        Cohttp_lwt_unix.Client.post
          ~headers:
            (Cohttp.Header.of_list
               (("Content-Type", "application/json") :: headers))
          ~body:(Cohttp_lwt.Body.of_string body)
          (Uri.of_string ntfy_uri)
      in
      Lwt.return_unit)
    Lwt.return_unit parsed_notifs
