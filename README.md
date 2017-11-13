# Crystal Realtime Service

A simple websocket service to broadcast realtime events powered by JWTs

## Quickstart

You can deploy this service straight to heroku and skip most of the setup.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Usage

Crystal realtime service is powered by [JWTs](https://jwt.io/), you can use the JWT library for the language of your choice, the examples will be in [Ruby](https://github.com/jwt/ruby-jwt).

**Make sure your server side JWT secret is shared with the realtime service to validate JWTs.**

### Subscribe clients to channels

Create a JWT that can be sent to the client side  for your end user to connect to the websocket with. This should list all of the channels that user is allowed to subscribe to.

```ruby
payload = { channels: ["user:#{current_user.id}", "global"] }
jwt = JWT.encode(payload, ENV["JWT_SECRET"], "HS512")
```

One the client side open up a websocket and send an authentication message with the generated JWT, this will subscribe the user to the channels allowed. (Use )

```js
// Recommend using ReconnectingWebSocket to automatically reconnect websockets if you deploy the server or have any network disconnections
import ReconnectingWebSocket from "reconnectingwebsocket";

let ws = new ReconnectingWebSocket(`${process.env.REALTIME_SERVICE_WSS}/subscribe`); // URL your crystal realtime service is running on
let pingInterval;

ws.onopen = function() {
  const msg = {
    event: "authenticate",
    data: jwtToken, // Your server generated token with allowed channels
  };
  ws.send(JSON.stringify(msg));

  console.log("WS Connected");

  // Send a ping every so often to keep the socket alive
  pingInterval = setInterval(() => {
    ws.send(JSON.stringify({ event: "ping" }));
  }, 10000);
};

ws.onmessage = function(event) {
  const msg = JSON.parse(event.data);

  switch (msg.event) {
    case "subscribed": {
      const channelName = JSON.parse(msg.data).channel;
      console.log(`Subscribed to channel ${channelName}`);
      break;
    }
    case "pong": {
      // console.log("Realtime pong");
      break;
    }
    default: {
      const evenData = JSON.parse(msg.data);
      console.log(`Realtime: ${msg.event}`, evenData);

      if (msg.event === "new_item") {
        console.log("new item!", evenData);
      }
    }
  }
};

ws.onclose = function(event) {
  console.error("WS Closed", event);
  clearInterval(pingInterval);
};
```

### Broadcast messages from the server

Generate a token and send it to the realtime service

```ruby
data = {
  channel: "user:1", # Channel to broadcast to
  message: {
    event: "new_item",
    data: JSON.dump(item)
  },
  exp: Time.zone.now.to_i + 1.hour
}
jwt = JWT.encode(data, ENV["JWT_SECRET"], "HS512")
url = ENV.fetch("REALTIME_SERVICE_URL")
url += "/broadcast"

req = HTTP.post(url, json: { token: jwt })

if req.status > 206
  raise "Error communicating with Realtime service on URL: #{url}"
end
```

## Developing

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

You need to have [crystal lang](https://crystal-lang.org/) installed

```
brew install crystal-lang
```

### Running locally

Create a `.env` file in the root of this repository with the following environment variables, or set the variables if deploying to heroku.

```
JWT_SECRET=[> 64 character string]
```

[Sentry](https://github.com/samueleaton/sentry) is used to run the app and recompile when files change

```
./sentry
```

## Running the tests

```
crystal spec
```

## Built With

* [Crystal lang](https://crystal-lang.org/)
* [Kemal](https://github.com/kemalcr/kemal) - Web microframework for crystal

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Authors

* **Pete Hawkins** - [phawk](https://github.com/phawk)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
