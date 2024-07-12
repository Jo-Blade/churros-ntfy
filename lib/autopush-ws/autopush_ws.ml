open Lwt.Infix

(** Construct the content of the first message we have to send
    to authenticate to the autopush service
    @param uaid the "dom.push.userAgentID" value from firefox about:config
    (used to authenticate to autopush)
  *)
let wscontent uaid =
  Printf.sprintf
    {|{"messageType":"hello","broadcasts":{"remote-settings/monitor_changes":"\"%s\""},"use_webpush":true,"uaid":"%s"}|}
    (Int64.to_string (Timedesc.Timestamp.get_s (Timedesc.Timestamp.now ())))
    uaid

(** Custom operator to return the first value that is not None
   @param option_a first option to check
   @param option_b second option to check
   @return option_a if not None, option_b otherwise
 *)
let ( || ) option_a option_b =
  match option_a with Some _ -> option_a | None -> option_b

(** Wrapper function to add a timeout to any Lwt async function
   @param time timeout in second
   @param f the function that return the promise
   @return `Done result if the function f ended in time
   or `Timeout promise if timeout was triggered
 *)
let compute ~time ~f =
  let promise = f () in
  Lwt.pick
    [
      (promise >|= fun v -> `Done v);
      (Lwt_unix.sleep time >|= fun () -> `Timeout promise);
    ]

(** Build the body of the ack response to send to the websocket
    when a notification is received
    @param content the content of the notification message received
    @return the string content to send back through the websocket or None
    if the message was invalid
  *)
let create_ack content =
  (* Inner function that return (Option channelID, Option version) depending
      if there are present in the current attribute or not *)
  let parse_attribute = function
    | Json.{ key = "channelID"; value = J_String s } -> (Some s, None)
    | Json.{ key = "version"; value = J_String s } -> (None, Some s)
    | _ -> (None, None)
  in
  Lexer.from_string Parser.file content |> function
  | Some (J_Object l) -> (
      (* Combine the result of the parsing of all attributes *)
      List.fold_left
        (fun (acc1, acc2) el ->
          let a, b = parse_attribute el in
          (acc1 || a, acc2 || b))
        (None, None) l
      |> function
      | Some channelID, Some version ->
          (* All parameters found, create the ack response string *)
          Some
            (Printf.sprintf
               {|{"messageType":"ack","updates":[{"channelID":"%s","version":"%s","code":100}]}|}
               channelID version)
      | _ -> None)
  | _ -> None

(** Main function of the client websocket,
    infinite loop that automatically reconnect if socket close
    @param uri the http endpoint of the websocket, IMPORTANT: ocaml uri
    DO NOT SUPPORT wss:// so you have to write https:// instead
    @param notif_callback a callback function which
    is called when a notif is received before looping
    @param uaid the "dom.push.userAgentID" value from firefox about:config
    (used to authenticate to autopush)
  *)
let rec wsclient ?(uri = Uri.of_string "https://push.services.mozilla.com/")
    ~notif_callback uaid =
  Resolver_lwt.resolve_uri ~uri Resolver_lwt_unix.system >>= fun endp ->
  let ctx = Lazy.force Conduit_lwt_unix.default_ctx in
  let%lwt client = Conduit_lwt_unix.endp_to_client ~ctx endp in

  let rec react conn =
    compute ~time:600. ~f:(fun () -> Websocket_lwt_unix.read conn) >>= function
    | `Done { opcode = Ping; _ } ->
        Websocket_lwt_unix.write conn (Websocket.Frame.create ~opcode:Pong ())
        >>= fun () -> react conn
    | `Done { opcode = Close; content; _ } ->
        print_endline "close";
        (* Immediately echo and pass this last message to the user *)
        (if String.length content >= 2 then
           Websocket_lwt_unix.write conn
             (Websocket.Frame.create ~opcode:Close
                ~content:(String.sub content 0 2) ())
         else Websocket_lwt_unix.write conn (Websocket.Frame.close 1000))
        >>= fun () -> Websocket_lwt_unix.close_transport conn
    | `Done { opcode = Text; content; _ }
    | `Done { opcode = Binary; content; _ } -> (
        print_endline "text or binary";
        match create_ack content with
        | Some content ->
            Websocket_lwt_unix.write conn (Websocket.Frame.create ~content ())
            >>= notif_callback
            >>= fun () -> react conn
        | None -> react conn)
    | `Done { opcode = Pong; _ } | `Done { opcode = Continuation; _ } ->
        print_endline "pong or continuation";
        react conn
    | `Done _ ->
        print_endline "BUGG ??";
        Websocket_lwt_unix.close_transport conn
    | `Timeout promise ->
        print_endline "timeout, close socket and reconnect";
        Lwt.cancel promise;
        Websocket_lwt_unix.close_transport conn >>= fun () ->
        let%lwt conn = Websocket_lwt_unix.connect ~ctx client uri in
        Websocket_lwt_unix.write conn
          (Websocket.Frame.create ~content:(wscontent uaid) ())
        >>= fun () -> react conn
  in

  let%lwt conn = Websocket_lwt_unix.connect ~ctx client uri in
  (* when disconnected, wait 15s before reconnect *)
  Websocket_lwt_unix.write conn
    (Websocket.Frame.create ~content:(wscontent uaid) ())
  >>= fun () ->
  Lwt.catch
    (fun () -> react conn)
    (fun _ ->
      print_endline "reconnect in 15s";
      Lwt_unix.sleep 15. >>= fun () -> wsclient ~uri ~notif_callback uaid)
