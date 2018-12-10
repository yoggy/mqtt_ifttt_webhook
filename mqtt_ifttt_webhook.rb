#!/usr/bin/ruby
# coding: utf-8
require 'mqtt'
require 'yaml'
require 'ostruct'
require 'json'
require 'uri'
require 'net/http'
require 'pp'

$stdout.sync = true

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

$conf = OpenStruct.new(YAML.load_file(File.dirname($0) + '/config.yaml'))

conn_opts = {
  "remote_host" => $conf.host,
  "remote_port" => $conf.port
}
if $conf.use_auth
  conn_opts["username"] = $conf.username
  conn_opts["password"] = $conf.password
end

def ifttt_webhook_post(json_str)
  uri = URI.parse("https://maker.ifttt.com/trigger/#{$conf.ifttt_webhook_event}/with/key/#{$conf.ifttt_webhook_key}")
  https = Net::HTTP.new(uri.host, uri.port)

  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.request_uri)
  req["Content-Type"] = "application/json"

  req.body = json_str # {"value1":"title", "value2":"message"}
  res = https.request(req)

  $log.info("post message code=#{res.code}, message=#{res.message}")
end

MQTT::Client.connect(conn_opts) do |c|
  c.subscribe($conf.subscribe_topic)
  $log.info "mqtt subscribe : topic=#{$conf.subscribe_topic}"

  c.get do |topic, msg|
    $log.info "mqtt receiveed message : topic=#{topic}, msg=#{msg.pretty_inspect}"
    ifttt_webhook_post(msg)
  end
end


# 
