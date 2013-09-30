require "spec_helper"

describe Roles::Resource do
  before do
    User.rolify
    Forum.resourcify
    reset_data
  end

  # Users
  let(:admin)   { User.first }
  let(:tourist) { User.last }

  describe "#users_with_role" do
    before do
      admin.add_role(:moderator, Board.first)
      admin.add_role(:admin, Board.first)
      tourist.add_role(:moderator, Board.first)
    end

    context "on a Board instance" do
      subject { Board.first }
      it { should respond_to :users_with_role }
      specify { subject.users_with_role.should == [admin, tourist] }
      specify { subject.users_with_role(:moderator).should == [admin, tourist] }
      specify { subject.users_with_role(:admin).should == [admin] }
      specify { subject.users_with_role(:teacher).should == [] }
    end
  end
end