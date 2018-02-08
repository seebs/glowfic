class Board < ApplicationRecord
  include Presentable
  include Viewable

  ID_SITETESTING = 4

  has_many :posts
  has_many :board_sections, dependent: :destroy
  has_many :favorites, as: :favorite, dependent: :destroy
  belongs_to :creator, class_name: 'User', optional: false

  has_many :board_authors, inverse_of: :board
  has_many :board_coauthors, -> { where(cameo: false) }, class_name: 'BoardAuthor', inverse_of: :board
  has_many :coauthors, class_name: 'User', through: :board_coauthors, source: :user
  has_many :board_cameos, -> { where(cameo: true) }, class_name: 'BoardAuthor', inverse_of: :board
  has_many :cameos, class_name: 'User', through: :board_cameos, source: :user

  validates_presence_of :name

  after_destroy :move_posts_to_sandbox

  scope :ordered, -> { order(pinned: :desc, name: :asc) }

  def writers
    @writers ||= coauthors + [creator]
  end

  def writer_ids
    coauthor_ids + [creator_id]
  end

  def open_to?(user)
    return false unless user
    return true if open_to_anyone?
    return true if creator_id == user.id
    board_authors.where(user_id: user.id).exists?
  end

  def open_to_anyone?
    !board_authors.exists?
  end

  def editable_by?(user)
    return false unless user
    return true if creator_id == user.id
    return true if user.has_permission?(:edit_continuities)
    board_coauthors.where(user_id: user.id).exists?
  end

  def ordered?
    !open_to_anyone? || board_sections.exists?
  end

  private

  def move_posts_to_sandbox
    # TODO don't hard code sandbox board_id
    UpdateModelJob.perform_later(Post.to_s, {board_id: id}, {board_id: 3, section_id: nil})
  end

  def fix_ordering
    # this should ONLY be called by an admin for emergency fixes
    board_sections.ordered.each_with_index do |section, index|
      next if section.section_order == index
      section.update_attribute(:section_order, index)
    end
    posts.where(section_id: nil).ordered_in_section.each_with_index do |post, index|
      next if post.section_order == index
      post.update_attribute(:section_order, index)
    end
  end
end
