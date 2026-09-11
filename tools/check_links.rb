#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Verify that every internal link and asset reference in the built site
# resolves to a real file. Catches the usual Jekyll own-goals: a renamed post,
# a tag page that never got generated, a screenshot referenced with the wrong
# path. Regex-based on purpose so it needs no gems.
#
# Usage: ruby tools/check_links.rb _site

require 'set'

root = ARGV[0] || '_site'
abort "not a directory: #{root}" unless Dir.exist?(root)

SKIP = %r{\A(?:https?:|mailto:|tel:|data:|javascript:|//|#)}i
ATTR = /(?:href|src)\s*=\s*(?:"([^"]*)"|'([^']*)')/i

problems = []
checked  = Set.new
pages    = Dir.glob(File.join(root, '**', '*.html'))

pages.each do |page|
  page_dir = File.dirname(page)
  File.read(page).scan(ATTR) do |dq, sq|
    raw = (dq || sq).to_s.strip
    next if raw.empty? || raw.match?(SKIP)

    path = raw.split('#').first.to_s.split('?').first.to_s
    next if path.empty?

    target =
      if path.start_with?('/')
        File.join(root, path)
      else
        File.join(page_dir, path)
      end

    # A directory URL is served by its index.html.
    candidates = [target]
    candidates << File.join(target, 'index.html') if path.end_with?('/')
    candidates << target.sub(%r{/\z}, '')

    next if candidates.any? { |c| File.file?(c) || File.directory?(c) }

    key = [page, raw]
    next if checked.include?(key)
    checked << key
    problems << "#{page.sub(%r{\A#{Regexp.escape(root)}/?}, '')} -> #{raw}"
  end
end

puts "checked #{pages.size} page(s)"

if problems.empty?
  puts 'no broken internal links or missing assets'
else
  warn "\n#{problems.size} broken reference(s):"
  problems.sort.each { |p| warn "  #{p}" }
  exit 1
end
