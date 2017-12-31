## Alidayu-sms ##

 Alidayu sms sdk ruby version of Aliyun(阿里云阿里大于短信SDK).


### Installation ###
    # Manually from RubyGems.org
    $ gem install alidayu-sms

    # Or Gemfile if you are using Bundler
    $ gem alidayu-sms

### Usage ###
```ruby
alisms = Alidayu::Sms.new(sms_template: YOUR_SMS_TEMPLATE, sms_sign: YOUR_SMS_SIGN)
alisms.send_to(138xxxxxxxx, {code: 1234})
# true or false

# or use send! if you wanna raise error
alisms.send_to!(138xxxxxxxx, {code: 1234})
# true or raise Alidayu::RequestError
```
You can also use `send_sms` to send Alidayu sms, it's an alias of `send_to`.

### Configration ###
Before you sending any sms message, a valid configration is necessary.
Alidayu-sms supports you use it under Rails or in pure Ruby environment.

#### Rails ####
The Alidayu-sms configuration file is a YAML file, by default located at `config/alidayu.yml`.
You need to set your Alidayu access_key which you can get from Aliyun.
Here is an example configuration file:

```yaml
# config/alidayu.yml
development: &defaults
  access_key_id: YOUR_ACCESS_KEY_ID
  access_key_secret: YOUR_ACCESS_KEY_SECRET

test:
  <<: *defaults

production:
  <<: *defaults
```

#### Non-rails ####
If you are using Sinatra or anything pure Ruby, use `Alidayu::Sms.configration` to configrate Alidayu-sms.

```ruby
Alidayu::Sms.configration do |config|
  config.access_key_id = YOUR_ACCESS_KEY_ID
  config.access_key_secret = YOUR_ACCESS_KEY_SECRET
end
```

### License ###
Released under the [MIT](http://opensource.org/licenses/MIT) license. See LICENSE file for details.
