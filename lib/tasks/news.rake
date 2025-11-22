namespace :news do
  desc "Fetch latest news from NewsAPI (smart sync - only new stories)"
  task fetch_latest: :environment do
    puts "🔄 Fetching latest news..."
    puts "📅 Last story published at: #{NewsStory.maximum(:published_at) || 'Never'}"
    puts ""

    results = FetchNewsJob.new.perform(mode: :latest)

    puts ""
    puts "✅ Fetch complete!"
    puts "   📊 #{results[:new].count} new stories"
    puts "   📊 #{results[:updated].count} updated stories"
    puts "   📊 #{results[:skipped].count} skipped (duplicates)"
    puts ""
    puts "📰 Total stories in database: #{NewsStory.count}"
  end

  desc "Fetch news from a specific category"
  task :fetch_category, [:category] => :environment do |_t, args|
    category = args[:category] || "general"
    puts "🔄 Fetching news from category: #{category}"
    
    results = FetchNewsJob.new.perform(mode: :single_category, categories: [category])
    
    puts ""
    puts "✅ Fetch complete!"
    puts "   📊 #{results[:new].count} new stories"
    puts "   📊 #{results[:updated].count} updated stories"
    puts "   📊 #{results[:skipped].count} skipped (duplicates)"
  end

  desc "Show news statistics"
  task stats: :environment do
    puts "📊 News Statistics"
    puts "=" * 50
    puts "Total stories: #{NewsStory.count}"
    puts "Active stories: #{NewsStory.active.count}"
    puts "Featured stories: #{NewsStory.featured.count}"
    puts ""
    puts "By category:"
    NewsStory.group(:category).count.each do |category, count|
      puts "  #{category}: #{count}"
    end
    puts ""
    puts "Latest story: #{NewsStory.maximum(:published_at)}"
    puts "Oldest story: #{NewsStory.minimum(:published_at)}"
    puts ""
    puts "Stories with interpretations: #{NewsStory.joins(:interpretations).distinct.count}"
    puts "Total interpretations: #{Interpretation.count}"
  end

  desc "Clean up old stories (older than 30 days)"
  task cleanup_old: :environment do
    cutoff_date = 30.days.ago
    old_stories = NewsStory.where("published_at < ?", cutoff_date)
    count = old_stories.count

    puts "🗑️  Found #{count} stories older than #{cutoff_date.to_date}"
    
    if count > 0
      print "Archive these stories? (y/N): "
      response = STDIN.gets.chomp.downcase
      
      if response == 'y'
        old_stories.update_all(active: false)
        puts "✅ Archived #{count} old stories"
      else
        puts "❌ Cancelled"
      end
    end
  end

  desc "Test NewsAPI connection"
  task test_api: :environment do
    puts "🔍 Testing NewsAPI connection..."
    puts ""
    
    api_key = ENV["NEWS_API_KEY"]
    
    if api_key.blank?
      puts "❌ NEWS_API_KEY is not set!"
      puts "Set it with: export NEWS_API_KEY=your_key_here"
      exit 1
    end
    
    puts "✅ API key found: #{api_key[0..10]}..."
    puts ""
    puts "Fetching test headlines..."
    
    service = NewsFetcherService.new
    articles = service.fetch_top_headlines(category: "general", limit: 5)
    
    if articles.any?
      puts "✅ Successfully fetched #{articles.count} articles:"
      articles.first(3).each do |article|
        puts "  • #{article[:headline]}"
      end
    else
      puts "❌ No articles fetched. Check your API key."
    end
  end
end

