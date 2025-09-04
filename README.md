# osl-idm Cookbook

A cookbook for managing Identity Management (IdM) services at the OSUOSL.

## Requirements

### Platforms

- AlmaLinux 9

### Chef

- Chef 16+

### Cookbooks

- base
- certificate
- osl-docker
- osl-resource
- osl-firewall

## Resources

- [`osl_ipa_server`](documentation/resources/osl_ipa_server.md): Installs and configures a FreeIPA server.
- [`osl_keycloak`](documentation/resources/osl_keycloak.md): Installs and configures a Keycloak instance.
- [`osl_noggin`](documentation/resources/osl_noggin.md): Installs and configures the Noggin user portal for FreeIPA.

## Usage

Add `depends 'osl-idm'` to your cookbook's `metadata.rb` and use the resources as needed in your recipes.

## Documentation

Full documentation for all resources is available in the [`documentation`](documentation/) directory.

## License and Authors

- Author:: Oregon State University <chef@osuosl.org>

```text
Copyright:: 2025, Oregon State University

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
