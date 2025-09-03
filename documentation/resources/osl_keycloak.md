
# Resource: osl_keycloak

## Actions

| Action | Description                                  |
| :----- | :------------------------------------------- |
| create | Installs and configures a Keycloak instance. |

## Properties

| Properties     | Description                                | Type                  | Values and Default          |
| :------------- | :----------------------------------------- | :-------------------- | :-------------------------- |
| admin_password | The password for the Keycloak admin user.  | String                | Required, sensitive         |
| caddy          | Whether to use Caddy as a reverse proxy.   | true or false         | Default is `false`          |
| db_engine      | The database engine to use.                | String                | `postgres`, `mariadb`. Default is `mariadb` |
| db_host        | The database host.                         | String                | Default is `localhost`      |
| db_name        | The name of the database.                  | String                | Default is `keycloak`       |
| db_pass        | The password for the database user.        | String                | Required, sensitive         |
| db_user        | The username for the database.             | String                | Default is `keycloak`       |
| hostname       | The hostname for the Keycloak instance.    | String                | Name property               |
| keystore_pass  | The password for the keystore.             | String                | Required, sensitive         |
| port           | The port to run Keycloak on.               | Integer               | Default is `8080`           |
| version        | The version of Keycloak to install.        | String                | Default is `26.3`           |

## Example Usage

```ruby
osl_keycloak 'keycloak.example.com' do
  admin_password 'supersecretadminpass'
  db_pass 'supersecretdbpass'
  keystore_pass 'supersecretkeystorepass'
  caddy true
  db_engine 'postgres'
  version '25.0'
end
```
