
# Resource: osl_noggin

## Actions

| Action | Description            |
| :----- | :--------------------- |
| create | Installs Noggin        |

## Properties

| Properties                     | Description                                                | Type          | Values and Default                               |
| :----------------------------- | :--------------------------------------------------------- | :------------ | :----------------------------------------------- |
| `accept_images_from`           | A list of domains from which images may be proxied.        | Array         | Default is `[]`                                  |
| `activation_token_expiration`  | The number of days an activation token is valid.           | Integer       | Default is `30`                                  |
| `allowed_username_human`       | A human-readable list of allowed characters in usernames.  | Array         | Default is `['a-z', '0-9', '-']`                 |
| `allowed_username_max_size`    | The maximum length of a username.                          | Integer       | Default is `32`                                  |
| `allowed_username_min_size`    | The minimum length of a username.                          | Integer       | Default is `5`                                   |
| `allowed_username_pattern`     | A regular expression that usernames must match.            | String        | Default is `'^[a-z0-9][a-z0-9-]{3,30}[a-z0-9]$'` |
| `avatar_default_type`          | The default avatar type to use.                            | String        | `mp`, `identicon`, `monsterid`, `wavatar`, `retro`, `robohash`. Default is `robohash` |
| `avatar_service_url`           | The URL of the avatar service.                             | String        | Default is `'https://seccdn.libravatar.org/'`    |
| `basset_url`                   | The URL for the Basset static assets.                      | String        | `nil`                                            |
| `fernet_secret`                | The secret key for Fernet.                                 | String        | Required, sensitive                              |
| `freeipa_admin_password`       | The password for the FreeIPA admin user.                   | String        | Required, sensitive                              |
| `freeipa_admin_user`           | The FreeIPA admin user.                                    | String        | Default is `'admin'`                             |
| `freeipa_servers`              | A list of FreeIPA servers to connect to.                   | Array         | Required                                         |
| `gunicorn_opts`                | Additional options to pass to Gunicorn.                    | String        | `nil`                                            |
| `gunicorn_workers`             | The number of Gunicorn workers to spawn.                   | String        | Default is `'3'`                                 |
| `mail_default_sender`          | The default sender for emails.                             | String        | Default is `"Noggin <noggin@#{node['domain']}>"` |
| `mail_domain_blocklist`        | A list of domains to block from registering.               | Array         | Default is `[]`                                  |
| `mail_suppress_send`           | Whether to suppress sending emails.                        | true or false | Defaults to `true` in a Kitchen environment      |
| `osl_only`                     | Whether to restrict firewall access to the OSL network.    | true or false | Default is `true`                                |
| `page_size`                    | The number of items to show per page.                      | Integer       | Default is `30`                                  |
| `password_reset_expiration`    | The number of minutes a password reset token is valid.     | Integer       | Default is `10`                                  |
| `registration_open`            | Whether to allow new users to register.                    | true or false | Default is `true`                                |
| `secret_key`                   | The secret key for the application.                        | String        | Required, sensitive                              |
| `spamcheck_token_expiration`   | The number of minutes a spam check token is valid.         | Integer       | Default is `60`                                  |
| `stage_users_role`             | The role for stage user managers.                          | String        | Default is `'Stage User Managers'`               |
| `templates_custom_directories` | A list of directories to search for custom templates.      | Array         | Default is `[]`                                  |
| `theme`                        | The theme to use for the application.                      | String        | Default is `'default'`                           |

## Example Usage

```ruby
osl_noggin 'noggin.example.com' do
  fernet_secret 'supersecretfernetkey'
  freeipa_admin_password 'supersecretipapass'
  freeipa_servers ['ipa1.example.com', 'ipa2.example.com']
  secret_key 'supersecretappkey'
end
```
