# frozen_string_literal: true
class TemplatesController < ApplicationController
  before_action :login_required, except: :show
  before_action :find_template, only: [:show, :destroy, :edit, :update]
  before_action :require_own_template, only: [:edit, :update, :destroy]
  before_action :editor_setup, only: [:new, :edit]

  def new
    @template = Template.new
    @page_title = "New Template"
  end

  def create
    @template = Template.new(template_params)
    @template.user = current_user
    if @template.save
      flash[:success] = "Template saved successfully."
      redirect_to template_path(@template)
    else
      flash.now[:error] = "Your template could not be saved."
      editor_setup
      @page_title = "New Template"
      render :action => :new
    end
  end

  def show
    @user = @template.user
    character_ids = @template.characters.pluck(:id)
    post_ids = Reply.where(character_id: character_ids).pluck('distinct post_id')
    arel = Post.arel_table
    where = arel[:character_id].in(character_ids).or(arel[:id].in(post_ids))
    @posts = posts_from_relation(Post.where(where).order('tagged_at desc'))
    @page_title = @template.name
  end

  def edit
    @page_title = 'Edit Template: ' + @template.name
  end

  def update
    unless @template.update_attributes(template_params)
      flash.now[:error] = "Your template could not be saved."
      editor_setup
      @page_title = 'Edit Template: ' + @template.name_was
      render :action => :edit and return
    end

    flash[:success] = "Template saved successfully."
    redirect_to template_path(@template)
  end

  def destroy
    if @template.destroy
      flash[:success] = "Template deleted successfully."
      redirect_to characters_path
    else
      flash[:error] = {}
      flash[:error][:message] = "Template could not be deleted because of the following problems:"
      flash[:error][:array] = @template.errors.full_messages
      redirect_to template_path(@template)
    end
  end

  private

  def editor_setup
    @selectable_characters = @template.try(:characters) || []
    @selectable_characters += current_user.characters.where(template_id: nil).order('LOWER(name)')
    @selectable_characters.uniq!
    @character_ids = template_params[:character_ids] if template_params.key?(:character_ids)
    @character_ids ||= @template.try(:character_ids) || []
  end

  def find_template
    unless (@template = Template.find_by_id(params[:id]))
      flash[:error] = "Template could not be found."
      redirect_to characters_path and return
    end
  end

  def require_own_template
    return true if @template.user_id == current_user.id
    flash[:error] = "That is not your template."
    redirect_to characters_path
  end

  def template_params
    params.fetch(:template, {}).permit(:name, :description, character_ids: [])
  end
end
