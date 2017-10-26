require "./app/models/book_cover_sample_data.rb"
class BookCoverModel
  attr_accessor :author_first, :author_last, :author_id, :author_url,
    :title, :pub_date, :image

  @@covers_paginated = nil

  def self.get_all_paginated(author_base_url, page_size)
    # TODO: Use the Rails cache for this
    @@covers_paginated ||= begin
      Rails.logger.info "Calculating paginated covers..."
      covers = get_all(author_base_url)
      pages = []
      page = []
      covers.each do |cover|
        page << cover
        if page.count == page_size
          pages << page
          page = []
        end
      end
      if page.count > 0
        pages << page
      end
      pages
    end
  end

  def self.db_pool()
    pool = ActiveRecord::Base.establish_connection(
      :adapter  => "mysql2",
      :host     => ENV["BOOK_COVER_HOST"],
      :database => ENV["BOOK_COVER_DB"],
      :username => ENV["BOOK_COVER_USER"],
      :password => ENV["BOOK_COVER_PASSWORD"]
    )
  end

  def self.get_all(author_base_url)
    if ENV["BOOK_COVER_STUB"]=="true"
      BookCoversSampleData.get_all()
    else
      self.get_all_from_db(author_base_url)
    end
  end

  def self.get_all_from_db(author_base_url)
    base_path = ENV["BOOK_COVER_BASE_PATH"]
    if base_path == nil
      Rails.logger.error "BOOK_COVER_BASE_PATH has not been defined. Book covers will not be available."
      return []
    end
    covers = []
    if ENV["BOOK_COVER_HOST"] != nil
      Rails.logger.info "Fetching covers from the database..."
      sql = <<-END_SQL.gsub(/\n/, '')
        SELECT jacket_id, firstname, lastname, shortID, title, pub_date,
        image, dept, dept2, dept3, active
        FROM book_jackets
        WHERE active = 'y'
        ORDER BY pub_date DESC
      END_SQL
      pool = db_pool()
      rows = pool.connection.exec_query(sql)
      rows.each do |row|
        cover = BookCoverModel.new()
        cover.author_first = row['firstname']
        cover.author_last = row['lastname']
        cover.author_id = row['shortID']
        cover.author_url = "#{author_base_url}#{row['shortID']}"
        cover.title = row['title']
        cover.pub_date = row['pub_date']
        cover.image = "#{base_path}/#{row['image']}"
        covers << cover
      end
      pool.disconnect!
    end
    covers
  rescue => ex
    Rails.logger.error "#{ex.message}"
    []
  end
end
