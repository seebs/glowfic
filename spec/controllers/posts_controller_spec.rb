require "spec_helper"

RSpec.describe PostsController do
  describe "GET index" do
    it "has a 200 status code" do
      get :index
      expect(response.status).to eq(200)
    end

    it "paginates" do
      26.times do create(:post) end
      get :index
      num_posts_fetched = controller.instance_variable_get('@posts').total_pages
      expect(num_posts_fetched).to eq(2)
    end

    it "only fetches most recent threads" do
      26.times do create(:post) end
      oldest = Post.order('id asc').first
      get :index
      ids_fetched = controller.instance_variable_get('@posts').map(&:id)
      expect(ids_fetched).not_to include(oldest.id)
    end

    it "only fetches most recent threads based on updated_at" do
      26.times do create(:post) end
      oldest = Post.order('id asc').first
      next_oldest = Post.order('id asc').second
      oldest.update_attributes(content: "just to make it update")
      get :index
      ids_fetched = controller.instance_variable_get('@posts').map(&:id)
      expect(ids_fetched).not_to include(next_oldest.id)
    end
  end

  describe "GET search" do
    skip
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "sets relevant fields" do
      user = create(:user)
      character = create(:character, user: user)
      user.update_attributes(active_character: character)
      user.reload
      login_as(user)

      get :new

      expect(response.status).to eq(200)
      expect(assigns(:post)).to be_new_record
      expect(assigns(:post).character).to eq(character)
    end
  end

  describe "POST create" do
    skip
  end

  describe "GET show" do
    it "does not require login" do
      post = create(:post)
      get :show, id: post.id
      expect(response).to have_http_status(200)
    end

    it "requires permission" do
      post = create(:post, privacy: Post::PRIVACY_PRIVATE)
      get :show, id: post.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "works with login" do
      post = create(:post)
      login
      get :show, id: post.id
      expect(response).to have_http_status(200)
    end

    it "marks read multiple times" do
      post = create(:post)
      user = create(:user)
      login_as(user)
      expect(post.last_read(user)).to be_nil
      get :show, id: post.id
      last_read = post.reload.last_read(user)
      expect(last_read).not_to be_nil

      Timecop.freeze(last_read + 1.second) do
        reply = create(:reply, post: post)
        expect(reply.created_at).not_to be_the_same_time_as(last_read)
        get :show, id: post.id
        cur_read = post.reload.last_read(user)
        expect(last_read).not_to be_the_same_time_as(cur_read)
        expect(last_read.to_i).to be < cur_read.to_i
      end
    end

    context "with render_views" do
      render_views

      it "renders HAML with additional attributes" do
        post = create(:post, with_icon: true, with_character: true)
        create(:reply, post: post, with_icon: true, with_character: true)
        get :show, id: post.id
        expect(response.status).to eq(200)
        expect(response.body).to include(post.subject)
        expect(response.body).to include('header-right')
      end

      it "renders HAML for logged in user" do
        post = create(:post)
        create(:reply, post: post)
        character = create(:character)
        login_as(character.user)
        get :show, id: post.id
        expect(response.status).to eq(200)
        expect(response.body).to include('Join Thread')
      end

      it "flat view renders HAML properly" do
        post = create(:post, with_icon: true, with_character: true)
        create(:reply, post: post, with_icon: true, with_character: true)
        get :show, id: post.id, view: 'flat'
        expect(response.status).to eq(200)
        expect(response.body).to include(post.subject)
        expect(response.body).not_to include('header-right')
      end
    end

    # TODO WAY more tests
  end

  describe "GET history" do
    it "requires post" do
      login
      get :history, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "works logged out" do
      get :history, id: create(:post).id
      expect(response.status).to eq(200)
    end

    it "works logged in" do
      login
      get :history, id: create(:post).id
      expect(response.status).to eq(200)
    end
  end

  describe "GET stats" do
    it "requires post" do
      login
      get :stats, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "works logged out" do
      get :stats, id: create(:post).id
      expect(response.status).to eq(200)
    end

    it "works logged in" do
      login
      get :stats, id: create(:post).id
      expect(response.status).to eq(200)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires post" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires your post" do
      login
      post = create(:post)
      get :edit, id: post.id
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "sets relevant fields" do
      user = create(:user)
      character = create(:character, user: user)
      post = create(:post, user: user, character: character)
      expect(post.icon).to be_nil
      login_as(user)

      get :edit, id: post.id

      expect(response.status).to eq(200)
      expect(assigns(:post)).to eq(post)
      expect(assigns(:post).character).to eq(character)
      expect(assigns(:post).icon).to be_nil
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid post" do
      login
      put :update, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    context "mark unread" do

      it "requires valid at_id" do
      end

      it "requires post's at_id" do
      end

      it "notifies Marri about board_read" do
        # TODO fix the board_read thing better
        post = create(:post)
        unread_reply = create(:reply, post: post)
        reply = create(:reply, post: post)
        time = Time.now
        post.board.mark_read(post.user, time)
        skip "todo"
        expect(post.last_read(post.user).time).to be_the_same_time_as(time)
        login_as(post.user)

        put :update, id: post.id, unread: true, at_id: unread_reply.id

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:error]).to eq("You have marked this continuity read more recently than that reply was written; it will not appear in your Unread posts.")
        expect(post.reload.last_read(post.user)).to be_the_same_time_as(time)
      end

      it "works with at_id" do
        post = create(:post)
        unread_reply = create(:reply, post: post)
        reply = create(:reply, post: post)
        time = Time.now
        post.mark_read(post.user, time)
        expect(post.last_read(post.user).time).to be_the_same_time_as(time)
        login_as(post.user)

        put :update, id: post.id, unread: true, at_id: unread_reply.id

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("Post has been marked as read until reply ##{unread_reply.id}.")
        expect(post.reload.last_read(post.user)).to be_the_same_time_as((unread_reply.created_at - 1.second))
      end

      it "works without at_id" do
        post = create(:post)
        user = create(:user)
        post.mark_read(user)
        expect(post.reload.send(:view_for, user)).not_to be_nil
        login_as(user)

        put :update, id: post.id, unread: true

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("Post has been marked as unread")
        expect(post.reload.send(:view_for, user)).to be_a_new_record
      end
    end

    context "change status" do
      skip "TODO"
    end

    context "author lock" do
      skip "TODO"
    end

    context "preview" do
      skip "TODO"
    end

    context "make changes" do
      skip "TODO"
    end
  end

  describe "POST warnings" do
    it "requires a valid post" do
      post :warnings, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires permission" do
      warn_post = create(:post, privacy: Post::PRIVACY_PRIVATE)
      post :warnings, id: warn_post.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "works for logged out" do
      warn_post = create(:post)
      expect(session[:ignore_warnings]).to be_nil
      post :warnings, id: warn_post.id, per_page: 10, page: 2
      expect(response).to redirect_to(post_url(warn_post, per_page: 10, page: 2))
      expect(flash[:success]).to eq("All content warnings have been hidden. Proceed at your own risk.")
      expect(session[:ignore_warnings]).to be_true
    end

    it "works for logged in" do
      warn_post = create(:post)
      user = create(:user)
      expect(session[:ignore_warnings]).to be_nil
      expect(warn_post.send(:view_for, user)).to be_a_new_record
      login_as(user)
      post :warnings, id: warn_post.id
      expect(response).to redirect_to(post_url(warn_post))
      expect(flash[:success]).to eq("Content warnings have been hidden for this thread. Proceed at your own risk.")
      expect(session[:ignore_warnings]).to be_nil
      view = warn_post.reload.send(:view_for, user)
      expect(view).not_to be_a_new_record
      expect(view.warnings_hidden).to be_true
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid post" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post permission" do
      user = create(:user)
      login_as(user)
      post = create(:post)
      expect(post).not_to be_editable_by(user)
      delete :destroy, id: post.id
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "succeeds" do
      post = create(:post)
      login_as(post.user)
      delete :destroy, id: post.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:success]).to eq("Post deleted.")
    end
  end

  describe "GET owed" do
    it "requires login" do
      get :owed
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds" do
      login
      get :owed
      expect(response.status).to eq(200)
    end

    # TODO WAY more tests
  end

  describe "GET unread" do
    it "requires login" do
      get :unread
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds" do
      login
      get :unread
      expect(response.status).to eq(200)
    end

    # TODO WAY more tests
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "read" do
      it "skips invisible post" do
        private_post = create(:post, privacy: Post::PRIVACY_PRIVATE)
        user = create(:user)
        expect(private_post.visible_to?(user)).not_to be_true
        login_as(user)
        post :mark, marked_ids: [private_post.id], commit: "Mark Read"
        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("0 posts marked as read.")
        expect(private_post.reload.last_read(user)).to be_nil
      end

      it "reads posts" do
        user = create(:user)
        post1 = create(:post)
        post2 = create(:post)
        login_as(user)

        expect(post1.last_read(user)).to be_nil
        expect(post2.last_read(user)).to be_nil

        post :mark, marked_ids: [post1.id.to_s, post2.id.to_s], commit: "Mark Read"

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("2 posts marked as read.")
        expect(post1.reload.last_read(user)).not_to be_nil
        expect(post2.reload.last_read(user)).not_to be_nil
      end
    end

    context "ignored" do
      it "skips invisible post" do
        private_post = create(:post, privacy: Post::PRIVACY_PRIVATE)
        user = create(:user)
        expect(private_post.visible_to?(user)).not_to be_true
        login_as(user)
        post :mark, marked_ids: [private_post.id]
        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("0 posts hidden from this page.")
        expect(private_post.reload.ignored_by?(user)).not_to be_true
      end

      it "ignores posts" do
        user = create(:user)
        post1 = create(:post)
        post2 = create(:post)
        login_as(user)

        expect(post1.visible_to?(user)).to be_true
        expect(post2.visible_to?(user)).to be_true

        post :mark, marked_ids: [post1.id.to_s, post2.id.to_s]

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("2 posts hidden from this page.")
        expect(post1.reload.ignored_by?(user)).to be_true
        expect(post2.reload.ignored_by?(user)).to be_true
      end
    end
  end

  describe "GET hidden" do
    it "requires login" do
      get :hidden
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds with no hidden" do
      login
      get :hidden
      expect(response.status).to eq(200)
      expect(assigns(:hidden_boardviews)).to be_empty
      expect(assigns(:hidden_posts)).to be_empty
    end

    it "succeeds with board hidden" do
      user = create(:user)
      board = create(:board)
      board.ignore(user)
      login_as(user)
      get :hidden
      expect(response.status).to eq(200)
      expect(assigns(:hidden_boardviews)).not_to be_empty
      expect(assigns(:hidden_posts)).to be_empty
    end

    it "succeeds with post hidden" do
      user = create(:user)
      post = create(:post)
      post.ignore(user)
      login_as(user)
      get :hidden
      expect(response.status).to eq(200)
      expect(assigns(:hidden_boardviews)).to be_empty
      expect(assigns(:hidden_posts)).not_to be_empty
    end

    it "succeeds with both hidden" do
      user = create(:user)
      post = create(:post)
      post.ignore(user)
      post.board.ignore(user)
      login_as(user)
      get :hidden
      expect(response.status).to eq(200)
      expect(assigns(:hidden_boardviews)).not_to be_empty
      expect(assigns(:hidden_posts)).not_to be_empty
    end
  end

  describe "POST unhide" do
    it "requires login" do
      post :unhide
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds for posts" do
      hidden_post = create(:post)
      stay_hidden_post = create(:post)
      user = create(:user)
      hidden_post.ignore(user)
      stay_hidden_post.ignore(user)
      login_as(user)
      post :unhide, unhide_posts: [hidden_post.id]
      expect(response).to redirect_to(hidden_posts_url)
      hidden_post.reload
      stay_hidden_post.reload
      expect(hidden_post).not_to be_ignored_by(user)
      expect(stay_hidden_post).to be_ignored_by(user)
    end

    it "succeeds for board" do
      board = create(:board)
      stay_hidden_board = create(:board)
      user = create(:user)
      board.ignore(user)
      stay_hidden_board.ignore(user)
      login_as(user)
      post :unhide, unhide_boards: [board.id]
      expect(response).to redirect_to(hidden_posts_url)
      board.reload
      stay_hidden_board.reload
      expect(board).not_to be_ignored_by(user)
      expect(stay_hidden_board).to be_ignored_by(user)
    end

    it "succeeds for both" do
      board = create(:board)
      hidden_post = create(:post)
      user = create(:user)
      board.ignore(user)
      hidden_post.ignore(user)
      login_as(user)

      post :unhide, unhide_boards: [board.id], unhide_posts: [hidden_post.id]

      expect(response).to redirect_to(hidden_posts_url)
      board.reload
      hidden_post.reload
      expect(board).not_to be_ignored_by(user)
      expect(hidden_post).not_to be_ignored_by(user)
    end

    it "succeeds for neither" do
      login
      post :unhide
      expect(response).to redirect_to(hidden_posts_url)
    end
  end
end
