open Lwt.Infix

(** Read the startCursor value from file 
    @param filename the path to the file to read
  *)
let read_startcursor filename =
  (* Read file and display the first line *)
  try
    let ic = open_in filename in
    try
      let line = input_line ic in
      close_in ic;
      (* close the input channel *)
      Some line
    with e ->
      (* some unexpected exception occurs *)
      close_in_noerr ic;
      (* emergency closing *)
      raise e
    (* exit with error: files are closed but
       channels are not flushed *)
  with Sys_error err ->
    print_endline err;
    print_endline
      (Printf.sprintf
         "Warning: can't open %s, try to retrieve last churros notification"
         filename);
    None

(** Write the updated startCursor into file
    @param filename the path to the file to read
    @param startCursor the new value of startCursor that will be written
  *)
let write_startcursor filename startCursor =
  (* Write message to file *)
  let oc = open_out filename in
  (* create or truncate file, return channel *)
  Printf.fprintf oc "%s\n" startCursor;
  (* write something *)
  close_out oc (* flush and close the channel *)

(* Read settings from environnment variables and then start program *)
let () =
  (* What is this `let*` syntax? In short, it allows to minimize the boilerplate associated to extracting **optional** values.
     Once we reach the bottom, we know all the prior function calls have successfully ran. Otherwise, the function short-circuits and returns `None`. *)
  let env_vars =
    let ( let* ) = Option.bind in
    let* churros_token = Sys.getenv_opt "TOKEN" in
    let* subscriptionEndpoint = Sys.getenv_opt "SUBSCRIPTION" in
    let* startcursor_file = Sys.getenv_opt "CURSOR_FILE" in
    let* ntfy_uri = Sys.getenv_opt "NTFY_URI" in
    Some (churros_token, subscriptionEndpoint, startcursor_file, ntfy_uri)
  in
  match env_vars with
  | Some (churros_token, subscriptionEndpoint, startcursor_file, ntfy_uri) -> (
      let relay_notifs () =
        Requests.fetch_unread_notifications ~churros_token ~subscriptionEndpoint
           ~startCursor:(read_startcursor startcursor_file)
        >>= fun (maybe_startCursor, parsed_notifs) ->
        match maybe_startCursor with
        | Some startCursor ->
            Requests.send_notifications ntfy_uri parsed_notifs >>= fun () ->
            Lwt.return (write_startcursor startcursor_file startCursor)
        | None -> Lwt.return_unit
      in
      match Sys.getenv_opt "USER_AGENT" with
      | Some uaid ->
          Lwt_main.run (Autopush_ws.wsclient ~notif_callback:relay_notifs uaid)
      | None ->
          print_endline "Debug: USER_AGENT undefined, run oneshot";
          Lwt_main.run (relay_notifs ()))
  | None ->
      print_endline
        "Missing configuration values, you must provide at least TOKEN, \
         SUBSCRIPTION, CURSOR_FILE and NTFY_URI"
