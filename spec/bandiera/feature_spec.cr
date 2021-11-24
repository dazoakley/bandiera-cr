require "../spec_helper"
require "../../src/bandiera/feature"

Spectator.describe Bandiera::Feature do
  subject do
    described_class.new(
      name: name,
      description: description,
      active: active,
      user_group_list: user_group_list,
      user_group_regex: user_group_regex,
      percentage: percentage,
      start_time: start_time,
      end_time: end_time
    )
  end

  let(name) { "feature_name" }
  let(description) { "feature description" }
  let(user_group_list) { nil }
  let(user_group_regex) { nil }
  let(percentage) { nil }
  let(start_time) { nil }
  let(end_time) { nil }

  describe "a plain on/off feature flag" do
    describe "#enabled?" do
      context "when it is 'active'" do
        let(active) { true }

        it "returns true" do
          expect(subject.enabled?).to eq true
        end
      end

      context "when it is NOT 'active'" do
        let(active) { false }

        it "returns false" do
          expect(subject.enabled?).to eq false
        end
      end
    end
  end

  describe "a feature for specific user groups" do
    context "configured as a list of groups" do
      let(user_group) { "admin" }
      let(user_group_list) { %w(admin editor) }

      context "when the feature is 'active'" do
        let(active) { true }

        describe "#enabled?" do
          context "returns true" do
            it "when the user_group is in the list" do
              expect(subject.enabled?(user_group: user_group)).to eq true
            end

            it "when the user_group is in the list regardless of case" do
              expect(subject.enabled?(user_group: user_group.upcase)).to eq true
            end
          end

          context "returns false" do
            let(user_group) { "guest" }

            it "when the user_group is not in the list" do
              expect(subject.enabled?(user_group: user_group)).to eq false
            end

            it "when no user_group argument was passed" do
              expect(subject.enabled?).to eq false
            end
          end
        end
      end

      context "when the feature is NOT 'active'" do
        let(active) { false }

        describe "#enabled?" do
          it "always returns false" do
            expect(subject.enabled?(user_group: user_group)).to eq false
          end
        end
      end

      context "when users have blank lines in their list of groups" do
        let(active) { true }
        let(user_group_list) { ["admin", "", "editor", ""] }

        describe "enabled?" do
          it "ignores these values when considering the user_group" do
            expect(subject.enabled?(user_group: "admin")).to eq true
            expect(subject.enabled?(user_group: "")).to eq false
          end
        end
      end
    end

    context "configured as a regex" do
      subject do
        described_class.new(
          name: name,
          description: description,
          active: active,
          user_group_regex: user_group_regex
        )
      end

      let(user_group) { "admin" }
      let(user_group_regex) { Regex.new("admin") }

      context "when the feature is 'active'" do
        let(active) { true }

        describe "#enabled?" do
          context "returns true" do
            it "when the user_group matches the regex" do
              expect(subject.enabled?(user_group: user_group)).to eq true
            end
          end

          context "returns false" do
            let(user_group) { "guest" }

            it "when the user_group does not match the regex" do
              expect(subject.enabled?(user_group: user_group)).to eq false
            end

            it "when no user_group argument was passed" do
              expect(subject.enabled?).to eq false
            end
          end
        end
      end

      context "when the feature is NOT 'active'" do
        let(active) { false }

        describe "#enabled?" do
          it "always returns false" do
            expect(subject.enabled?(user_group: user_group)).to eq false
          end
        end
      end
    end

    context "configured as a combination of exact matches and a regex" do
      subject do
        described_class.new(
          name: name,
          description: description,
          active: active,
          user_group_list: user_group_list,
          user_group_regex: user_group_regex
        )
      end

      let(user_group_list) { %w(editor) }
      let(user_group_regex) { Regex.new(".*admin") }

      context "when the feature is 'active'" do
        let(active) { true }

        describe "#enabled?" do
          context "returns true" do
            it "when the user_group is in the exact match list but does not match the regex" do
              expect(subject.enabled?(user_group: "editor")).to eq true
            end

            it "when the user_group matches the regex but is not in the exact match list" do
              expect(subject.enabled?(user_group: "super_admin")).to eq true
            end
          end

          context "returns false" do
            it "when the user_group is not in the exact match list and does not match the regex" do
              expect(subject.enabled?(user_group: "guest")).to eq false
            end

            it "when no user_group argument was passed" do
              expect(subject.enabled?).to eq false
            end
          end
        end
      end

      context "when the feature is NOT 'active'" do
        let(active) { false }

        describe "#enabled?" do
          it "always returns false" do
            expect(subject.enabled?(user_group: "editor")).to eq false
          end
        end
      end
    end
  end

  describe "a feature for a percentage of users" do
    context "when a feature is 'active'" do
      let(active) { true }

      context "with 5%" do
        let(percentage) { 5 }

        describe "#enabled?" do
          it "returns true for ~5% of users" do
            expect(calculate_active_count(subject, percentage)).to be < 15
          end
        end
      end

      context "with 95%" do
        let(percentage) { 95 }

        describe "#enabled?" do
          it "returns true for ~95% of users" do
            expect(calculate_active_count(subject, percentage)).to be > 85
            expect(calculate_active_count(subject, percentage)).to be < 100
          end
        end
      end

      context "when no user_id is passed" do
        let(percentage) { 95 }

        describe "#enabled?" do
          it "returns false" do
            expect(subject.enabled?).to eq false
          end
        end
      end
    end

    context "when the feature is NOT 'active'" do
      let(active) { false }
      let(percentage) { 95 }

      describe "#enabled?" do
        it "returns false" do
          expect(calculate_active_count(subject, percentage)).to eq(0)
        end
      end
    end
  end

  describe "a feature configured for both user groups and a percentage of users" do
    context "when the feature is 'active'" do
      let(active) { true }

      context "and the user matches on the user_group configuration" do
        let(user_group_list) { %w(admin editor) }
        let(percentage) { 5 }

        describe "#enabled?" do
          it "returns true" do
            expect(subject.enabled?(user_group: "admin", user_id: "12345")).to eq true
          end
        end
      end

      context "and the user does not match the user_groups, but does fall into the percentage" do
        let(user_group_list) { %w(admin editor) }
        let(percentage) { 100 }

        describe "#enabled?" do
          it "returns true" do
            expect(subject.enabled?(user_group: "qwerty", user_id: "12345")).to eq true
          end
        end
      end

      context "and the user matches neither the user_groups or falls into the percentage" do
        let(user_group_list) { %w(admin editor) }
        let(percentage) { 0 }

        describe "#enabled?" do
          it "returns false" do
            expect(subject.enabled?(user_group: "qwerty", user_id: "12345")).to eq false
          end
        end
      end

      context "when the user_group and/or user_id params are not passed" do
        let(user_group_list) { %w(admin editor) }
        let(percentage) { 100 }

        describe "#enabled?" do
          it "returns false" do
            expect(subject.enabled?).to eq false
          end
        end
      end
    end

    context "when the feature is NOT 'active'" do
      let(active) { false }
      let(user_group_list) { %w(admin editor) }
      let(percentage) { 100 }

      describe "#enabled?" do
        it "returns false" do
          expect(subject.enabled?(user_group: "admin", user_id: "12345")).to eq false
        end
      end
    end
  end

  describe "a feature for a time range" do
    let(active) { true }

    context "when only start_time is set" do
      let(start_time) { Time.utc(2021, 1, 1) }

      context "when the current date/time is after the start_time" do
        describe "#enabled?" do
          it "returns true" do
            Timecop.freeze(Time.utc(2021, 1, 10)) do
              expect(subject.enabled?).to eq true
            end
          end
        end
      end

      context "when the current date/time is before the start_time" do
        describe "#enabled?" do
          it "returns false" do
            Timecop.freeze(Time.utc(2020, 12, 10)) do
              expect(subject.enabled?).to eq false
            end
          end
        end
      end
    end

    context "when only end_time is set" do
      let(end_time) { Time.utc(2021, 2, 1) }

      context "when the current date/time is before the end_time" do
        describe "#enabled?" do
          it "returns true" do
            Timecop.freeze(Time.utc(2021, 1, 1)) do
              expect(subject.enabled?).to eq true
            end
          end
        end
      end

      context "when the current date/time is after the end_time" do
        describe "#enabled?" do
          it "returns false" do
            Timecop.freeze(Time.utc(2021, 2, 10)) do
              expect(subject.enabled?).to eq false
            end
          end
        end
      end
    end

    context "when the current date/time is in the set range" do
      let(start_time) { Time.utc(2021, 1, 1) }
      let(end_time) { Time.utc(2021, 2, 1) }

      describe "#enabled?" do
        it "returns true" do
          Timecop.freeze(Time.utc(2021, 1, 10)) do
            expect(subject.enabled?).to eq true
          end
        end
      end
    end

    context "when the current date/time is outside the set range" do
      let(start_time) { Time.utc(2021, 1, 1) }
      let(end_time) { Time.utc(2021, 2, 1) }

      describe "#enabled?" do
        it "returns false" do
          Timecop.freeze(Time.utc(2021, 2, 10)) do
            expect(subject.enabled?).to eq false
          end
        end
      end
    end
  end

  describe "#configured_for_time_range?" do
    let(active) { true }

    context "when the end_time is before the start_time" do
      let(start_time) { Time.utc(2021, 2, 1) }
      let(end_time) { Time.utc(2021, 1, 1) }

      it "returns false" do
        expect(subject.configured_for_time_range?).to eq false
      end
    end

    context "when only start_time is set" do
      let(start_time) { Time.utc(2021, 2, 1) }

      it "returns true" do
        expect(subject.configured_for_time_range?).to eq true
      end
    end

    context "when only end_time is set" do
      let(end_time) { Time.utc(2021, 2, 1) }

      it "returns true" do
        expect(subject.configured_for_time_range?).to eq true
      end
    end

    context "when the time range is valid" do
      let(start_time) { Time.utc(2021, 1, 1) }
      let(end_time) { Time.utc(2021, 2, 1) }

      it "returns true" do
        expect(subject.configured_for_time_range?).to eq true
      end
    end
  end

  describe "#configured_for_user_groups?" do
    let(active) { true }
    let(user_group_list) { nil }
    let(user_group_regex) { nil }

    context "when a user_group list have been configured" do
      let(user_group_list) { %w(boo bar) }

      it "returns true" do
        expect(subject.configured_for_user_groups?).to eq true
      end
    end

    context "when a user_group regex have been configured" do
      let(user_group_regex) { Regex.new(".*") }

      it "returns true" do
        expect(subject.configured_for_user_groups?).to eq true
      end
    end

    context "when no user_group settings have been configured" do
      it "returns false" do
        expect(subject.configured_for_user_groups?).to eq false
      end
    end
  end

  describe "#configured_for_percentage?" do
    let(active) { true }
    let(percentage) { nil }

    context "when a percentage has been configured" do
      let(percentage) { 50 }

      it "returns true" do
        expect(subject.configured_for_percentage?).to be_true
      end
    end

    context "when a percentage has not been configured" do
      it "returns false" do
        expect(subject.configured_for_percentage?).to be_false
      end
    end
  end
end

def calculate_active_count(feature, _percentage)
  (0...100).map { |id| feature.enabled?(user_id: id.to_s) }
    .count { |val| val == true }
end
