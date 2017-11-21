# frozen_string_literal: true
class IndexesController < CrudController
  def index
    super
    @indexes = Index.order('id asc').paginate(per_page: 25, page: page)
  end

  def show
    super
    @sectionless = @index.posts.where(index_posts: {index_section_id: nil})
    @sectionless = @sectionless.order('index_posts.section_order asc')
    @sectionless = posts_from_relation(@sectionless, true, false, ', index_posts.description as index_description')
    @sectionless = @sectionless.select { |p| p.visible_to?(current_user) }
  end

  private

  def permitted_params
    params.fetch(:index, {}).permit(:name, :description, :privacy, :open_to_anyone)
  end

  def before_create
    @model.user = current_user
  end
end
