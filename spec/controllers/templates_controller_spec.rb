require "spec_helper"

RSpec.describe TemplatesController do
  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "works" do
      login
      get :new
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq("New Template")
      expect(assigns(:template)).to be_a_new_record
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      login
      post :create
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("Your template could not be saved.")
      expect(assigns(:page_title)).to eq("New Template")
      expect(assigns(:template)).not_to be_valid
      expect(assigns(:template)).to be_a_new_record
    end

    it "works" do
      char = create(:character)
      login_as(char.user)
      post :create, params: { template: {name: 'testtest', description: 'test desc', character_ids: [char.id]} }
      created = Template.last
      expect(response).to redirect_to(template_url(created))
      expect(flash[:success]).to eq("Template saved successfully.")
      expect(created.name).to eq('testtest')
      expect(created.description).to eq('test desc')
      expect(created.characters).to match_array([char])
    end
  end

  describe "GET show" do
    it "requires valid template" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "works logged in" do
      login
      get :show, params: { id: create(:template).id }
      expect(response).to have_http_status(200)
    end

    it "works logged out" do
      get :show, params: { id: create(:template).id }
      expect(response).to have_http_status(200)
    end

    it "sets correct variables" do
      template = create(:template)
      char1 = create(:character, user: template.user, template: template)
      char2 = create(:character, user: template.user, template: template)
      non_char = create(:character)
      template_post = create(:post, user: template.user, character: char1)
      reply_post = create(:post)
      create(:reply, post: reply_post, user: template.user, character: char2)
      create(:post, character: non_char, user: non_char.user)

      get :show, params: { id: template.id }
      expect(assigns(:page_title)).to eq(template.name)
      expect(assigns(:posts).map(&:id)).to eq([reply_post.id, template_post.id])
      expect(assigns(:user)).to eq(template.user)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid template" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "requires your template" do
      template = create(:template)
      login
      get :edit, params: { id: template.id }
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("That is not your template.")
    end

    it "works" do
      template = create(:template)
      login_as(template.user)
      get :edit, params: { id: template.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq("Edit Template: #{template.name}")
      expect(assigns(:template)).to eq(template)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid template" do
      login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "requires your template" do
      template = create(:template)
      login
      put :update, params: { id: template.id }
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("That is not your template.")
    end

    it "requires valid params" do
      template = create(:template)
      login_as(template.user)
      put :update, params: { id: template.id, template: {name: ''} }
      expect(assigns(:template)).not_to be_valid
      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq("Your template could not be saved.")
    end

    it "works" do
      template = create(:template)
      char = create(:character, user: template.user)
      new_name = template.name + 'new'
      login_as(template.user)

      put :update, params: { id: template.id, template: {name: new_name, description: 'new desc', character_ids: [char.id]} }
      expect(response).to redirect_to(template_url(template))
      expect(flash[:success]).to eq("Template saved successfully.")

      template.reload
      expect(template.name).to eq(new_name)
      expect(template.description).to eq('new desc')
      expect(template.characters).to match_array([char])
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid template" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "requires your template" do
      user = create(:user)
      login_as(user)
      template = create(:template)
      delete :destroy, params: { id: template.id }
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("That is not your template.")
    end

    it "succeeds" do
      template = create(:template)
      login_as(template.user)
      delete :destroy, params: { id: template.id }
      expect(response).to redirect_to(characters_url)
      expect(flash[:success]).to eq("Template deleted successfully.")
    end

    it "handles destroy failure" do
      template = create(:template)
      character = create(:character, user: template.user, template: template)
      login_as(template.user)
      expect_any_instance_of(Template).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: template.id }
      expect(response).to redirect_to(template_url(template))
      expect(flash[:error]).to eq({message: "Template could not be deleted.", array: []})
      expect(character.reload.template).to eq(template)
    end
  end
end
