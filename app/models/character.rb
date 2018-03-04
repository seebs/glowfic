class Character < ApplicationRecord
  include Presentable

  belongs_to :user, optional: false
  belongs_to :template, inverse_of: :characters, optional: true
  belongs_to :default_icon, class_name: 'Icon', inverse_of: false, optional: true
  belongs_to :character_group, optional: true
  has_many :replies, dependent: false
  has_many :posts, dependent: false # These are handled in callbacks
  has_many :aliases, class_name: 'CharacterAlias', inverse_of: :character, dependent: :destroy

  has_many :characters_galleries, inverse_of: :character, dependent: :destroy
  accepts_nested_attributes_for :characters_galleries, allow_destroy: true
  has_many :galleries, through: :characters_galleries, dependent: :destroy
  has_many :icons, -> { group('icons.id').order('LOWER(keyword)') }, through: :galleries

  has_many :character_tags, inverse_of: :character, dependent: :destroy
  has_many :settings, -> { order('character_tags.id ASC') }, through: :character_tags, source: :setting
  has_many :gallery_groups, -> { order('character_tags.id ASC') }, through: :character_tags, source: :gallery_group, dependent: :destroy

  validates :name, presence: true
  validate :valid_group, :valid_galleries, :valid_default_icon

  attr_accessor :group_name

  after_destroy :clear_char_ids

  accepts_nested_attributes_for :template, reject_if: :all_blank

  nilify_blanks

  audited on: :update, mod_only: true

  def editable_by?(user)
    return false unless user
    return true if user_id == user.id
    user.has_permission?(:edit_characters)
  end

  def deletable_by?(user)
    return false unless user
    return true if user_id == user.id
    user.has_permission?(:delete_characters)
  end

  def recent_posts
    return @recent unless @recent.nil?
    reply_ids = replies.group(:post_id).pluck(:post_id)
    post_ids = posts.select(:id).map(&:id)
    @recent ||= Post.where(id: (post_ids + reply_ids).uniq).order('tagged_at desc')
  end

  def selector_name
    [name, template_name, screenname].compact.join(' | ')
  end

  def reorder_galleries(_gallery=nil)
    # public so that it can be called from CharactersGallery.after_destroy
    galleries = CharactersGallery.where(character_id: id).order('section_order asc')
    return unless galleries.present?

    galleries.each_with_index do |other, index|
      next if other.section_order == index
      other.section_order = index
      other.save
    end
  end

  def ungrouped_gallery_ids
    characters_galleries.reject(&:added_by_group?).map(&:gallery_id)
  end

  # WARNING: this method *will make changes* when used, not just when saved!!!
  # This is so it can interact with group_gallery_ids properly instead of having to use an intricate system to find the current character galleries prior to persisting
  # i.e. it's so ungrouped_gallery_ids= and various callbacks for gallery_group_ids= interact properly
  def ungrouped_gallery_ids=(new_ids)
    new_ids -= ['']
    new_ids = new_ids.map(&:to_i)
    group_gallery_ids = gallery_groups.joins(:gallery_tags).except(:order).pluck('distinct gallery_tags.gallery_id')
    new_chargals = []
    transaction do
      characters_galleries.each do |char_gal|
        gallery_id = char_gal.gallery_id
        if new_ids.include?(gallery_id)
          # add relevant old galleries, making sure added_by_group is false
          char_gal.added_by_group = false
          new_chargals << char_gal
          new_ids.delete(gallery_id)
        elsif group_gallery_ids.include?(gallery_id)
          # add relevant old group galleries, added_by_group being true
          char_gal.added_by_group = true
          new_chargals << char_gal
          group_gallery_ids.delete(gallery_id)
        else
          # destroy joins that are not in the new set of IDs
          char_gal.destroy
        end
      end
      new_ids.each do |gallery_id|
        # add any leftover new galleries
        new_chargals << CharactersGallery.new(gallery_id: gallery_id, character_id: id, added_by_group: false)
      end
      # leftover galleries from gallery groups will be added by that model
      self.characters_galleries = new_chargals
      if persisted?
        self.update_attributes(characters_galleries: new_chargals)
      else
        self.assign_attributes(characters_galleries: new_chargals)
      end
    end
  end

  def character_gallery_for(gallery)
    characters_galleries.find_by(gallery_id: gallery)
  end

  private

  def valid_group
    return unless character_group_id == 0
    @group = CharacterGroup.new(user: user, name: group_name)
    return if @group.valid?
    @group.errors.messages.each do |k, v|
      v.each { |val| errors.add('group '+k.to_s, val) }
    end
  end

  def valid_galleries
    if galleries.present? && galleries.detect{|g| g.user_id != user.id}
      errors.add(:galleries, "must be yours")
    end
  end

  def valid_default_icon
    return unless default_icon.present?
    return if default_icon.user_id == user_id
    errors.add(:default_icon, "must be yours")
  end

  def clear_char_ids
    UpdateModelJob.perform_later(Post.to_s, {character_id: id}, {character_id: nil})
    UpdateModelJob.perform_later(Reply.to_s, {character_id: id}, {character_id: nil})
    ReplyDraft.where(character_id: id).update_all(character_id: nil)
    User.where(active_character_id: id).update_all(active_character_id: nil)
  end
end
