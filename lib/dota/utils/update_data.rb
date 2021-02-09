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
      NPC_ABILITIES_URL = 'https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/scripts/npc/npc_abilities.json'.freeze
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
            hero_yml       = heroes_yml.dig(hero['id'])
            name           = hero['name'].sub('npc_dota_hero_', '')
            localized_name = hero['localized_name']

            next if hero_yml&.last == localized_name
            heroes_yml[hero['id']] = [name, localized_name]
          end

          File.open(file_url, 'w') { |f| f.write heroes_yml.to_yaml }
        end

        # Updating abilities

        escaped_abilities_url = URI.escape(ABILITIES_URL)
        escaped_ability_ids_url = URI.escape(ABILITY_IDS_URL)
        escaped_npc_ability_url = URI.escape(NPC_ABILITIES_URL)
        abilities_uri = URI.parse(escaped_abilities_url)
        ability_ids_uri = URI.parse(escaped_ability_ids_url)
        npc_abilities_uri = URI.parse(escaped_npc_ability_url)
        abilities_res = Net::HTTP.get_response(abilities_uri)
        ability_ids_res = Net::HTTP.get_response(ability_ids_uri)
        npc_abilities_res = Net::HTTP.get_response(npc_abilities_uri)

        if abilities_res.is_a?(Net::HTTPSuccess) && ability_ids_res.is_a?(Net::HTTPSuccess)
          file_url = File.join(Dota.root, ABILITIES_DATA_FILE)
          abilities_yml = YAML::load_file(file_url)
          abilities = JSON.parse(abilities_res.body)
          ability_ids = JSON.parse(ability_ids_res.body)
          npc_abilities = JSON.parse(npc_abilities_res.body)

          ability_ids.each do |ability_id, ability_name|
            next if abilities_yml.dig(ability_id.to_i)

            localized_name = abilities.dig('abilitydata', ability_name, 'dname')
            if localized_name&.include?('{s:value}')
              ability_special = npc_abilities.dig('DOTAAbilities', ability_name, 'AbilitySpecial')&.first

              bonus_value = ability_special ? ability_special['value'] : ''
              localized_name.gsub!('{s:value}', bonus_value.to_s)
            end
            abilities_yml[ability_id.to_i] = [ability_name, localized_name]
          end

          File.open(file_url, 'w') { |f| f.write abilities_yml.to_yaml }
        end
      end
    end
  end
end
