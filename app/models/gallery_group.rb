class GalleryGroup < Tag
  scope :ordered_by_gallery_tag, -> { order('gallery_tags.id ASC') }
  scope :ordered_by_char_tag, -> { order('character_tags.id ASC') }
end
