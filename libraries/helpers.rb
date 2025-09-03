module OslIdm
  module Cookbook
    module Helpers
      def keycloak_db_url
        case new_resource.db_engine
        when 'postgresql'
          "jdbc:postgresql://#{new_resource.db_host}:5432/#{new_resource.db_name}"
        when 'mariadb', 'mysql'
          "jdbc:mariadb://#{new_resource.db_host}:3306/#{new_resource.db_name}"
        end
      end
    end
  end
end
Chef::DSL::Recipe.include ::OslIdm::Cookbook::Helpers
Chef::Resource.include ::OslIdm::Cookbook::Helpers
