require "../spec_helper"
require "../../src/bandiera/feature"

Spec2.describe Bandiera::Feature do
  subject { described_class.new(name: name, active: active) }

  let(:name)   { "feature_name" }

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
      subject do
        described_class.new(
          name:            name,
          active:          active,
          user_group_list: user_group_list
        )
      end

      let(:user_group)  { "admin" }
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
        let(:active)          { true }
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
      subject do
        described_class.new(
          name:             name,
          active:           active,
          user_group_regex: user_group_regex
        )
      end

      let(:user_group)       { "admin" }
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
      subject do
        described_class.new(
          name:             name,
          active:           active,
          user_group_list:  user_group_list,
          user_group_regex: user_group_regex
        )
      end

      let(:user_group_list)  { %w(editor) }
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
end
