require "kemal"
require "http/web_socket"
require "json"
require "colorize"
require "dotenv"
require "jwt"
require "./bifrost/*"

Dotenv.load unless Kemal.config.env == "production"

SOCKETS = {} of String => Set(HTTP::WebSocket)
STATS   = {} of String => Int32
STATS["deliveries"] = 0

module Bifrost
  get "/" do |env|
    env.response.content_type = "text/html"
    render "src/views/index.ecr"
  end

  get "/test" do |env|
    if Kemal.config.env == "development"
      env.response.content_type = "text/html"
      allowed_channels = {channels: ["user:1"]}
      test_token = JWT.encode(allowed_channels, ENV["JWT_SECRET"], "HS512")
      render "src/views/test.ecr"
    else
      render_404
    end
  end

  get "/info.json" do |env|
    connected_clients = 0
    SOCKETS.each { |k, v| connected_clients += v.size }
    env.response.content_type = "application/json"
    new_stats = STATS.merge({"connected" => connected_clients})
    {stats: new_stats}.to_json
  end

  get "/ping" do |env|
    begin
      message = env.params.query["message"].as(String)
      channel = env.params.query["channel"].as(String)

      SOCKETS[channel].each do |socket|
        socket.send({event: "ping", data: message}.to_json)
        STATS["deliveries"] += 1
      end
    rescue KeyError
      puts "Key error!".colorize(:red)
    end
  end

  post "/broadcast" do |env|
    env.response.content_type = "application/json"

    begin
      token = env.params.json["token"].as(String)
      payload = self.decode_jwt(token)

      channel = payload["channel"].as(String)
      deliveries = 0

      if SOCKETS.has_key?(channel)
        SOCKETS[channel].each do |socket|
          socket.send(payload["message"].as(Hash).to_json)
          deliveries += 1
        end
      end

      STATS["deliveries"] += deliveries

      {message: "Success", deliveries: deliveries}.to_json
    rescue JWT::DecodeError
      env.response.status_code = 400
      {error: "Bad signature"}.to_json
    end
  end

  ws "/subscribe" do |socket|
    puts "Socket connected".colorize(:green)
    ponged = true

    socket.on_message do |message|
      puts message.colorize(:blue)

      data = JSON.parse(message)

      # If message is authing, store in hash
      if data["event"].to_s == "authenticate"
        token = data["data"].to_s

        begin
          payload = self.decode_jwt(token)
          payload["channels"].as(Array).each do |channel|
            channel = channel.as(String)
            if SOCKETS.has_key?(channel)
              SOCKETS[channel] << socket
            else
              SOCKETS[channel] = Set{socket}
            end

            socket.send({event: "subscribed", data: {channel: channel}.to_json}.to_json)
            STATS["deliveries"] += 1
          end
        rescue JWT::DecodeError
          socket.close("Not Authorized!")
        end
      end
    end

    socket.on_pong do
      ponged = true
    end

    # Remove clients from the list when it's closed
    socket.on_close do
      SOCKETS.each do |channel, set|
        if set.includes?(socket)
          set.delete(socket)

          puts "Socket disconnected from #{channel}!".colorize(:yellow)
        end
      end
    end

    # Ping sockets every 15 seconds to keep them alive
    spawn do
      loop do
        sleep 15

        if ponged
          puts "Socket ponged, pinging again!"
          ponged = false
        else
          puts "Socket didn't respond to ping, disconnecting!".colorize(:red)
          socket.close("Socket didn't respond to ping")
          break
        end

        begin
          socket.ping
        rescue IO::Error
          puts "Socket closed, stopping ping timer".colorize(:yellow)
          break
        end
      end
    end
  end

  def self.decode_jwt(token : String)
    payload, header = JWT.decode(token, ENV["JWT_SECRET"], "HS512")
    payload
  end
end

Kemal.run
