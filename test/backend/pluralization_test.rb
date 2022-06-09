require 'test_helper'

class I18nBackendPluralizationTest < I18n::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::Pluralization
    include I18n::Backend::Fallbacks
  end

  def setup
    super
    I18n.backend = Backend.new
    @rule = lambda { |n| n % 10 == 1 && n % 100 != 11 ? :one : n == 0 || (2..10).include?(n % 100) ? :few : (11..19).include?(n % 100) ? :many : :other }
    store_translations(:xx, :i18n => { :plural => { :rule => @rule } })
    @entry = { :"0" => 'none', :"1" => 'single', :one => 'one', :few => 'few', :many => 'many', :other => 'other' }
  end

  test "pluralization picks a pluralizer from :'i18n.pluralize'" do
    assert_equal @rule, I18n.backend.send(:pluralizer, :xx)
  end

  test "pluralization picks the explicit 1 rule for count == 1, the explicit rule takes priority over the matching :one rule" do
    assert_equal 'single', I18n.t(:count => 1, :default => @entry, :locale => :xx)
    assert_equal 'single', I18n.t(:count => 1.0, :default => @entry, :locale => :xx)
  end

  test "pluralization picks :one for 1, since in this case that is the matching rule for 1 (when there is no explicit 1 rule)" do
    @entry.delete(:"1")
    assert_equal 'one', I18n.t(:count => 1, :default => @entry, :locale => :xx)
  end

  test "pluralization picks :few for 2" do
    assert_equal 'few', I18n.t(:count => 2, :default => @entry, :locale => :xx)
  end

  test "pluralization picks :many for 11" do
    assert_equal 'many', I18n.t(:count => 11, :default => @entry, :locale => :xx)
  end

  test "pluralization picks explicit 0 rule for count == 0, since the explicit rule takes priority over the matching :few rule" do
    assert_equal 'none', I18n.t(:count => 0, :default => @entry, :locale => :xx)
    assert_equal 'none', I18n.t(:count => 0.0, :default => @entry, :locale => :xx)
    assert_equal 'none', I18n.t(:count => -0, :default => @entry, :locale => :xx)
  end

  test "pluralization picks :few for 0 (when there is no explicit 0 rule)" do
    @entry.delete(:"0")
    assert_equal 'few', I18n.t(:count => 0, :default => @entry, :locale => :xx)
  end

  test "pluralization does Lateral Inheritance to :other to cover missing data" do
    @entry.delete(:many)
    assert_equal 'other', I18n.t(:count => 11, :default => @entry, :locale => :xx)
  end

  test "pluralization picks one for 1 if the entry has attributes hash on unknown locale" do
    @entry[:attributes] = { :field => 'field', :second => 'second' }
    assert_equal 'one', I18n.t(:count => 1, :default => @entry, :locale => :pirate)
  end

  test "Fallbacks can pick up rules from fallback locales, too" do
    assert_equal @rule, I18n.backend.send(:pluralizer, :'xx-XX')
  end
end
