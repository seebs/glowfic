module Writable
  extend ActiveSupport::Concern

  included do
    belongs_to :character
    belongs_to :icon
    belongs_to :user

    attr_accessible :character, :character_id, :user, :user_id, :icon, :icon_id, :content

    validates_presence_of :user, :content
    validate :character_ownership, :icon_ownership

    private

    def character_ownership
      return true unless character
      return true if character.user_id == user_id
      errors.add(:character, "must be yours")
    end

    def icon_ownership
      return true unless icon
      return true if icon.user_id == user_id
      errors.add(:icon, "must be yours")
    end
  end
end