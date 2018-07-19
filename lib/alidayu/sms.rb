require_relative 'sms/version'
%w(securerandom net/http ostruct openssl base64 erb yaml json cgi uri).each{|_| require _}

module Alidayu
  class SettingError < StandardError; end
  class RequestError < StandardError; end

  class Sms
    SMS_ENDPOINT = 'http://dysmsapi.aliyuncs.com'
    attr :signature, :template

    class << self
      def configuration
        @setting = OpenStruct.new
        yield @setting
      end

      def setting
        return @setting if @setting && !@setting.to_h.nil?
        if defined?(Rails)
          config = YAML.load(ERB.new(File.read("#{Rails.root}/config/alidayu.yml")).result)[Rails.env]
          if !config.nil? then @setting = OpenStruct.new config else
            raise SettingError, setting_error_message(:rails)
          end
        else
          raise SettingError, setting_error_message
        end
      end

      private

      def setting_error_message(reason = :configuration)
        base_message = 'You have not set access_key_id and access_key_secret '
        case reason
          when :configuration
            base_message << 'by Alidayu::Sms.configuration'
          when :rails
            base_message << "in config/alidayu.yml for #{env} environment"
        end
      end
    end

    def initialize(options)
      @template  = options[:sms_template]
      @signature = options[:sms_sign]

      endpoint = URI setting.endpoint || SMS_ENDPOINT
      @conn = Net::HTTP.new(endpoint.host, endpoint.port).tap do |http|
        http.open_timeout = 3
        http.read_timeout = 3
      end
    end

    def send_to!(reciever, params = {})
      reciever   = Array(reciever).join(',')
      sms_params = default_params(reciever, params)
      sig_params = params_with_sign(setting.access_key_secret, sms_params)
      response   = @conn.request_post '/', params_string(sig_params)
      result     = JSON.parse response.body
      if result['Code'] != 'OK'
        raise RequestError, "#{result['Code']} #{result['Message']}"
      end
      true
    end

    def send_to(*args)
      send_to!(*args) rescue false
    end

    alias send_sms send_to
    alias send_sms! send_to!

    private

    def default_params(reciever, params)
      {
        'AccessKeyId'      => setting.access_key_id,
        'Action'           => 'SendSms',
        'Format'           => 'JSON',
        'RegionId'         => 'cn-hangzhou',
        'SignName'         => signature,
        'PhoneNumbers'     => reciever,
        'TemplateParam'    => params.to_json,
        'SignatureMethod'  => 'HMAC-SHA1',
        'SignatureNonce'   => SecureRandom.uuid,
        'SignatureVersion' => '1.0',
        'TemplateCode'     => template,
        'Timestamp'        => Time.now.utc.strftime('%FT%TZ'),
        'Version'          => '2017-05-25'
      }
    end

    def setting
      self.class.setting
    end

    def params_with_sign(key_secret, params)
      params.merge 'Signature' => sign(key_secret, params)
    end

    def xencode(str)
      CGI.escape(str).gsub('+', '%20').gsub('*', '%2A').gsub('%7E', '~')
    end

    def sign(key_secret, params)
      key = key_secret + '&'
      str = 'POST&%2F&' + xencode(params_string params)
      Base64.strict_encode64 OpenSSL::HMAC.digest('sha1', key, str)
    end

    def params_string(params)
      params.sort.map{|arr| arr.map{|e| xencode e}.join('=')}.join('&')
    end

  end
end
