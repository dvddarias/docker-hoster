#!/usr/bin/env ruby

require 'json'
require_relative 'lib'

def main
  repo_owner = ARGV[0]
  repo_name = ARGV[1]
  git_ref_name = ARGV[2]
  git_ref_type = ARGV[3]
  git_default_branch = ARGV[4]

  # log to stderr so that stdout only contains the full tags
  $stderr.puts "'#{repo_owner}', '#{repo_name}', '#{git_ref_name}', '#{git_ref_type}', '#{git_default_branch}'"

  image_name = get_image_name(username: repo_owner, project_name: repo_name)

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
