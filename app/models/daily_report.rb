class DailyReport < Report
  attr_reader :day

  def initialize(day)
    @day = day
  end

  def posts(sort='', page=1, per_page=25)
    created_no_replies = Post.where(last_reply_id: nil, created_at: day.beginning_of_day .. day.end_of_day).pluck(:id)
    by_replies = Reply.where(created_at: day.beginning_of_day .. day.end_of_day).pluck(:post_id)
    all_post_ids = created_no_replies + by_replies
    Post.where(id: all_post_ids.uniq)
      .select("posts.*,
        max(boards.name) as board_name,
        case
        when (posts.created_at between #{ActiveRecord::Base.connection.quote(day.beginning_of_day)} AND #{ActiveRecord::Base.connection.quote(day.end_of_day)})
          then posts.created_at
          else coalesce(min(replies_today.created_at), posts.created_at)
          end as first_updated_at")
      .joins(:board)
      .includes(:authors)
      .joins("LEFT JOIN replies AS replies_today ON replies_today.post_id = posts.id")
      .where("replies_today.created_at IS NULL OR (replies_today.created_at between ? AND ?)", day.beginning_of_day, day.end_of_day)
      .group("posts.id")
      .order(sort)
      .with_reply_count
      .with_has_content_warnings
      .paginate(page: page, per_page: per_page)
  end

  def self.unread_date_for(user)
    # ignores reports in progress
    return nil unless user
    return nil if user.ignore_unread_daily_report?
    last_read = last_read(user)
    return 1.day.ago.to_date.to_s unless last_read
    return nil unless last_read.to_date < 1.day.ago.to_date
    (last_read + 1.day).to_date.to_s
  end
end
