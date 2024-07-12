# Churros-ntfy: churros to ntfy.sh notification bridge

**Churros-ntfy is a bridge that relay your [churros](https://git.inpt.fr/inp-net/churros) notifications to a ntfy.sh compatible endpoint.**

## Just, why ?

For 99% of people, it is useless, web push works great. However if you are in the case web push don't work on one of your devices (eg. ungoogled android) or you want to receive churros notifications in your your own non web project this project can help you.

## How does it work ?

The application get notifications by connecting into your churros account and then it just make an api call to churros with your subscription as a parameter.
You can choose to fetch notifications only when you run the binary and then exit (in that case you should set a cron job to run the application periodically) or to connect to [mozilla's server](https://github.com/mozilla-services/autopush-rs) to receive notifications in real time.

In the second case, the application will connect to Mozilla's "service push" server with a websocket and run forever.
When a notification is send by churros to you, it is in fact sent to Mozilla's service "service push" server that relay it through the websocket to any authenticated client. The application authehticate himself as the web browser to the service push using the USER_AGENT value you have to provide.

With this method, we can receive a message in real time for each push notification sent to your web browser (not only churros' ones). But their content is encrypted and to make the project simpler it does not try to decrypt any data (it may be a good new feature but too much complicated for me). The reception of a notification is only used as a signal to know when to do an api call to churros and receive notification almost imediatly.

## Interesting… How to use then ?

>[!CAUTION]
> **The process explained here is for experimented user only! Be caution to not share any sensitive data to others like your churros_token. If you don't know what you are doing, don't follow the next section.**

1. Connect to your churros account on Firefox (another web browser can work only if you don't want to use the websocket. The instruction here assume you use firefox, because it's honestly supperior ;) )
2. Subscribe to the notification et verify they work by pressing the test button
3. Find the needed values for the bridge:
    - TOKEN: open Firefox debug tools (F12) and go to "Storage" > "cookies" > "https://churros.inpt.fr" > "token"
    - SUBSCRIPTION: go to "about:serviceworkers" uri in Firefox search "churros" in the page and look for the url begginning with "https://updates.push.services.mozilla.com/wpush/v2/…"
    - CURSOR_FILE: a path to any writable location in the disk. It's used to remember already received notifications to not send them multiple times
4. Choose you own ntfy.sh uri for "NTFY_URI" environnment variable. A good uri should be random and long to be sure it's unique and nobody will receive you notifications. See https://ntfy.sh/#features to learn more about how to setup ntfy.sh client app on your device
5. Start the executable by passing the previous values as environnment variables. It will fetch the latests notifications, send them using ntfy.sh api and exit

*How to use the websocket support for realtime notifications ?*

**Use a new Firefox profile !** You can rename the "~/.mozilla/" folder and then restore it after you finished to setup the bridge. Passing the user agent id of your actual firefox profile will prevent your browser to receive any notification until the bridge is stopped.

So, now that you have an empty Firefox profile just for the bridge (or you don't care at all about notifications in firefox), you can repeat the steps 1 to 3 from the previous section.
Then, you need to find your Firefox' user agent id for web push:
- Go to "about:config" and search "dom.push.userAgentID"
- Copy the value and pass it to the bridge as "USER_AGENT" environnment variable
- You can now safely delete this Firefox' profile, we don't need it anymore

## How to build ?

Build it as a normal ocaml dune project. You can also use [nix](https://nixos.org/download/) (the package manager) to make the process fully automatic on any linux distribution by running `nix build`.

If people are interesting in the project I could create docker images, just ask me.

## Why Ocaml ?

Because functionnal languages are good and robust ! And because I don't learned Haskell yet (hello Haskell fans, I promise I will learn your language, please don't kill me)
