require "spec_helper"

RSpec.feature "Renders the same:", :type => :feature, :js => true do
  before(:each) do
    4.times { create(:board).destroy }
    desired_time = Time.zone.local(2018)
    Timecop.freeze(desired_time) do
      26.times { create(:post) }
    end
  end

  scenario "Recently Updated" do
    scenario "in default" do
      user = login
      user.update_attributes(layout: nil)
      Timecop.freeze(Time.zone.local(2018)) do
        visit posts_path
      end
      expect(page).to match_expectation
    end

    scenario "in dark" do
      user = login
      user.update_attributes(layout: 'dark')
      Timecop.freeze(Time.zone.local(2018)) do
        visit posts_path
      end
      expect(page).to match_expectation
    end

    scenario "in starry" do
      user = login
      user.update_attributes(layout: 'starry')
      Timecop.freeze(Time.zone.local(2018)) do
        visit posts_path
      end
      expect(page).to match_expectation
    end

    scenario "in starrydark" do
      user = login
      user.update_attributes(layout: 'starrydark')
      Timecop.freeze(Time.zone.local(2018)) do
        visit posts_path
      end
      expect(page).to match_expectation
    end

    scenario "in starrylight" do
      user = login
      user.update_attributes(layout: 'starrylight')
      Timecop.freeze(Time.zone.local(2018)) do
        visit posts_path
      end
      expect(page).to match_expectation
    end

    scenario "in monochrome" do
      user = login
      user.update_attributes(layout: 'monochrome')
      Timecop.freeze(Time.zone.local(2018)) do
        visit posts_path
      end
      expect(page).to match_expectation
    end

    scenario "in river" do
      user = login
      user.update_attributes(layout: 'river')
      Timecop.freeze(Time.zone.local(2018)) do
        visit posts_path
      end
      expect(page).to match_expectation
    end

    scenario "in iconless" do
      user = login
      user.update_attributes(layout: 'iconless')
      Timecop.freeze(Time.zone.local(2018)) do
        visit posts_path
      end
      expect(page).to match_expectation
    end
  end

  scenario "User#edit"
    scenario "in default" do
      user = login
      user.update_attributes(layout: nil)
      Timecop.freeze(Time.zone.local(2018)) do
        visit edit_user_path(user.id)
      end
      expect(page).to match_expectation
    end

    scenario "in dark" do
      user = login
      user.update_attributes(layout: 'dark')
      Timecop.freeze(Time.zone.local(2018)) do
        visit edit_user_path(user.id)
      end
      expect(page).to match_expectation
    end

    scenario "in starry" do
      user = login
      user.update_attributes(layout: 'starry')
      Timecop.freeze(Time.zone.local(2018)) do
        visit edit_user_path(user.id)
      end
      expect(page).to match_expectation
    end

    scenario "in starrydark" do
      user = login
      user.update_attributes(layout: 'starrydark')
      Timecop.freeze(Time.zone.local(2018)) do
        visit edit_user_path(user.id)
      end
      expect(page).to match_expectation
    end

    scenario "in starrylight" do
      user = login
      user.update_attributes(layout: 'starrylight')
      Timecop.freeze(Time.zone.local(2018)) do
        visit edit_user_path(user.id)
      end
      expect(page).to match_expectation
    end

    scenario "in monochrome" do
      user = login
      user.update_attributes(layout: 'monochrome')
      Timecop.freeze(Time.zone.local(2018)) do
        visit edit_user_path(user.id)
      end
      expect(page).to match_expectation
    end

    scenario "in river" do
      user = login
      user.update_attributes(layout: 'river')
      Timecop.freeze(Time.zone.local(2018)) do
        visit edit_user_path(user.id)
      end
      expect(page).to match_expectation
    end

    scenario "in iconless" do
      user = login
      user.update_attributes(layout: 'iconless')
      Timecop.freeze(Time.zone.local(2018)) do
        visit edit_user_path(user.id)
      end
      expect(page).to match_expectation
    end
  end
end
