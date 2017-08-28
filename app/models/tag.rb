class Tag < ActiveRecord::Base
  belongs_to :user
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
  has_many :character_tags, dependent: :destroy
  has_many :characters, through: :character_tags
  has_many :gallery_tags, dependent: :destroy
  has_many :galleries, through: :gallery_tags

  validates_presence_of :user, :name, :type
  validates :name, uniqueness: { scope: :type }

  scope :with_item_counts, -> {
    select('(SELECT COUNT(DISTINCT post_tags.post_id) FROM post_tags WHERE post_tags.tag_id = tags.id) AS post_count,
    (SELECT COUNT(DISTINCT gallery_tags.gallery_id) FROM gallery_tags WHERE gallery_tags.tag_id = tags.id) AS gallery_count')
  }

  def editable_by?(user)
    user.try(:admin?)
  end

  def as_json(*)
    {id: self.id, text: self.name}
  end

  def id_for_select
    id || "_#{name}"
  end

  def post_count
    return read_attribute(:post_count) if has_attribute?(:post_count)
    posts.count
  end

  def gallery_count
    return read_attribute(:gallery_count) if has_attribute?(:gallery_count)
    galleries.count
  end

  def merge_with(other_tag)
    transaction do
      PostTag.where(tag_id: other_tag.id).where(post_id: post_tags.pluck('distinct post_id')).delete_all
      PostTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      CharacterTag.where(tag_id: other_tag.id).where(character_id: character_tags.pluck('distinct character_id')).delete_all
      CharacterTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      GalleryTag.where(tag_id: other_tag.id).where(gallery_id: gallery_tags.pluck('distinct gallery_id')).delete_all
      GalleryTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      other_tag.destroy
    end
  end
end
