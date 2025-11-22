namespace :personas do
  desc "Generate cartoonesque avatars for personas using DALL-E"
  task generate_avatars: :environment do
    require 'httparty'
    require 'fileutils'

    puts "🎨 Generating persona avatars with DALL-E..."

    # Create directory for avatars
    avatars_dir = Rails.root.join('app', 'assets', 'images', 'personas')
    FileUtils.mkdir_p(avatars_dir)

    # Avatar prompts for each persona
    avatar_prompts = {
      "revolutionary" => "A funny cartoon character with a raised fist, wearing a red beret and Che Guevara style outfit, angry expression, holding a protest sign, vibrant red color scheme, simple flat design, white background",
      
      "moderate" => "A funny cartoon character wearing glasses and a cardigan, holding an NPR tote bag and a coffee mug, calm neutral expression, beige and gray color scheme, simple flat design, white background",
      
      "patriot" => "A funny cartoon character wearing an American flag shirt and baseball cap, saluting with pride, confident patriotic expression, red white and blue color scheme, simple flat design, white background",
      
      "skeptic" => "A funny cartoon character wearing a tinfoil hat, suspicious squinting eyes, holding a magnifying glass, purple and dark color scheme, mysterious vibe, simple flat design, white background",
      
      "disruptor" => "A funny cartoon character wearing a hoodie and sneakers, holding a laptop with startup stickers, excited energetic expression, cyan and tech blue color scheme, simple flat design, white background",
      
      "burnt-out" => "A funny cartoon character looking exhausted with bags under eyes, holding a phone and coffee, defeated slouched posture, teal and muted color scheme, simple flat design, white background"
    }

    Persona.find_each do |persona|
      next unless avatar_prompts[persona.slug]

      puts "\n🎭 Generating avatar for #{persona.name}..."

      begin
        # Call DALL-E API
        response = HTTParty.post(
          'https://api.openai.com/v1/images/generations',
          headers: {
            'Authorization' => "Bearer #{ENV['OPENAI_API_KEY']}",
            'Content-Type' => 'application/json'
          },
          body: {
            model: 'dall-e-3',
            prompt: avatar_prompts[persona.slug],
            n: 1,
            size: '1024x1024',
            quality: 'standard',
            style: 'vivid'
          }.to_json
        )

        if response.success?
          image_url = response.parsed_response['data'][0]['url']
          puts "  ✓ Generated image URL: #{image_url[0..60]}..."

          # Download the image
          image_response = HTTParty.get(image_url)
          
          if image_response.success?
            # Save to assets
            filename = "#{persona.slug}.png"
            filepath = avatars_dir.join(filename)
            File.binwrite(filepath, image_response.body)
            puts "  ✓ Saved to: #{filepath}"

            # Update persona with local asset path
            persona.update!(avatar_url: "personas/#{filename}")
            puts "  ✓ Updated #{persona.name} avatar_url"
          else
            puts "  ✗ Failed to download image: #{image_response.code}"
          end
        else
          puts "  ✗ DALL-E API error: #{response.code} - #{response.parsed_response}"
        end

      rescue => e
        puts "  ✗ Error generating avatar: #{e.message}"
      end

      # Rate limiting - wait 2 seconds between requests
      sleep 2
    end

    puts "\n✅ Avatar generation complete!"
    puts "   Generated avatars in: #{avatars_dir}"
  end
end

