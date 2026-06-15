#!/usr/bin/env ruby
# Validate a SKILL.md's LEADING frontmatter with a real YAML parse (codex review: a line/grep
# "parser" accepted unloadable YAML and description: ""). Exit 0 iff: the file opens with a closed
# `--- … ---` block that parses as a YAML mapping whose `name` == expected and whose `description`
# is a non-empty string.
require 'yaml'

path, expected = ARGV[0], ARGV[1]
unless path && expected && File.exist?(path)
  warn "missing or bad args: #{path.inspect}"; exit 1
end

lines = File.readlines(path, chomp: true)
if lines.empty? || lines[0].strip != "---"
  warn "no leading frontmatter: #{path}"; exit 1
end
close = (1...lines.length).find { |i| lines[i].strip == "---" }
if close.nil?
  warn "unclosed frontmatter: #{path}"; exit 1
end

begin
  meta = YAML.safe_load(lines[1...close].join("\n"))
rescue => e
  warn "invalid frontmatter YAML: #{path} (#{e.class})"; exit 1
end
unless meta.is_a?(Hash)
  warn "frontmatter is not a mapping: #{path}"; exit 1
end
if meta["name"] != expected
  warn "name #{meta['name'].inspect} != #{expected.inspect}: #{path}"; exit 1
end
desc = meta["description"]
unless desc.is_a?(String) && !desc.strip.empty?
  warn "missing/empty description: #{path}"; exit 1
end
exit 0
