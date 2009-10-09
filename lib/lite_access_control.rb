module LiteAccessControl

  class AccessError < Exception; end
  class AccessDenied < AccessError; end
  
  module ClassMethods
    def set_rights(rights)
      write_inheritable_attribute :rights, rights
    end
  end
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def access_control(user)
    required_rights = lookup_by_controller_and_action(controller_name, action_name)
    return true if required_rights.blank?
    raise AccessDenied if user.permissions.blank? || (user.permissions & required_rights).empty?
    true
  end
  
  private
  def rights
    @rights ||= self.class.read_inheritable_attribute(:rights) || {}
  end
  
  def reversed_rights
    reversed_rights = {}
    rights.each do |r|
      permission_name = r[0]
      controller_name = r[1][:controller]
      action_names = r[1][:actions]
      
      tmp_rules_set = reversed_rights.fetch(controller_name, {})
      
      if action_names == :all
        tmp_rules_set[:all_controller_actions]= (tmp_rules_set[:all_controller_actions]||[] << permission_name.to_sym)
      else
        action_names.each do |a|
          tmp_rules_set[a] = (tmp_rules_set[a] || [] ) << permission_name
        end
      end
      
      reversed_rights[controller_name] = tmp_rules_set
    end
    
    reversed_rights
  end
  
  # Lookup rights name by controller name
  def lookup_by_controller_and_action(controller, action)
    actions = reversed_rights[controller.to_s]
    if actions 
      required_actions = []
      required_actions += actions[action] if actions[action]
      required_actions += actions[:all_controller_actions] if actions[:all_controller_actions]
      required_actions
    end
  end

end# LiteAccessControl
