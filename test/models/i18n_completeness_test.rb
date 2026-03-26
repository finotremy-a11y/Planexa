require "test_helper"
require "yaml"

# Verifies that all 3 locale files (fr/en/es) define exactly the same set of
# translation keys so that a missing translation cannot sneak into production.
class I18nCompletenessTest < ActiveSupport::TestCase
  LOCALES_DIR = Rails.root.join("config", "locales")

  # Recursively collect every leaf key path (e.g. "nav.search")
  def collect_keys(hash, prefix = "")
    hash.each_with_object([]) do |(k, v), keys|
      full = prefix.empty? ? k.to_s : "#{prefix}.#{k}"
      if v.is_a?(Hash)
        keys.concat(collect_keys(v, full))
      else
        keys << full
      end
    end
  end

  def load_locale(file)
    raw = YAML.load_file(LOCALES_DIR.join(file))
    # Strip top-level locale key (fr/en/es)
    raw.values.first || {}
  end

  test "en.yml has all keys present in fr.yml" do
    fr_keys = collect_keys(load_locale("fr.yml")).sort
    en_keys = collect_keys(load_locale("en.yml")).sort
    missing  = fr_keys - en_keys
    assert missing.empty?,
      "en.yml is missing #{missing.size} key(s) present in fr.yml:\n  #{missing.join("\n  ")}"
  end

  test "es.yml has all keys present in fr.yml" do
    fr_keys = collect_keys(load_locale("fr.yml")).sort
    es_keys = collect_keys(load_locale("es.yml")).sort
    missing  = fr_keys - es_keys
    assert missing.empty?,
      "es.yml is missing #{missing.size} key(s) present in fr.yml:\n  #{missing.join("\n  ")}"
  end

  test "fr.yml has all keys present in en.yml" do
    en_keys = collect_keys(load_locale("en.yml")).sort
    fr_keys = collect_keys(load_locale("fr.yml")).sort
    missing  = en_keys - fr_keys
    assert missing.empty?,
      "fr.yml is missing #{missing.size} key(s) present in en.yml:\n  #{missing.join("\n  ")}"
  end

  test "fr.yml has all keys present in es.yml" do
    es_keys = collect_keys(load_locale("es.yml")).sort
    fr_keys = collect_keys(load_locale("fr.yml")).sort
    missing  = es_keys - fr_keys
    assert missing.empty?,
      "fr.yml is missing #{missing.size} key(s) present in es.yml:\n  #{missing.join("\n  ")}"
  end
end
