require 'net/http'
require 'yaml'
require 'json'

module Dota
  module Utilities
    class UpdateData
      DOTA_CONSTANTS_ITEMS_URL = 'https://raw.githubusercontent.com/odota/dotaconstants/master/build/items.json'.freeze
      HEROES_URL = 'https://api.opendota.com/api/heroes'.freeze
      ABILITY_IDS_URL = 'https://raw.githubusercontent.com/odota/dotaconstants/master/build/ability_ids.json'.freeze
      ABILITIES_URL = 'http://www.dota2.com/jsfeed/abilitydata'.freeze
      ITEMS_DATA_FILE = 'data/item.yml'.freeze
      HEROES_DATA_FILE = 'data/hero.yml'.freeze
      ABILITIES_DATA_FILE = 'data/ability.yml'.freeze

      def self.call
        # updating items
        escaped_url = URI.escape(DOTA_CONSTANTS_ITEMS_URL)
        uri = URI.parse(escaped_url)
        res = Net::HTTP.get_response(uri)

        if res.is_a?(Net::HTTPSuccess)
          file_url = File.join(Dota.root, ITEMS_DATA_FILE)
          items = YAML::load_file(file_url)
          parsed = JSON.parse(res.body)
          parsed.each do |item_name, attributes|
            next if items.dig(attributes['id'])
            items[attributes['id']] = [item_name, attributes['dname']]
          end

          File.open(file_url, 'w') { |f| f.write items.to_yaml }
        end

        # Updating heroes

        escaped_url = URI.escape(HEROES_URL)
        uri = URI.parse(escaped_url)
        res = Net::HTTP.get_response(uri)

        if res.is_a?(Net::HTTPSuccess)
          file_url = File.join(Dota.root, HEROES_DATA_FILE)
          heroes_yml = YAML::load_file(file_url)
          heroes = JSON.parse(res.body)

          heroes.each do |hero|
              next if heroes_yml.dig(hero['id'])
              name = hero['name'].sub('npc_dota_hero_', '')
              heroes_yml[hero['id']] = [name, hero['localized_name']]
          end

          File.open(file_url, 'w') { |f| f.write heroes_yml.to_yaml }
        end

        # Updating abilities

        escaped_abilities_url = URI.escape(ABILITIES_URL)
        escaped_ability_ids_url = URI.escape(ABILITY_IDS_URL)
        abilities_uri = URI.parse(escaped_abilities_url)
        ability_ids_uri = URI.parse(escaped_ability_ids_url)
        abilities_res = Net::HTTP.get_response(abilities_uri)
        ability_ids_res = Net::HTTP.get_response(ability_ids_uri)

        if abilities_res.is_a?(Net::HTTPSuccess) && ability_ids_res.is_a?(Net::HTTPSuccess)
          file_url = File.join(Dota.root, ABILITIES_DATA_FILE)
          abilities_yml = YAML::load_file(file_url)
          abilities = JSON.parse(abilities_res.body)
          ability_ids = JSON.parse(ability_ids_res.body)

          ability_ids.each do |ability_id, ability_name|
            next if abilities_yml.dig(ability_id.to_i)

            localized_name = abilities.dig('abilitydata', ability_name, 'dname')
            abilities_yml[ability_id.to_i] = [ability_name, localized_name]
          end

          File.open(file_url, 'w') { |f| f.write abilities_yml.to_yaml }
        end
      end
    end
  end
end
