require "spec_helper"

describe Roles::Role do
  before do
    User.rolify
    Forum.resourcify
    reset_data
    @admin = User.first
  end

  let(:board_first){ Board.first }
  let(:board_last){ Board.last }

  describe "#with_role" do
    before do
      @admin.add_role(:admin)
      @admin.add_role(:moderator, board_first)
      role = @admin.add_role(:godfather, Board)
    end

    specify { User.should respond_to :with_role }
    specify { User.with_role(:admin).should == [@admin] }
    specify { User.with_role(:moderator, board_first).should == [@admin] }
    specify { User.with_role(:moderator, board_first.becomes(Forum)).should == [@admin] }
    specify { User.with_role(:moderator, Board).should == [] }
    specify { User.with_role(:moderator, Forum).should == [] }
    specify { User.with_role(:godfather, Board).should == [@admin] }
    specify { User.with_role(:godfather, Forum).should_not == [@admin] }
  end

  describe ".add_role for STI resource" do

    it "should be able to add role on STI class" do
      @admin.add_role :moderator, Board
      @admin.has_role?(:moderator, Board).should be_true
      Role.last.resource_type.should == Board.to_s
    end

    it "should be able to add role on a STI instance and reference base_class" do
      @admin.add_role :moderator, board_first
      @admin.has_role?(:moderator, board_first).should be_true
      Role.last.resource_type.should == Board.base_class.to_s
    end
    
    it "should add similiar roles across STI classes" do
      @admin.add_role :moderator, Board
      @admin.add_role :moderator, Forum
      @admin.roles.count.should == 2
    end
    
    it "should not add duplicate roles on STI instances" do
      @admin.add_role :moderator, board_first
      @admin.add_role :moderator, board_first.becomes(Forum)
      @admin.roles.count.should == 1
    end
  end

  describe ".remove_role" do
     it "should be able to remove role on STI class" do
       @admin.add_role :moderator, Board
       @admin.has_role?(:moderator, Board).should be_true
       @admin.remove_role :moderator, Board
       @admin.has_role?(:moderator, Board).should be_false
     end
  
     it "should be able to remove role on a Board instance using base_class" do
       @admin.add_role :moderator, board_first
       @admin.has_role?(:moderator, board_first).should be_true
       @admin.remove_role :moderator, board_first.becomes(Forum)
       @admin.has_role?(:moderator, board_first).should be_false
     end
   end
  
   describe ".has_role?" do
     it "should be able to has_role? on Board class and respect class type" do
       @admin.add_role :moderator, Board
       @admin.add_role :teacher, Board
       @admin.has_role?(:moderator, Board).should be_true
       @admin.has_role?(:teacher, Board).should be_true
       @admin.has_role?(:moderator, Forum).should be_false
       @admin.has_role?(:teacher, Forum).should be_false
     end
  
     it "should be able to has_role? on a Board instance and respect base_class" do
       @admin.add_role :moderator, board_first
       @admin.add_role :teacher, board_first
       @admin.has_role?(:moderator, board_first).should be_true
       @admin.has_role?(:teacher, board_first).should be_true
       @admin.has_role?(:moderator, board_first).should be_true
       @admin.has_role?(:teacher, board_first).should be_true
       @admin.has_role?(:moderator, board_first.becomes(Forum)).should be_true
       @admin.has_role?(:teacher, board_first.becomes(Forum)).should be_true
     end
   end
  
   describe ".role_names" do
     it "should be able to list role names on Board class" do
       @admin.add_role :moderator, Board
       @admin.add_role :teacher, Board
       @admin.role_names(Board).should == ["moderator", "teacher"]
       @admin.role_names(Forum).should_not == ["moderator", "teacher"]
     end
  
     it "should be able to list role names on a Board instance" do
       @admin.add_role :moderator, board_first
       @admin.add_role :teacher, board_first
       @admin.role_names(board_first).should == ["moderator", "teacher"]
       @admin.role_names(board_first.becomes(Forum)).should == ["moderator", "teacher"]
     end
   end
  
   describe ".resources_with_role" do
     before do
       @admin.add_role(:moderator, board_first)
       @admin.add_role(:moderator, board_last)
       @admin.add_role(:teacher, board_last)
     end
  
     it "should be able to find all instances of which user has any role through the instance base_class" do
       @admin.resources_with_role(Board).should =~ [board_first, board_last]
       @admin.resources_with_role(Forum).should =~ [board_first, board_last]
     end
  
     it "should be able to find all resources of which user has specific role" do
       @admin.resources_with_role(Board, :moderator).should =~ [board_first, board_last]
       @admin.resources_with_role(Board, :teacher).should =~ [board_last]
       @admin.resources_with_role(Forum, :moderator).should =~ [board_first, board_last]
       @admin.resources_with_role(Forum, :teacher).should =~ [board_last]
     end
   end
  
   describe "roles get destroyed when user destroyed" do
     before do
       @admin.roles.create :name => "teacher"
       @admin.roles.create :name => "moderator", :resource_type => "Board"
       @admin.roles.create :name => "admin", :resource => board_first
     end
  
     it "should remove the roles binded to this instance" do
       expect { @admin.destroy }.to change { Role.count }.by(-3)
     end
   end
end
