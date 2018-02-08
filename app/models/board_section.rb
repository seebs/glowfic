class BoardSection < ApplicationRecord
  include Orderable
  include Presentable

  belongs_to :board, inverse_of: :board_sections, optional: false
  has_many :posts, inverse_of: :section, foreign_key: :section_id

  validates_presence_of :name

  after_destroy :clear_post_values

  scope :ordered, -> { order(section_order: :asc) }

  private

  def clear_post_values
    Post.where(section_id: id).each do |post|
      post.section_id = nil
      post.save
    end
  end

  def ordered_attributes
    [:board_id]
  end
end
