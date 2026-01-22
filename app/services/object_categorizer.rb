# frozen_string_literal: true

# Service to categorize detected objects using taxonomy configuration
class ObjectCategorizer
  TAXONOMY_FILE = Rails.root.join("config", "taxonomy.yml")

  class << self
    # Categorize a single object label
    # Returns category name or "other" if not found
    def categorize(label)
      taxonomy[label.to_s.strip] || "other"
    end

    # Load taxonomy from YAML file
    def taxonomy
      @taxonomy ||= load_taxonomy
    end

    # Reload taxonomy (useful for development/testing)
    def reload_taxonomy!
      @taxonomy = load_taxonomy
    end

    private

    def load_taxonomy
      return {} unless File.exist?(TAXONOMY_FILE)

      yaml_data = YAML.load_file(TAXONOMY_FILE)
      build_reverse_mapping(yaml_data)
    end

    # Build reverse mapping: label => category
    # Example: "Chair" => "furniture"
    def build_reverse_mapping(yaml_data)
      mapping = {}
      yaml_data.each do |category, labels|
        labels.each do |label|
          # Case-insensitive matching, store normalized
          mapping[label.to_s.downcase.strip] = category.to_s
        end
      end
      mapping
    end
  end
end
