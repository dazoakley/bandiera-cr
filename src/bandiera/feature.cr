module Bandiera
  struct Feature
    @name : String
    @active : Bool
    @user_group_list : Array(String)
    @user_group_regex : Regex

    getter :active, :user_group_list, :user_group_regex
    getter? :active

    def initialize(
      name,
      active = false,
      user_group_regex = Regex.new(""),
      user_group_list = [] of String
    )
      @name             = name
      @active           = active
      @user_group_list  = user_group_list
      @user_group_regex = user_group_regex
    end

    def enabled?(user_group = "")
      return false unless active?
      return true unless configured_for_user_groups?

      false || enabled_for_user_group_list?(user_group) || enabled_for_user_group_regex?(user_group)
    end

    private def configured_for_user_groups?
      user_group_list.any? || !user_group_regex.source.empty?
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
  end
end
