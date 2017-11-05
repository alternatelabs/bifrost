require "kemal"
require "http/web_socket"
require "json"
require "colorize"
require "dotenv"
require "jwt"
require "./realtime_service/*"

Dotenv.load unless Kemal.config.env == "production"

# HTTP Client: https://github.com/mamantoha/crest
# JWT: https://github.com/crystal-community/jwt

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

  post "/broadcast" do |env|
    env.response.content_type = "text/html"

    begin
      token = env.params.json["token"].as(String)
      self.decode_jwt(token)

      {message: "Success"}.to_json
    rescue JWT::DecodeError
      env.response.status_code = 400
      {error: "Bad signature"}.to_json
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

  def self.decode_jwt(token : String)
    payload, header = JWT.decode(token, ENV["JWT_SECRET"], "HS512")
    payload
  end
end

Kemal.run
