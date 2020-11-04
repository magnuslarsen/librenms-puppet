# frozen_string_literal: true

Puppet::Functions.create_function(:to_phpconfig) do
  dispatch :convert do
    required_param 'Hash', :original_hash
    return_type 'Hash'
  end

  def convert(original_hash)
    new_hash = {}

    original_hash.each do |org_key, org_val|
      ## FORMAT KEY ##
      new_key = '$config'

      key_split = org_key.split('.')
      new_key  += format_key(key_split)

      ## FORMAT VALUE ##
      case org_val.to_s.strip
      when %r{^(\d+\.\d+|\d+|true|false)$}
        # These values do not need formatting
        new_hash[new_key] = org_val
      when %r{^(\[\{.*\}\]|\{.*\}\,(\{.*\}\,?)*)$}
        # For array of hashes, create an array key, and add a entry for each hash
        num = 0
        org_val.each do |hash|
          new_hash["#{new_key}[#{num}]"] = format_val_hash(hash)
          num += 1
        end
      when %r{^\[.*\]$}
        new_hash[new_key] = format_val_array(org_val)
      when %r{^\{.*\}$}
        new_hash[new_key] = format_val_hash(org_val)
      else
        # Strings need qoutes around it
        new_hash[new_key] = "'#{org_val}'"
      end
    end

    new_hash
  end

  # @param values - an array of values to format
  # @return [string]
  def format_key(values)
    formatted_vals = []

    values.each do |item|
      begin # rubocop:disable Style/RedundantBegin
        formatted_vals.push(Integer(item))
      rescue StandardError
        formatted_vals.push("'#{item}'")
      end
    end

    formatted_vals.map! { |item| "[#{item}]" }

    formatted_vals.join
  end

  # @param values - an array of values to format
  # @return [string]
  def format_val_array(values)
    # This is definitly not pretty; but it works fine enough
    joined_vals = values.join("', '")
    "array('#{joined_vals}')"
  end

  # @param hash - a hash of values to format
  # @return [string]
  def format_val_hash(hash)
    # Again, not pretty; works
    formatted_vals = []
    hash.each { |key, value| formatted_vals.push("'#{key}' => '#{value}'") }

    joined_vals = formatted_vals.join(', ')
    "array(#{joined_vals})"
  end
end
