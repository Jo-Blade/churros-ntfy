val wsclient :
  ?uri:Uri.t -> notif_callback:(unit -> unit Lwt.t) -> string -> unit Lwt.t
(** Main function of the client websocket,
    infinite loop that automatically reconnect if socket close
    @param uri the http endpoint of the websocket, IMPORTANT: ocaml uri
    DO NOT SUPPORT wss:// so you have to write https:// instead
    @param notif_callback a callback function which
    is called when a notif is received before looping
    @param uaid the "dom.push.userAgentID" value from firefox about:config
    (used to authenticate to autopush)
  *)
