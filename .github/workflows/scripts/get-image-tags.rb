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

  tags =
    get_image_tags(
      git_repo: git_repo,
      git_ref_name: git_ref_name,
      git_ref_type: git_ref_type,
      git_default_branch: git_default_branch,
      package: JSON.parse(File.read('package.json')),
    ).to_a.join(',')

  # log to stderr so that stdout only contains the full tags
  $stderr.puts tags

  puts tags
end

main()
