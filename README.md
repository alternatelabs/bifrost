# Bifröst

Simple and fast websocket service written in Crystal to broadcast realtime events powered by JWTs

[![Build Status](https://travis-ci.org/alternatelabs/bifrost.svg?branch=master)](https://travis-ci.org/alternatelabs/bifrost)

## Quickstart

Get started by deploying this service to heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Usage

Bifrost is powered by [JWTs](https://jwt.io/), you can use the JWT library for the language of your choice, the examples will be in [Ruby](https://github.com/jwt/ruby-jwt).

**Make sure your server side JWT secret is shared with your bifrost server to validate JWTs.**

### 1. Create an API endpoint in your application that can give users a realtime token

*If you use Ruby we have a [bifrost-client gem](https://github.com/alternatelabs/bifrost-ruby-client) available to help simplify things.*

Create a JWT that can be sent to the client side for your end user to connect to the websocket with. This should list all of the channels that user is allowed to subscribe to.

```ruby
get "/api/bifrost-token" do
  authenticate_user!
  payload = { channels: ["user:#{current_user.id}", "global"] }
  jwt = JWT.encode(payload, ENV["JWT_SECRET"], "HS512")
  { token: jwt }.to_json
end
```

### 2. Subscribe clients to channels

On the client side open up a websocket and send an authentication message with the generated JWT, this will subscribe the user to the allowed channels.

```js
// Recommend using ReconnectingWebSocket to automatically reconnect websockets if you deploy the server or have any network disconnections
import ReconnectingWebSocket from "reconnectingwebsocket";

let ws = new ReconnectingWebSocket(`${process.env.BIFROST_WSS_URL}/subscribe`); // URL your bifrost server is running on
let pingInterval;

// Step 1
// ======
// When you first open the websocket the goal is to request a signed realtime
// token from your server side application and then authenticate with bifrost,
// subscribing your user to the channels your server side app allows them to
// connect to
ws.onopen = function() {
  axios.get("/api/bifrost-token").then((resp) => {
    const jwtToken = resp.data.token;
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
  });
};

// Step 2
// ======
// Upon receiving a message you can check the event name and ignore subscribed
// and pong events, everything else will be an event sent by your server side
// app.
ws.onmessage = function(event) {
  const msg = JSON.parse(event.data);

  switch (msg.event) {
    case "subscribed": {
      const channelName = JSON.parse(msg.data).channel;
      console.log(`Subscribed to channel ${channelName}`);
      break;
    }
    case "pong": {
      // console.log("Bifrost pong");
      break;
    }
    default: {
      // Note:
      // We advise you broadcast messages with a data key
      const eventData = JSON.parse(msg.data);
      console.log(`Bifrost msg: ${msg.event}`, eventData);

      if (msg.event === "new_item") {
        console.log("new item!", eventData);
      }
    }
  }
};

// Step 3
// ======
// Do some cleanup when the socket closes
ws.onclose = function(event) {
  console.error("WS Closed", event);
  clearInterval(pingInterval);
};
```

### 3. Broadcast messages from the server

Generate a token and send it to bifrost

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
url = ENV.fetch("BIFROST_URL")
url += "/broadcast"

req = HTTP.post(url, json: { token: jwt })

if req.status > 206
  raise "Error communicating with Bifrost server on URL: #{url}"
end
```

### 🚀 You're done

That's all you need to start broadcasting realtime events directly to clients in an authenticated manner. Despite the name, there is no planned support for bi-directional communication, it adds a lot of complications and for most apps it's simply not necessary.

#### `GET /info.json`

An endpoint that returns basic stats. As all sockets are persisted in memory if you restart the server or deploy an update the stats will reset.

```json
{
  "stats":{
    "deliveries": 117,
    "connected": 21
  }
}
```

## Contributing

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

See also the list of [contributors](https://github.com/alternatelabs/crystal-realtime/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
