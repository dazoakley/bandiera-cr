require "digest/crc32"

module Bandiera
  struct Feature
    @name : String
    @description : String
    @active : Bool || Nil
    @user_group_list : Array(String) || Nil
    @user_group_regex : Regex || Nil
    @percentage : Int32 || Nil

    getter name, description, active, user_group_list, user_group_regex, percentage
    getter? active

    def initialize(
      name,
      description,
      active = nil,
      user_group_list = nil,
      user_group_regex = nil,
      percentage = nil
    )
      @name = name
      @description = description
      @active = active || false
      @user_group_list = user_group_list || [] of String
      @user_group_regex = user_group_regex || Regex.new("")
      @percentage = percentage || 1000
    end

    def enabled?(user_group = "", user_id = "")
      return false unless active?
      return true unless configured_for_user_groups? || configured_for_percentage?

      false ||
        enabled_for_user_group_list?(user_group) ||
        enabled_for_user_group_regex?(user_group) ||
        enabled_for_percentage?(user_id)
    end

    def configured_for_user_groups?
      user_group_list.any? || !user_group_regex.source.empty?
    end

    def configured_for_percentage?
      percentage <= 100
    end

    private def enabled_for_user_group_list?(user_group : String)
      return false if user_group_list.empty? || user_group.empty?
      cleaned_user_group_list.includes?(user_group.downcase)
    end

    private def cleaned_user_group_list
      user_group_list.reject { |elm| elm.nil? || elm.empty? }.map { |elm| elm.downcase }
    end

    private def enabled_for_user_group_regex?(user_group : String)
      return false if user_group_regex.source.empty?
      !!user_group_regex.match(user_group)
    end

    private def enabled_for_percentage?(user_id : String)
      return false if !configured_for_percentage? || user_id.empty?
      Digest::CRC32.checksum("#{name}-1_000_000-#{user_id}") % 100 < percentage
    end
  end
end
