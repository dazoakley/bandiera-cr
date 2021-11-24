require "digest/crc32"

module Bandiera
  struct Feature
    @name : String
    @description : String
    @active : Bool
    @user_group_list : Array(String)
    @user_group_regex : Regex
    @percentage : Int32
    @start_time : Time
    @end_time : Time

    getter name, description, active, user_group_list, user_group_regex, percentage, start_time, end_time
    getter? active

    def initialize(
      name,
      description,
      active = nil,
      user_group_list = nil,
      user_group_regex = nil,
      percentage = nil,
      start_time = nil,
      end_time = nil
    )
      @name = name
      @description = description
      @active = active || false
      @user_group_list = user_group_list || [] of String
      @user_group_regex = user_group_regex || Regex.new("")
      @percentage = percentage || 1000
      @start_time = start_time || Time.utc(1, 1, 1, 0, 0, 0)
      @end_time = end_time || Time.utc(9999, 12, 31, 23, 59, 59)
    end

    def enabled?(user_group = "", user_id = "")
      return false unless active?
      return true unless configured_for_user_groups? || configured_for_percentage? || configured_for_time_range?

      false ||
        enabled_for_user_group_list?(user_group) ||
        enabled_for_user_group_regex?(user_group) ||
        enabled_for_percentage?(user_id) ||
        enabled_for_time_range?
    end

    def configured_for_user_groups?
      user_group_list.any? || !user_group_regex.source.empty?
    end

    def configured_for_percentage?
      percentage <= 100
    end

    def configured_for_time_range?
      return false if start_time == Time.utc(1, 1, 1, 0, 0, 0) && end_time == Time.utc(9999, 12, 31, 23, 59, 59)
      end_time > start_time
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

    private def enabled_for_time_range?
      return false unless configured_for_time_range?

      now = Time.utc
      start_time < now && end_time > now
    end
  end
end
