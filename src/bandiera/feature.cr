require "zlib"

module Bandiera
  struct Feature
    @name : String
    @active : Bool
    @user_group_list : Array(String)
    @user_group_regex : Regex
    @percentage : Int32

    getter :name, :active, :user_group_list, :user_group_regex, :percentage
    getter? :active

    def initialize(
      name,
      active = false,
      user_group_regex = Regex.new(""),
      user_group_list = [] of String,
      percentage = 1000
    )
      @name             = name
      @active           = active
      @user_group_list  = user_group_list
      @user_group_regex = user_group_regex
      @percentage       = percentage
    end

    def enabled?(user_group = "", user_id = "")
      return false unless active?
      return true unless configured_for_user_groups? || configured_for_percentage?

      false || enabled_for_user_group_list?(user_group) || enabled_for_user_group_regex?(user_group) || enabled_for_percentage?(user_id)
    end

    private def configured_for_user_groups?
      user_group_list.any? || !user_group_regex.source.empty?
    end

    private def configured_for_percentage?
      percentage <= 100
    end

    private def enabled_for_user_group_list?(user_group : String)
      return false unless user_group_list.any? && !user_group.empty?
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
      return false unless configured_for_percentage? && !user_id.empty?
      Zlib.crc32("#{name}-1_000_000-#{user_id}") % 100 < percentage
    end
  end
end
