# Methods for converting the Hashie output of ProductionSampler into SQL INSERT statements

module ProductionSampler
  module HashieToSqlConversion

    private

    # This method could possibly be extracted to another common module since it could be useful in other hashie
    # conversion routines
    def attributes_from_model_data(hashie)
      hashie.reject { |_k,v| v.is_a? Array }  # associations would be of type Array
    end

    # Builds the output INSERT SQL statements to build the data fixtures
    def build_sql_insert_statement(table_name, attributes={})
      return if attributes.empty?
      "INSERT INTO #{table_name} (#{attributes.keys.join(',')}) VALUES (#{sql_safe(attributes.values).join(',')});\n"
    end

    # IMPORTANT: For this method to work, we are making the assumption that expand_spec_properties as already been
    #            enacted on model_spec, per call from build_hashie
    def extract_sql_from_hashie(hashie, model_spec)
      # Build the SQL for the current level
      sql_output = ''
      base_model = model_spec[:base_model]
      columns = model_spec[:columns]
      associations = model_spec[:associations]

      hashie.each do |model_data|
        sql_output << build_sql_insert_statement(base_model.table_name, attributes_from_model_data(model_data))

        next unless associations.present?
        associations.each do |association|
          sub_hashie = model_data.send(association[:association_name])
          sql_output << extract_sql_from_hashie(sub_hashie, association)
        end
      end
      sql_output
    end

    # Takes an array of values, converts each one to a SQL-friendly text string
    def sql_safe(values)
      values.map do |val|
        case val
          when String, ActiveSupport::TimeWithZone, Date
            "'#{val}'"
          when Fixnum, BigDecimal, Float
            "#{val}"
          when FalseClass
            "false"
          when TrueClass
            "true"
          when NilClass
            "null"
          else
            raise ProductionSamplerError, "Unknown SQL Type: #{val.class}"
        end
      end
    end
  end
end
