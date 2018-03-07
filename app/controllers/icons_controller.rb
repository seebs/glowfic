# frozen_string_literal: true
class IconsController < UploadingController
  before_action :login_required, except: :show
  before_action :find_icon, except: :delete_multiple
  before_action :require_own_icon, only: [:edit, :update, :replace, :do_replace, :destroy, :avatar]
  before_action :set_s3_url, only: :edit

  def delete_multiple
    gallery = Gallery.find_by_id(params[:gallery_id])
    icon_ids = (params[:marked_ids] || []).map(&:to_i).reject(&:zero?)
    if icon_ids.empty? || (icons = Icon.where(id: icon_ids)).empty?
      flash[:error] = "No icons selected."
      redirect_to galleries_path and return
    end

    if params[:gallery_delete]
      unless gallery
        flash[:error] = "Gallery could not be found."
        redirect_to galleries_path and return
      end

      unless gallery.user_id == current_user.id
        flash[:error] = "That is not your gallery."
        redirect_to galleries_path and return
      end

      icons.each do |icon|
        next unless icon.user_id == current_user.id
        gallery.icons.destroy(icon)
      end

      flash[:success] = "Icons removed from gallery."
      icon_redirect(gallery) and return
    end

    icons.each do |icon|
      next unless icon.user_id == current_user.id
      icon.destroy
    end
    flash[:success] = "Icons deleted."
    icon_redirect(gallery) and return
  end

  def show
    @page_title = @icon.keyword
    if params[:view] == 'posts'
      arel = Post.arel_table
      where_calc = arel[:icon_id].eq(@icon.id).or(arel[:id].in(Reply.where(icon_id: @icon.id).pluck('distinct post_id')))
      @posts = posts_from_relation(Post.where(where_calc).order('tagged_at desc'))
    elsif params[:view] == 'galleries'
      use_javascript('galleries/expander_old')
    end
  end

  def edit
    @page_title = 'Edit Icon: ' + @icon.keyword
    use_javascript('galleries/update_existing')
    use_javascript('galleries/uploader')
  end

  def update
    unless @icon.update_attributes(icon_params)
      flash.now[:error] = {}
      flash.now[:error][:message] = "Your icon could not be saved due to the following problems:"
      flash.now[:error][:array] = @icon.errors.full_messages
      @page_title = 'Edit icon: ' + @icon.keyword_was
      render action: :edit and return
    end

    flash[:success] = "Icon updated."
    redirect_to icon_path(@icon)
  end

  def replace
    @page_title = "Replace Icon: " + @icon.keyword
    all_icons = if @icon.has_gallery?
      @icon.galleries.map(&:icons).flatten.uniq.compact - [@icon]
    else
      current_user.galleryless_icons - [@icon]
    end
    @alts = all_icons.sort_by{|i| i.keyword.downcase }
    use_javascript('icons')
    gon.gallery = Hash[all_icons.map { |i| [i.id, {url: i.url, keyword: i.keyword}] }]
    gon.gallery[''] = {url: view_context.image_path('icons/no-icon.png'), keyword: 'No Icon'}

    all_posts = Post.where(icon_id: @icon.id) + Post.where(id: Reply.where(icon_id: @icon.id).pluck('distinct post_id'))
    @posts = all_posts.uniq
  end

  def do_replace
    unless params[:icon_dropdown].blank? || (new_icon = Icon.find_by_id(params[:icon_dropdown]))
      flash[:error] = "Icon could not be found."
      redirect_to replace_icon_path(@icon) and return
    end

    if new_icon && new_icon.user_id != current_user.id
      flash[:error] = "That is not your icon."
      redirect_to replace_icon_path(@icon) and return
    end

    wheres = {icon_id: @icon.id}
    wheres[:post_id] = params[:post_ids] if params[:post_ids].present?
    UpdateModelJob.perform_later(Reply.to_s, wheres, {icon_id: new_icon.try(:id)})
    wheres[:id] = wheres.delete(:post_id) if params[:post_ids].present?
    UpdateModelJob.perform_later(Post.to_s, wheres, {icon_id: new_icon.try(:id)})

    flash[:success] = "All uses of this icon will be replaced."
    redirect_to icon_path(@icon)
  end

  def destroy
    gallery = @icon.galleries.first if @icon.galleries.count == 1
    if @icon.destroy
      flash[:success] = "Icon deleted successfully."
      redirect_to gallery_path(gallery) and return if gallery
      redirect_to galleries_path
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Your icon could not be deleted due to the following problems:"
      flash.now[:error][:array] = @icon.errors.full_messages
      redirect_to gallery_path(gallery)
    end
  end

  def avatar
    if current_user.update_attributes(avatar: @icon)
      flash[:success] = "Avatar has been set!"
    else
      flash[:error] = "Something went wrong."
    end
    redirect_to icon_path(@icon)
  end

  private

  def find_icon
    unless (@icon = Icon.find_by_id(params[:id]))
      flash[:error] = "Icon could not be found."
      redirect_to galleries_path
    end
  end

  def require_own_icon
    if @icon.user_id != current_user.id
      flash[:error] = "That is not your icon."
      redirect_to galleries_path
    end
  end

  def icon_redirect(gallery)
    if params[:return_to] == 'index'
      redirect_to galleries_path(anchor: "gallery-#{gallery.id}")
    elsif params[:return_tag].present? && (tag = Tag.find_by_id(params[:return_tag]))
      redirect_to tag_path(tag, anchor: "gallery-#{gallery.id}")
    elsif gallery
      redirect_to gallery_path(id: gallery.id)
    else
      redirect_to user_gallery_path(id: 0, user_id: current_user.id)
    end
  end

  def icon_params
    params.fetch(:icon, {}).permit(:url, :keyword, :credit, :s3_key)
  end
end
