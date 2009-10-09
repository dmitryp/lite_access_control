$:.unshift(File.join(File.dirname(__FILE__), '..'))

require 'rubygems'
require 'spec'

require 'activesupport'
require 'lib/lite_access_control'

class Obj
  include LiteAccessControl
  set_rights(
    :view_notifications   => {:controller => "main", :actions => ["dashboard"]  },
    :place_single_orders  => {:controller => "orders", :actions => ["new"] },
    :place_bulk_orders    => {:controller => "orders", :actions => ["new", "multi"] },
    :manage_invoices      => {:controller => "invoices", :actions => :all},
    :review_invoices      => {:controller => "invoices", :actions => ["show"]}
  )
  
  # AccessControl::RIGHTS = {
  #   :view_notifications   => {:controller => "main", :actions => ["dashboard"]  },
  #   :place_single_orders  => {:controller => "orders", :actions => ["new"] },
  #   :place_bulk_orders    => {:controller => "orders", :actions => ["new", "multi"] },
  #   :manage_invoices      => {:controller => "invoices", :actions => :all},
  #   :review_invoices      => {:controller => "invoices", :actions => ["show"]}
  # }
  
  attr_accessor :controller_name, :action_name
  def initialize
    @controller_name = "orders"
    @action_name = "new"
  end
end

class UserObj
  attr_accessor :permissions
  def initialize
    @permissions = [:place_bulk_orders]
  end
  
  def permissions
    @permissions
  end
end

module LiteAccessControl
  describe LiteAccessControl do
    before(:each) do
      @obj = Obj.new
      @user = UserObj.new
    end

    context "starting up" do
      it "should return reversed rights hash" do
        @obj.send(:reversed_rights).sort.should == (
          {
            'invoices'  => {:all_controller_actions=>[:manage_invoices], "show" => [:review_invoices]},
            'main'      => {"dashboard" => [:view_notifications]},
            'orders'    => {"new" => [:place_single_orders, :place_bulk_orders], "multi" => [:place_bulk_orders]},
          }.sort
        )
      end 

      it "should return required permissions and actions" do
        @obj.send(:lookup_by_controller_and_action, 'orders', 'new').should == ([:place_single_orders, :place_bulk_orders])
      end
      
      it "should return true if users granted permissions" do
        @obj.access_control(@user).should be_true
      end


      it "should return false if user has no any permissions" do
        @user.permissions = []
        lambda{ @obj.access_control(@user)}.should raise_error(LiteAccessControl::AccessDenied)
      end

      it "should raise AccessDenied if user has unsuitable permissions" do
        @user.permissions = [:view_notifications]
        lambda{ @obj.access_control(@user)}.should raise_error(LiteAccessControl::AccessDenied)
      end

      it "should return true if current controller does not require permissions" do
        @obj.controller_name = 'news'
        @user.permissions = [:view_notifications]
        @obj.access_control(@user).should be_true
      end

      it "should return true if current controller does not require permissions and user permissions is empty" do
        @obj.controller_name = 'news'
        @user.permissions = []
        @obj.access_control(@user).should be_true
      end

      it "should return true if current action does not require permissions and user permissions is empty" do
        @obj.action_name = 'destroy'
        @obj.access_control(@user).should be_true
      end

      it "should return true if current controller required permissions to all actions" do
        @obj.controller_name = 'invoices'
        lambda{ @obj.access_control(@user)}.should raise_error(LiteAccessControl::AccessDenied)
        
        @user.permissions << :manage_invoices
        @obj.access_control(@user).should be_true
        
        @obj.action_name = 'show'
        @obj.access_control(@user).should be_true
        
        @user.permissions << :review_invoices
        @obj.action_name = 'show'
        @obj.access_control(@user).should be_true
        
        @user.permissions << :review_invoices
        @obj.action_name = 'destroy'
        @obj.access_control(@user).should be_true
      end

    end
  end
end
