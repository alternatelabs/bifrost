require "kemal"
require "http/web_socket"
require "json"
require "colorize"
require "./realtime_service/*"

SOCKETS = {} of String => HTTP::WebSocket

module RealtimeService
  get "/" do |env|
    env.response.content_type = "text/html"
    render "src/views/index.ecr"
  end

  get "/ping" do |env|
    begin
      message = env.params.query["message"].as(String)
      token = env.params.query["token"].as(String)

      SOCKETS[token].send(message)
    rescue KeyError
      puts "Key error!".colorize(:red)
    end
  end

  ws "/ws" do |socket|
    puts "Socket connected".colorize(:green)

    # Broadcast each message to all clients
    socket.on_message do |message|
      puts message.colorize(:blue)

      data = JSON.parse(message)

      # If message is authing, store in hash
      if data["type"].to_s == "authenticate"
        # if socket is already authenticated with a different token re-auth
        if existing_token = SOCKETS.key?(socket)
          SOCKETS.delete(existing_token)
        end
        token = data["payload"]["token"].to_s
        SOCKETS[token] = socket
      end
    end

    # Remove clients from the list when it's closed
    socket.on_close do
      token = SOCKETS.key(socket)
      puts "Token: #{token} disconnected!".colorize(:yellow)
      SOCKETS.delete token
    end
  end
end

Kemal.run