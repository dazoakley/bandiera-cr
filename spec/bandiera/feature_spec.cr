require "../spec_helper"
require "../../src/bandiera/feature"

Spectator.describe Bandiera::Feature do
  let(:subject) { described_class.new(name: name, active: active) }
  let(:name) { "feature_name" }

  describe "a plain on/off feature flag" do
    describe "#enabled?" do
      context "when it is 'active'" do
        let(:active) { true }

        it "returns true" do
          expect(subject.enabled?).to eq(true)
        end
      end

      context "when it is NOT 'active'" do
        let(:active) { false }

        it "returns false" do
          expect(subject.enabled?).to eq(false)
        end
      end
    end
  end

  describe "a feature for specific user groups" do
    context "configured as a list of groups" do
      let(:subject) do
        described_class.new(
          name: name,
          active: active,
          user_group_list: user_group_list
        )
      end

      let(:user_group) { "admin" }
      let(:user_group_list) { %w(admin editor) }

      context "when the feature is 'active'" do
        let(:active) { true }

        describe "#enabled?" do
          context "returns true" do
            it "if the user_group is in the list" do
              expect(subject.enabled?(user_group: user_group)).to eq(true)
            end

            it "if the user_group is in the list regardless of case" do
              expect(subject.enabled?(user_group: user_group.upcase)).to eq(true)
            end
          end

          context "returns false" do
            let(:user_group) { "guest" }

            it "if the user_group is not in the list" do
              expect(subject.enabled?(user_group: user_group)).to eq(false)
            end

            it "if no user_group argument was passed" do
              expect(subject.enabled?).to eq(false)
            end
          end
        end
      end

      context "when the feature is NOT 'active'" do
        let(:active) { false }

        describe "#enabled?" do
          it "always returns false" do
            expect(subject.enabled?(user_group: user_group)).to eq false
          end
        end
      end

      context "when users have blank lines in their list of groups" do
        let(:active) { true }
        let(:user_group_list) { ["admin", "", "editor", ""] }

        describe "enabled?" do
          it "ignores these values when considering the user_group" do
            expect(subject.enabled?(user_group: "admin")).to eq(true)
            expect(subject.enabled?(user_group: "")).to eq(false)
          end
        end
      end
    end

    context "configured as a regex" do
      let(:subject) do
        described_class.new(
          name: name,
          active: active,
          user_group_regex: user_group_regex
        )
      end

      let(:user_group) { "admin" }
      let(:user_group_regex) { Regex.new("admin") }

      context "when the feature is 'active'" do
        let(:active) { true }

        describe "#enabled?" do
          context "returns true" do
            it "if the user_group matches the regex" do
              expect(subject.enabled?(user_group: user_group)).to eq(true)
            end
          end

          context "returns false" do
            let(:user_group) { "guest" }

            it "if the user_group does not match the regex" do
              expect(subject.enabled?(user_group: user_group)).to eq(false)
            end

            it "if no user_group argument was passed" do
              expect(subject.enabled?).to eq(false)
            end
          end
        end
      end

      context "when the feature is NOT 'active'" do
        let(:active) { false }

        describe "#enabled?" do
          it "always returns false" do
            expect(subject.enabled?(user_group: user_group)).to eq(false)
          end
        end
      end
    end

    context "configured as a combination of exact matches and a regex" do
      let(:subject) do
        described_class.new(
          name: name,
          active: active,
          user_group_list: user_group_list,
          user_group_regex: user_group_regex
        )
      end

      let(:user_group_list) { %w(editor) }
      let(:user_group_regex) { Regex.new(".*admin") }

      context "when the feature is 'active'" do
        let(:active) { true }

        describe "#enabled?" do
          context "returns true" do
            it "if the user_group is in the exact match list but does not match the regex" do
              expect(subject.enabled?(user_group: "editor")).to eq(true)
            end

            it "if the user_group matches the regex but is not in the exact match list" do
              expect(subject.enabled?(user_group: "super_admin")).to eq(true)
            end
          end

          context "returns false" do
            it "if the user_group is not in the exact match list and does not match the regex" do
              expect(subject.enabled?(user_group: "guest")).to eq(false)
            end

            it "if no user_group argument was passed" do
              expect(subject.enabled?).to eq(false)
            end
          end
        end
      end

      context "when the feature is NOT 'active'" do
        let(:active) { false }

        describe "#enabled?" do
          it "always returns false" do
            expect(subject.enabled?(user_group: "editor")).to eq(false)
          end
        end
      end
    end
  end

  describe "a feature for a percentage of users" do
    let(:subject) do
      described_class.new(
        name: name,
        active: active,
        percentage: percentage
      )
    end

    context "when a feature is 'active'" do
      let(:active) { true }

      context "with 5%" do
        let(:percentage) { 5 }

        describe "#enabled?" do
          it "returns true for ~5% of users" do
            expect(calculate_active_count(subject, percentage)).to be < 15
          end
        end
      end

      context "with 95%" do
        let(:percentage) { 95 }

        describe "#enabled?" do
          it "returns true for ~95% of users" do
            expect(calculate_active_count(subject, percentage)).to be > 85
            expect(calculate_active_count(subject, percentage)).to be < 100
          end
        end
      end

      context "when no user_id is passed" do
        let(:percentage) { 95 }

        describe "#enabled?" do
          it "returns false" do
            expect(subject.enabled?).to eq(false)
          end
        end
      end
    end

    context "when the feature is NOT 'active'" do
      let(:active) { false }
      let(:percentage) { 95 }

      describe "#enabled?" do
        it "returns false" do
          expect(calculate_active_count(subject, percentage)).to eq(0)
        end
      end
    end
  end

  describe "a feature configured for both user groups and a percentage of users" do
    let(:subject) do
      described_class.new(
        name: name,
        active: active,
        user_group_list: user_group_list,
        percentage: percentage
      )
    end

    context "when the feature is 'active'" do
      let(:active) { true }

      context "and the user matches on the user_group configuration" do
        let(:user_group_list) { %w(admin editor) }
        let(:percentage) { 5 }

        describe "#enabled?" do
          it "returns true" do
            expect(subject.enabled?(user_group: "admin", user_id: "12345")).to eq(true)
          end
        end
      end

      context "and the user does not match the user_groups, but does fall into the percentage" do
        let(:user_group_list) { %w(admin editor) }
        let(:percentage) { 100 }

        describe "#enabled?" do
          it "returns true" do
            expect(subject.enabled?(user_group: "qwerty", user_id: "12345")).to eq(true)
          end
        end
      end

      context "and the user matches neither the user_groups or falls into the percentage" do
        let(:user_group_list) { %w(admin editor) }
        let(:percentage) { 0 }

        describe "#enabled?" do
          it "returns false" do
            expect(subject.enabled?(user_group: "qwerty", user_id: "12345")).to eq(false)
          end
        end
      end

      context "when the user_group and/or user_id params are not passed" do
        let(:user_group_list) { %w(admin editor) }
        let(:percentage) { 100 }

        describe "#enabled?" do
          it "returns false" do
            expect(subject.enabled?).to eq(false)
          end
        end
      end
    end

    context "when the feature is NOT 'active'" do
      let(:active) { false }
      let(:user_group_list) { %w(admin editor) }
      let(:percentage) { 100 }

      describe "#enabled?" do
        it "returns false" do
          expect(subject.enabled?(user_group: "admin", user_id: "12345")).to eq(false)
        end
      end
    end
  end
end

def calculate_active_count(feature, _percentage)
  (0...100).map { |id| feature.enabled?(user_id: id.to_s) }
    .count { |val| val == true }
end
