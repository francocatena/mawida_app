require 'test_helper'

class TagTest < ActiveSupport::TestCase
  setup do
    @tag = tags :important
  end

  test 'blank attributes' do
    @tag.name = ''
    @tag.kind = ''
    @tag.style = ''
    @tag.icon = ''

    assert @tag.invalid?
    assert_error @tag, :name, :blank
    assert_error @tag, :kind, :blank
    assert_error @tag, :style, :blank
    assert_error @tag, :icon, :blank
  end

  test 'unique attributes' do
    tag = @tag.dup

    assert tag.invalid?
    assert_error tag, :name, :taken
  end

  test 'attributes length' do
    @tag.name = 'abcde' * 52
    @tag.kind = 'abcde' * 52
    @tag.style = 'abcde' * 52
    @tag.icon = 'abcde' * 52

    assert @tag.invalid?
    assert_error @tag, :name, :too_long, count: 255
    assert_error @tag, :kind, :too_long, count: 255
    assert_error @tag, :style, :too_long, count: 255
    assert_error @tag, :icon, :too_long, count: 255
  end

  test 'attributes inclusion' do
    @tag.kind = 'wrong'
    @tag.style = 'wrong'
    @tag.icon = 'wrong'

    assert @tag.invalid?
    assert_error @tag, :kind, :inclusion
    assert_error @tag, :style, :inclusion
    assert_error @tag, :icon, :inclusion
  end

  test 'shared reversion' do
    @tag.update! shared: true

    @tag.shared = false

    assert @tag.invalid?
    assert_error @tag, :shared, :invalid
  end

  test 'search' do
    tags = Tag.search query: @tag.name

    assert tags.any?
    assert tags.all? { |s| s.name =~ /#{@tag.name}/ }
  end
end
