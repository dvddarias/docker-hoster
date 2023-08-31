require 'test/unit'
require 'json'
require 'set'

require_relative '../lib'

class TestGetImageTags < Test::Unit::TestCase
  def test_simple_branch
    assert_equal(
      Set['ghcr.io/virginity-bot/virginity-bot/bot:feat-foo-bar'],
      get_image_tags(
        git_repo: 'Virginity-Bot/virginity-bot',
        git_ref_name: 'feat/foo-bar',
        git_ref_type: 'branch',
        git_default_branch: 'master',
        package: JSON.parse('{"version": "1.0.0"}'),
      ),
    )

    assert_equal(
      Set[
        'ghcr.io/virginity-bot/virginity.bot/bot:latest',
        'ghcr.io/virginity-bot/virginity.bot/bot:master'
      ],
      get_image_tags(
        git_repo: 'Virginity-Bot/virginity.bot',
        git_ref_name: 'master',
        git_ref_type: 'branch',
        git_default_branch: 'master',
        package: JSON.parse('{"version": "1.0.0"}'),
      ),
    )
  end

  def test_simple_tag
    assert_equal(
      Set[
        'ghcr.io/virginity-bot/virginity.bot/bot:latest',
        'ghcr.io/virginity-bot/virginity.bot/bot:master',
        'ghcr.io/virginity-bot/virginity.bot/bot:1.0.0',
        'ghcr.io/virginity-bot/virginity.bot/bot:1.0',
        'ghcr.io/virginity-bot/virginity.bot/bot:1'
      ],
      get_image_tags(
        git_repo: 'Virginity-Bot/virginity.bot',
        git_ref_name: '1.0.0',
        git_ref_type: 'tag',
        git_default_branch: 'master',
        package: JSON.parse('{"version": "1.0.0"}'),
      ),
    )
  end

  def test_pre_tag
    assert_equal(
      Set[
        'ghcr.io/virginity-bot/virginity.bot/bot:latest',
        'ghcr.io/virginity-bot/virginity.bot/bot:master',
        'ghcr.io/virginity-bot/virginity.bot/bot:1.0.0-pre'
      ],
      get_image_tags(
        git_repo: 'Virginity-Bot/virginity.bot',
        git_ref_name: '1.0.0',
        git_ref_type: 'tag',
        git_default_branch: 'master',
        package: JSON.parse('{"version": "1.0.0-pre"}'),
      ),
    )
  end

  def test_unsafe_branch_name
    assert_equal(
      Set['ghcr.io/virginity-bot/virginity.bot/bot:feat-foo-bar'],
      get_image_tags(
        git_repo: 'Virginity-Bot/virginity.bot',
        git_ref_name: 'feat/Foo---bar',
        git_ref_type: 'branch',
        git_default_branch: 'master',
        package: JSON.parse('{"version": "1.0.0"}'),
      ),
    )
  end
end

class TestParseSemver < Test::Unit::TestCase
  def test_parse_basic
    parsed = parse_semver('1.2.3')
    assert_equal(1, parsed.major)
    assert_equal(2, parsed.minor)
    assert_equal(3, parsed.patch)
    assert_equal(nil, parsed.pre)
    assert_equal(nil, parsed.build)
  end

  def test_parse_pre
    parsed = parse_semver('1.2.3-p.re')
    assert_equal(1, parsed.major)
    assert_equal(2, parsed.minor)
    assert_equal(3, parsed.patch)
    assert_equal('p.re', parsed.pre)
    assert_equal(nil, parsed.build)
  end

  def test_parse_full_semver
    parsed = parse_semver('1.2.3-p.re+build')
    assert_equal(1, parsed.major)
    assert_equal(2, parsed.minor)
    assert_equal(3, parsed.patch)
    assert_equal('p.re', parsed.pre)
    assert_equal('build', parsed.build)
  end
end
