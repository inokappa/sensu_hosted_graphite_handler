require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'hosted_graphite'
require 'timeout'

module Sensu::Extension

  class PostHostedGraphite < Handler

    def name
      'post_hosted_graphite'
    end

    def description
      'outputs metrics to Hosted Graphite'
    end

    def post_init
      HostedGraphite.api_key = settings['post_hosted_graphite']['api_key']
      case settings['post_hosted_graphite']['protocol']
      when "http"
        HostedGraphite.protocol = HostedGraphite::HTTP
      when "tcp"
        HostedGraphite.protocol = HostedGraphite::TCP
      when "udp"
        HostedGraphite.protocol = HostedGraphite::UDP
      end
    end

    def run(event)
      begin
        event = Oj.load(event)
        @logger.info("----------------------- first event  ------------------------------------------")
        @logger.info(event[:check])
        host = event[:client][:name]
        series = event[:check][:name]
        timestamp = event[:check][:issued]
        duration = event[:check][:duration]
        output = event[:check][:output]
      rescue => e
        @logger.error("Hosted Graphite: Error setting up event object - #{e.backtrace.to_s}")
      end

      begin
        @logger.info("----------------------- event  ------------------------------------------")
        @logger.info(event)
        @logger.info(event['check']['output'])
        @logger.info("--------------------------------------------------------------------------")
        output.split(/\n/).each do |line|
          @logger.info("Parsing line: #{line}")
	  k,v = line.split(/\s+/)
          v = v.match('\.').nil? ? Integer(v) : Float(v) rescue v.to_s
          @logger.info("=============> #{v}")
          post_init.send_metric(k, v)
        end
      rescue => e
        @logger.error("Hosted Graphite: Error parsing output lines - #{e.backtrace.to_s}")
        @logger.error("Hosted Graphite: #{e.backtrace.to_s}")
        @logger.error("Hosted Graphite: Error posting event - #{e.backtrace.to_s}")
      end
      yield("Hosted Graphite: Handler finished", 0)
    end
  end
end
