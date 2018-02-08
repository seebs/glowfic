class Tag < ApplicationRecord
  belongs_to :user, optional: false
  has_many :post_tags, dependent: :destroy, inverse_of: :tag
  has_many :posts, through: :post_tags
  has_many :character_tags, dependent: :destroy, inverse_of: :tag
  has_many :characters, through: :character_tags
  has_many :gallery_tags, dependent: :destroy, inverse_of: :tag
  has_many :galleries, through: :gallery_tags

  TYPES = %w(Setting Label ContentWarning GalleryGroup)

  validates_presence_of :name, :type
  validates :name, uniqueness: { scope: :type }

  scope :ordered_by_type, -> { order(type: :desc).order('lower(name) asc', id: :asc) }

  scope :ordered_by_name, -> { order('lower(name) asc', id: :asc) }

  scope :ordered, -> { order(created_at: :asc, id: :asc) }

  scope :with_item_counts, -> {
    select('(SELECT COUNT(DISTINCT post_tags.post_id) FROM post_tags WHERE post_tags.tag_id = tags.id) AS post_count,
    (SELECT COUNT(DISTINCT character_tags.character_id) FROM character_tags WHERE character_tags.tag_id = tags.id) AS character_count')
  }

  def editable_by?(user)
    return false unless user
    return true if deletable_by?(user)
    return true if user.has_permission?(:edit_tags)
    return false unless is_a?(Setting)
    !owned?
  end

  def deletable_by?(user)
    return false unless user
    return true if user.has_permission?(:delete_tags)
    user.id == user_id
  end

  def as_json(options={})
    tag_json = {id: self.id, text: self.name}
    return tag_json unless options[:include].present?
    if options[:include].include?(:gallery_ids)
      g_tags = gallery_tags.joins(:gallery)
      g_tags = g_tags.where(galleries: {user_id: options[:user_id]}) if options[:user_id].present?
      tag_json[:gallery_ids] = g_tags.pluck(:gallery_id)
    end
    tag_json
  end

  def id_for_select
    return id if persisted? # id present on unpersisted records when associated record is invalid
    "_#{name}"
  end

  def post_count
    return read_attribute(:post_count) if has_attribute?(:post_count)
    posts.count
  end

  def character_count
    return read_attribute(:character_count) if has_attribute?(:character_count)
    characters.count
  end

  def gallery_count
    return read_attribute(:gallery_count) if has_attribute?(:gallery_count)
    galleries.count
  end

  def has_items? # TODO auto destroy when false, and also maybe fix with settings/canons
    post_count + character_count + gallery_count > 0
  end

  def merge_with(other_tag)
    transaction do
      PostTag.where(tag_id: other_tag.id).where(post_id: post_tags.pluck('distinct post_id')).delete_all
      PostTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      CharacterTag.where(tag_id: other_tag.id).where(character_id: character_tags.pluck('distinct character_id')).delete_all
      CharacterTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      GalleryTag.where(tag_id: other_tag.id).where(gallery_id: gallery_tags.pluck('distinct gallery_id')).delete_all
      GalleryTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      TagTag.where(tag_id: other_tag.id, tagged_id: self.id).delete_all
      TagTag.where(tag_id: self.id, tagged_id: other_tag.id).delete_all
      TagTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      TagTag.where(tagged_id: other_tag.id).update_all(tagged_id: self.id)
      other_tag.destroy
    end
  end
end
