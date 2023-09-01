#!/usr/bin/env ruby

require 'json'
require_relative 'lib'

def main
  git_repo = ARGV[0]
  git_ref_name = ARGV[1]
  git_ref_type = ARGV[2]
  git_default_branch = ARGV[3]

  # log to stderr so that stdout only contains the full tags
  $stderr.puts "'#{git_repo}', '#{git_ref_name}', '#{git_ref_type}', '#{git_default_branch}'"

  image_name = get_image_name(git_repo: git_repo)

  tags =
    get_image_tags(
      git_ref_name: git_ref_name,
      git_ref_type: git_ref_type,
      git_default_branch: git_default_branch,
      semver: '0.0.0',
    )
    .to_a
    .map {|tag| "#{image_name}:#{tag}" }
    .join(',')

  # log to stderr so that stdout only contains the full tags
  $stderr.puts tags

  puts tags
end

main()
