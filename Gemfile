source "https://rubygems.org"

gem "jekyll", "~> 4.4"

group :jekyll_plugins do
  gem "jekyll-feed",     "~> 0.17"
  gem "jekyll-archives", "~> 2.3"
  gem "jekyll-seo-tag",  "~> 2.9"
end

# Rouge does build-time syntax highlighting. Jekyll 4.4 requires rouge < 5.0,
# so 4.x is the ceiling here regardless of what's newest on rubygems. Pinned so
# a major bump can't silently rename the classes assets/css/main.scss targets.
gem "rouge", "~> 4.0"

# Required on Ruby 3.4+, where these left the standard library.
gem "csv"
gem "base64"
gem "bigdecimal"
