# Resource: osl_ipa_server

## Actions

| Action  | Description                               |
| :------ | :---------------------------------------- |
| install | Installs and configures a FreeIPA server. |

## Properties

| Properties        | Description                                       | Type          | Values and Default  |
| :---------------- | :------------------------------------------------ | :------------ | :------------------ |
| admin_password    | The password for the FreeIPA admin user.          | String        | Required, sensitive |
| certificate_pin   | The pin for the SSL certificate.                  | String        | Required, sensitive |
| certificate       | The name of the certificate to use .              | String        | Required            |
| dirsrv_password   | The password for the Directory Server.            | String        | Required, sensitive |
| dns               | Whether to set up DNS on the FreeIPA server.      | true or false | Default is false    |
| domain            | The domain for the FreeIPA server.                | String        | Required            |
| ntp               | Whether to configure NTP on the FreeIPA server.   | true or false | Default is false    |
| realm             | The Kerberos realm for the FreeIPA server.        | String        | Required            |
| server_hostname   | The hostname of the FreeIPA server.               | String        | Name property       |

## Example Usage

```ruby
osl_ipa_server 'ipa.example.com' do
  admin_password 'password'
  certificate 'ipa.example.com'
  certificate_pin '1234'
  dirsrv_password 'password'
  dns true
  domain 'example.com'
  ntp true
  realm 'EXAMPLE.COM'
end
```
