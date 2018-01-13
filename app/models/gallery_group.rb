class GalleryGroup < Tag
  scope :ordered_by_gallery_tag, -> { order('gallery_tags.id ASC') }
end
