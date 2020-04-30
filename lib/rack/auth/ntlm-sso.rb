# Rack authentication module for optional single sign-on via NTLM
# more info about NTLM: http://www.innovation.ch/personal/ronald/ntlm.html

require 'base64'
require 'ntlm'
require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'

module Rack
  module Auth
    class NTLMSSO < AbstractHandler

      VERSION = '0.0.1'
      FLAGS = [ :NEGOTIATE_UNICODE,
                :REQUEST_TARGET,
                :NEGOTIATE_NTLM,
                :NEGOTIATE_ALWAYS_SIGN,
                :TARGET_TYPE_DOMAIN,
                :NEGOTIATE_EXTENDED_SECURITY,
                :NEGOTIATE_TARGET_INFO,
                :NEGOTIATE_VERSION,
                :NEGOTIATE_128,
                :NEGOTIATE_56 ]

      attr_accessor :hostname, :domain, :default_remote_user, :debug

      public
      def call env
        auth = NTLMSSO::Request.new env

        unless auth.provided?
          log "ask for TYPE 1 message"
          return unauthorized
        end
        
        log "got: #{auth.params}"
        message = auth.decode
        @version = auth.version

        case message
        when :negotiate
          log "received negotiate message. Sending TYPE 2 message asking for TYPE 3 message"
          return unauthorized challenge(:type2)

        when :authenticate
          if auth.user.nil? or auth.user.empty?
            set_default_user env
          else
            env['REMOTE_USER'] = auth.user
            log "authenticated user: #{auth.user}"
          end

        else
          log "ERROR: unknown client response"
          set_default_user env
        end

        return @app.call env
      end

      private
      def log msg
        return unless @debug
        $stdout.puts "[NTLM SSO] #{msg}"
        $stdout.flush
      end

      def set_default_user env
        return if @default_remote_user.nil? or @default_remote_user.empty?
        env['REMOTE_USER'] = @default_remote_user 
        log "set default user: #{@default_remote_user}"
      end

      def challenge msg=nil
        if msg.eql? :type2
          c = NTLM::Message::Challenge.new
          c.version = @version
          c.target_name = @domain
          c.target_info = { :AV_NB_DOMAIN_NAME => @domain,
                            :AV_NB_COMPUTER_NAME => @hostname}.to_a
          FLAGS.each{|flag| c.set flag}

          res = 'NTLM %s' % c.serialize_to_base64
        else
          res = 'NTLM'
        end

        log "sending: %s" % res
        return res
      end


      class Request < Auth::AbstractRequest
        attr_accessor :version, :user

        def decode
          s = Base64.decode64 self.params
          begin
            res = NTLM::Message::Authenticate.parse s
            @user = res.user
            return :authenticate
          rescue NTLM::Message::ParseError
            begin
              res = NTLM::Message::Negotiate.parse s
              @version = res.version
              return :negotiate
            rescue NTLM::Message::ParseError
              return nil
            end
          end
        end
      end

    end
  end
end
