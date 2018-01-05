require "spec_helper"

RSpec.feature "Renders the same:", :type => :feature, :js => true do
  let(:desired_time) { Time.zone.local(2018) }

  shared_examples_for "layout" do |layout|
    let(:user) { login }
    before(:each) do
      user.update_attributes(layout: layout)
    end

    scenario "Recently Updated" do
      Timecop.freeze(desired_time) do
        4.times { create(:board).destroy }
        26.times { create(:post) }
        visit posts_path
      end
      expect(page).to match_expectation
    end

    scenario "User#Edit" do
      Timecop.freeze(desired_time) do
        visit edit_user_path(user)
      end
      expect(page).to match_expectation
    end

    scenario "Board" do
      Timecop.freeze(desired_time) do
        board = create(:board)
        3.times { create(:board_section, board: board) }
        3.times { create(:post, board: board) }
        board.board_sections.order(:section_order).each do |section|
          2.times { create(:post, board: board, section: section) }
        end
        visit board_path(board)
      end
      expect(page).to match_expectation
    end

    scenario "Character#Edit" do
      Timecop.freeze(desired_time) do
        character = create(:character, user: user)
        gallery = create(:gallery, user: user)
        icon = create(:icon, user: user, galleries: [gallery])
        2.times { create(:icon, user: user, galleries: [gallery]) }
        character.galleries += [gallery]
        character.update_attributes(default_icon: icon)
        visit edit_character_path(character)
      end
      expect(page).to match_expectation
    end

    scenario "Post" do
      Timecop.freeze(desired_time) do
        other_user = create(:user)
        post = create(:post, user: other_user)
        create(:reply, post: post, user: user)
        30.times do |i|
          if i.even? then
            create(:reply, post: post, user: user)
          else
            create(:reply, post: post, user: other_user)
          end
        end
        visit post_path(post, page: 2)
      end
      expect(page).to match_expectation
    end

    scenario "Post#Edit" do
      Timecop.freeze(desired_time) do
        post = create(:post, user: user)
        visit edit_post_path(post)
      end
      expect(page).to match_expectation
    end
  end

  ['default', 'dark', 'starry', 'starrydark', 'starrylight', 'monochrome', 'river', 'iconless'].each do |type|
    context type do
      it_behaves_like('layout', (type == 'default') ? nil : type)
    end
  end
end
