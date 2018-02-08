require "spec_helper"

RSpec.describe UsersController do
  describe "GET index" do
    it "succeeds when logged out" do
      get :index
      expect(response).to have_http_status(200)
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response).to have_http_status(200)
    end

    context "with moieties" do
      render_views

      it "displays the name" do
        create(:user, moiety: 'fed123', moiety_name: 'moietycolor')
        get :index
        expect(response.body).to include('moietycolor')
        expect(response.body).to include('fed123')
      end
    end
  end

  describe "GET new" do
    it "succeeds when logged out" do
      get :new
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "complains when logged in" do
      login
      post :create
      expect(response).to redirect_to(boards_path)
      expect(flash[:error]).to eq('You are already logged in.')
    end
  end

  describe "POST create" do
    it "complains when logged in" do
      login
      post :create
      expect(response).to redirect_to(boards_path)
      expect(flash[:error]).to eq('You are already logged in.')
    end

    it "requires beta secret" do
      post :create
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("This is in beta. Please come back later.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "requires valid fields" do
      post :create, params: { secret: "ALLHAILTHECOIN" }
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("There was a problem completing your sign up.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "rejects short passwords" do
      user = build(:user).attributes.with_indifferent_access.merge(password: 'short', password_confirmation: 'short')
      post :create, params: { secret: 'ALLHAILTHECOIN' }.merge(user: user)
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq('There was a problem completing your sign up.')
      expect(flash[:error][:array]).to eq(['Password is too short (minimum is 6 characters)'])
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
    end

    it "signs you up" do
      pass = 'testpassword'
      user = build(:user).attributes.with_indifferent_access.merge(password: pass, password_confirmation: pass, email: 'testemail@example.com')

      expect {
        post :create, params: { secret: "ALLHAILTHECOIN" }.merge(user: user)
      }.to change{User.count}.by(1)
      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("User created! You have been logged in.")

      new_user = assigns(:current_user)
      expect(new_user).not_to be_nil
      expect(new_user.username).to eq(user[:username])
      expect(new_user.authenticate(user[:password])).to eq(true)
      expect(new_user.email).to eq(user[:email])
    end

    it "allows long passwords" do
      pass = 'this is a long password to test the password validation feature and to see if it accepts this'
      user = build(:user).attributes.with_indifferent_access.merge(password: pass, password_confirmation: pass)
      expect {
        post :create, params: { secret: 'ALLHAILTHECOIN' }.merge(user: user)
      }.to change{User.count}.by(1)
      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("User created! You have been logged in.")
      expect(assigns(:current_user)).not_to be_nil
      expect(assigns(:current_user).username).to eq(user['username'])
      expect(assigns(:current_user).authenticate(pass)).to eq(true)
    end
  end

  describe "GET show" do
    it "requires valid user" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(users_url)
      expect(flash[:error]).to eq("User could not be found.")
    end

    it "works when logged out" do
      user = create(:user)
      get :show, params: { id: user.id }
      expect(response.status).to eq(200)
    end

    it "works when logged in as someone else" do
      user = create(:user)
      login
      get :show, params: { id: user.id }
      expect(response.status).to eq(200)
    end

    it "works when logged in as yourself" do
      user = create(:user)
      login_as(user)
      get :show, params: { id: user.id }
      expect(response.status).to eq(200)
    end

    it "sets the correct variables" do
      user = create(:user)
      posts = Array.new(3) { create(:post, user: user) }
      create(:post)
      get :show, params: { id: user.id }
      expect(assigns(:page_title)).to eq(user.username)
      expect(assigns(:posts).to_a).to match_array(posts)
    end

    it "sorts posts correctly" do
      user = create(:user)
      post1 = create(:post)
      post2 = create(:post, user: user)
      post3 = create(:post)
      create(:reply, post: post3, user: user)
      create(:reply, post: post2)
      create(:reply, post: post1, user: user)
      create(:post)
      get :show, params: { id: user.id }
      expect(assigns(:posts).to_a).to eq([post1, post2, post3])
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires own user" do
      user = create(:user)
      login
      get :edit, params: { id: user.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq('You do not have permission to edit that user.')
    end

    it "succeeds" do
      user_id = login
      get :edit, params: { id: user_id }
      expect(response.status).to eq(200)
    end

    context "with views" do
      render_views

      it "displays options" do
        user_id = login
        get :edit, params: { id: user_id }
      end
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      user = create(:user)
      login_as(user)
      put :update, params: { id: user.id, user: {moiety: 'A'} }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:error]).to eq('There was a problem with your changes.')
    end

    it "does not update another user" do
      user1 = create(:user)
      user2 = create(:user)
      login_as(user1)
      put :update, params: { id: user2.id, user: {email: 'bademail@example.com'} }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq('You do not have permission to edit that user.')
      expect(user2.reload.email).not_to eq('bademail@example.com')
    end

    it "works with valid params" do
      user = create(:user)
      login_as(user)

      user_details = {
        email: 'testuser314@example.com',
        email_notifications: true,
        moiety_name: 'Testmoiety',
        moiety: 'AAAAAA',
        favorite_notifications: false,
        show_user_in_switcher: false,
        default_character_split: 'none'
      }

      # ensure new values are different, so test tests correct things
      user_details.each do |key, value|
        expect(user.public_send(key)).not_to eq(value)
      end

      put :update, params: { id: user.id, user: user_details }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved successfully.')

      user.reload
      user_details.each do |key, value|
        expect(user.public_send(key)).to eq(value)
      end
    end

    it "updates username and still allows login" do
      pass = 'password123'
      user = create(:user, username: 'user123', password: pass)
      expect(user.authenticate(pass)).to eq(true)
      login_as(user)
      put :update, params: { id: user.id, user: {username: 'user124'} }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved successfully.')

      user.reload
      expect(user.username).to eq('user124')
      expect(user.authenticate(pass)).to eq(true)
      expect(user.authenticate(pass + '1')).not_to eq(true)
    end
  end

  describe "POST username" do
    it "complains when logged in" do
      skip "TODO not yet implemented"
    end

    it "requires username" do
      post :username
      expect(response.json['error']).to eq("No username provided.")
    end

    it "finds user" do
      user = create(:user)
      post :username, params: { username: user.username }
      expect(response.json['username_free']).not_to eq(true)
    end

    it "finds free username" do
      user = create(:user)
      post :username, params: { username: user.username + 'nope' }
      expect(response.json['username_free']).to eq(true)
    end
  end

  describe "PUT password" do
    it "requires login" do
      put :password, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires own user" do
      user = create(:user)
      login
      put :password, params: { id: user.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq('You do not have permission to edit that user.')
    end

    it "requires correct password" do
      pass = 'testpass'
      fakepass = 'wrongpass'
      newpass = 'newpass'
      user = create(:user, password: 'testpass')
      login_as(user)

      put :password, params: { id: user.id, old_password: fakepass, user: {password: newpass, password_confirmation: newpass} }

      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq('Incorrect password entered.')
      user.reload
      expect(user.authenticate(pass)).to eq(true)
      expect(user.authenticate(fakepass)).not_to eq(true)
      expect(user.authenticate(newpass)).not_to eq(true)
    end

    it "requires valid password" do
      pass = 'testpass'
      newpass = 'bad'
      user = create(:user, password: pass)
      login_as(user)

      put :password, params: { id: user.id, old_password: pass, user: {password: newpass, password_confirmation: newpass} }

      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq('There was a problem with your changes.')
      expect(user.authenticate(pass)).to eq(true)
      expect(user.authenticate(newpass)).not_to eq(true)
    end

    it "requires valid confirmation" do
      pass = 'testpass'
      newpass = 'newpassword'
      user = create(:user, password: pass)
      login_as(user)

      put :password, params: { id: user.id, old_password: pass, user: {password: newpass, password_confirmation: 'wrongconfirmation'} }

      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq('There was a problem with your changes.')
      user.reload
      expect(user.authenticate(pass)).to eq(true)
      expect(user.authenticate(newpass)).not_to eq(true)
    end

    it "succeeds" do
      pass = 'testpass'
      newpass = 'newpassword'
      user = create(:user, password: pass)
      login_as(user)

      put :password, params: { id: user.id, old_password: pass, user: {password: newpass, password_confirmation: newpass} }

      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved successfully.')
      user.reload
      expect(user.authenticate(pass)).not_to eq(true)
      expect(user.authenticate(newpass)).to eq(true)
    end

    it "has more tests" do
      skip
    end
  end

  describe "GET search" do
    it "works logged in" do
      login
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:search_results)).to be_nil
    end

    it "works logged out" do
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:search_results)).to be_nil
    end

    it "subsearches correctly" do
      firstuser = create(:user, username: 'baa')
      miduser = create(:user, username: 'aba')
      enduser = create(:user, username: 'aab')
      notuser = create(:user, username: 'aaa')
      User.all.each do |user|
        create(:user, username: user.username.upcase + 'c')
      end
      get :search, params: { commit: 'Search', username: 'b' }
      expect(response).to have_http_status(200)
      expect(assigns(:search_results)).to be_present
      expect(assigns(:search_results).count).to eq(6)
    end

    it "orders users correctly" do
      create(:user, username: 'baa')
      create(:user, username: 'aba')
      create(:user, username: 'aab')
      get :search, params: { commit: 'Search', username: 'b' }
      expect(assigns(:search_results).map(&:username)).to eq(['aab', 'aba', 'baa'])
    end
  end
end
