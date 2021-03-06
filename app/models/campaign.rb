# == Schema Information
# Schema version: 17
#
# Table name: campaigns
#
#  id                  :integer(4)      not null, primary key
#  uuid                :string(36)
#  user_id             :integer(4)
#  assigned_to         :integer(4)
#  name                :string(64)      default(""), not null
#  access              :string(8)       default("Private")
#  status              :string(64)
#  budget              :decimal(12, 2)
#  target_leads        :integer(4)
#  target_conversion   :float
#  target_revenue      :decimal(12, 2)
#  leads_count         :integer(4)
#  opportunities_count :integer(4)
#  revenue             :decimal(12, 2)
#  starts_on           :date
#  ends_on             :date
#  objectives          :text
#  deleted_at          :datetime
#  created_at          :datetime
#  updated_at          :datetime
#

class Campaign < ActiveRecord::Base
  belongs_to  :user
  has_many    :tasks, :as => :asset, :dependent => :destroy, :order => 'created_at DESC'
  has_many    :leads, :dependent => :destroy, :order => "id DESC"
  has_many    :opportunities, :dependent => :destroy, :order => "id DESC"
  has_many    :activities, :as => :subject, :order => 'created_at DESC'
  named_scope :only, lambda { |filters| { :conditions => [ "status IN (?)" + (filters.delete("other") ? " OR status IS NULL" : ""), filters ] } }

  simple_column_search :name, :match => :middle, :escape => lambda { |query| query.gsub(/[^\w\s\-]/, "").strip }

  uses_mysql_uuid
  uses_user_permissions
  acts_as_commentable
  acts_as_paranoid

  validates_presence_of :name, :message => "^Please specify campaign name."
  validates_uniqueness_of :name, :scope => :user_id
  validate :start_and_end_dates
  validate :users_for_shared_access

  SORT_BY = {
    "name"           => "campaigns.name ASC",
    "target leads"   => "campaigns.target_leads DESC",
    "target revenue" => "campaigns.target_revenue DESC",
    "actual leads"   => "campaigns.leads_count DESC",
    "actual revenue" => "campaigns.revenue DESC",
    "start date"     => "campaigns.starts_on DESC",
    "end date"       => "campaigns.ends_on DESC",
    "date created"   => "campaigns.created_at DESC",
    "date updated"   => "campaigns.updated_at DESC"
  }

  # Default values provided through class methods.
  #----------------------------------------------------------------------------
  def self.per_page ;  20                          ; end
  def self.outline  ;  "long"                      ; end
  def self.sort_by  ;  "campaigns.created_at DESC" ; end

  private
  # Make sure end date > start date.
  #----------------------------------------------------------------------------
  def start_and_end_dates
    if (self.starts_on && self.ends_on) && (self.starts_on > self.ends_on)
      errors.add(:ends_on, "^Please make sure the campaign end date is after the start date.")
    end
  end

  # Make sure at least one user has been selected if the campaign is being shared.
  #----------------------------------------------------------------------------
  def users_for_shared_access
    errors.add(:access, "^Please specify users to share the campaign with.") if self[:access] == "Shared" && !self.permissions.any?
  end

end
