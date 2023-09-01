require 'set'

# @param git_ref_name [String]
# @param git_ref_type [String]
# @param git_default_branch [String]
# @return [Set[String]]
def get_image_tags(
  git_ref_name: nil,
  git_ref_type: nil,
  git_default_branch: nil,
  semver: nil
)
  versions = Set[]

  if git_ref_type == 'branch'
    # add safe branch name
    versions.add(git_ref_name.downcase.gsub(/[^a-z0-9._\n]+/, '-'))
  elsif git_ref_type == 'tag'
    # add version tag
    versions.add(semver)
    # TODO: check that this is actually latest
    parsed = parse_semver(semver)
    if parsed.pre == nil
      versions.add(parsed.major.to_s)
      versions.add("#{parsed.major}.#{parsed.minor}")
      versions.add("#{parsed.major}.#{parsed.minor}.#{parsed.patch}")
    end

    # TODO: if the tag was made on a non-default branch, we still tag with default branch
    versions.add(git_default_branch)
  end

  # TODO: if `tag`, check that this is actually latest
  if git_ref_name == git_default_branch or git_ref_type == 'tag'
    # Use Docker `latest` tag convention, only tagging `latest` on default branch.
    versions.add('latest')
  end

  return versions
end

# @param registry [String]
# @param git_repo [String]
# @param sub_image [String?]
# @return String
def get_image_name(registry: 'ghcr.io', git_repo: nil, sub_image: nil)
  git_repo = git_repo.downcase

  default_sub_image = File.basename git_repo
  container_repo = "#{registry}/#{git_repo}/#{sub_image ? sub_image : default_sub_image}"
end

Semver = Struct.new('Semver', :major, :minor, :patch, :pre, :build)

# @param version [String]
# @return [Semver]
def parse_semver(version)
  # Ruby extracts regex named groups to local vars (but only if the regex is inlined).
  /^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?:-(?<pre>[0-9A-Za-z\-.]+))?(?:\+(?<build>[0-9A-Za-z\-]+))?$/ =~
    version

  Semver.new(major.to_i, minor.to_i, patch.to_i, pre, build)
end
