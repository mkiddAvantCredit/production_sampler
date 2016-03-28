require 'production_sampler/hashie_to_sql_conversion'
require 'production_sampler/production_sampler_error'
require 'hashie'
require 'money-rails'

module ProductionSampler
  class ProductionSampler
    include HashieToSqlConversion

    attr_accessor :app_models

    def initialize(load_models: nil)
      if load_models.nil?
        # load everything
        Rails.application.eager_load!
      else
        # load only the specified models
        load_models.each { |m| load_model(m) }
      end
      @app_models = ActiveRecord::Base.descendants.compact.map { |d| d.name }.sort
    end

    def build_hashie(model_spec)
      if model_spec.class != Hashie::Mash
        raise ProductionSamplerError.new('Value passed to build_hashie must be a Hashie::Mash')
      end

      @preloaded_models = Hashie::Mash.new
      expand_spec_properties(model_spec)
      return extract_model(model_spec)
    end

    def build_sql(model_spec)
      hashie = build_hashie(model_spec)
      extract_sql_from_hashie(hashie, model_spec)
    end

    private

    def apply_filters_to_model(model_spec)
      klass_with_filters = model_spec[:base_model]
      klass_with_filters = klass_with_filters.send(model_spec[:scope]) if model_spec[:scope]
      if model_spec[:where]
        klass_with_filters = klass_with_filters.where(model_spec[:where][:expression], *model_spec[:where][:parameters])
      end
      klass_with_filters
    end

    # Caches data we are going to need for querying a particular model in the spec hash
    def expand_spec_properties(model_spec)
      model_spec[:columns].unshift(:id) unless model_spec[:exclude_columns].present? || model_spec[:columns].include?(:id)
      base_model = model_spec[:base_model]
      if model_spec[:associations].present?
        model_spec[:associations].each do |associated_model_spec|
          reflection = base_model.reflect_on_association(associated_model_spec[:association_name].to_sym)
          associated_model_spec[:base_model]       = reflection.klass
          associated_model_spec[:association_type] = reflection.macro
          if associated_model_spec[:association_type] == :has_many

            associated_model_spec[:foreign_key] ||=
              reflection.options[:foreign_key] ||
              model_spec[:base_model].to_s.underscore << "_id"

            associated_model_spec[:primary_key] = reflection.options[:primary_key] || :id
          end

          expand_spec_properties(associated_model_spec)
        end
      end
    end

    def extract_model(model_spec)
      result = []

      # Skip processing if no ids are specified; production_sampler is meant to pull a sample, not a whole table
      return result if model_spec[:ids].nil?

      # Preload any records not currently cached
      # TODO Consider replacing preload_includes? with find_preloaded_ids result validation so it only iterates once.
      unless preload_includes?(model_spec[:base_model], model_spec[:ids])
        preload_model(model_spec, 'id', model_spec[:ids])
      end

      # Use the list of ID numbers to grab the preloaded ActiveRecord models for processing into a returned Hashie
      model_objects = find_preloaded_records_by_ids(model_spec[:base_model], model_spec[:ids])
      model_objects.each do |obj|
        model_data = filtered_attributes(obj, model_spec)
        result << model_data
      end

      if model_spec[:associations].present?
        model_spec[:associations].each do |associated_model_spec|
          preload_association(
            base_model: model_spec[:base_model],
            base_model_objects: model_objects,
            association_spec: associated_model_spec,
            base_primary_key: associated_model_spec[:primary_key]
          )
          association_name = associated_model_spec[:association_name]
          associated_model = associated_model_spec[:base_model]
          association_type = associated_model_spec[:association_type]

          result.each do |base_model_attributes|
            if association_type == :has_many
              foreign_key = associated_model_spec[:foreign_key]
              primary_key = associated_model_spec[:primary_key]
              associated_model_spec[:ids] = find_preloaded_records_by_key(associated_model, foreign_key, [base_model_attributes.send(primary_key)])
                .map { |pr| pr.id }

              if associated_model_spec[:ids].present?
                base_model_attributes[association_name] = extract_model(associated_model_spec)
              else
                base_model_attributes[association_name] = []
              end

            elsif association_type == :belongs_to
              # Not currently supported
              fail ArgumentError, ":belongs_to associations not yet supported in the model spec"
            end
          end
        end
      end

      return result
    end

    def filtered_attributes(object, spec)
      if spec[:columns]   # user specifies a whitelist
        attr = Hashie::Mash.new
        spec[:columns].each do |col_name|
          attr.merge!(col_name => object.send(col_name)) # if object.respond_to?(col_name) # testing without the if - not necessary since switched to preloading
        end
        return attr
      elsif spec[:exclude_columns]   # user specifies columns to be exclude
        Hashie::Mash.new(object.attributes.reject { |k,_v| spec[:exclude_columns].include? k.to_sym})
      else
        Hashie::Mash.new  # didn't whitelist or exclude any columns
      end
    end

    def find_preloaded_record_by_id(model, id)
      return nil if @preloaded_models[model.to_s].nil?
      result = @preloaded_models[model.to_s].select { |record| record.id==id }
      fail 'Multiple preloaded records found with the same primary key (id)!' if result.count > 1
      result.count > 0 ? result.first : nil
    end

    # TODO combine this into a method that uses a single select statement for efficiency
    # TODO find_preloaded_record_by_id/ids functions could be combined into one based on whether id is a hash or integer
    def find_preloaded_records_by_ids(model, ids)
      ids.map do |id|
        preloaded_id = find_preloaded_record_by_id(model, id)
        preloaded_id.present? ? preloaded_id : nil
      end.compact
    end

    def find_preloaded_records_by_key(model, key, ids)
      @preloaded_models[model.to_s].select { |record| ids.include?(record.send(key)) }
    end

    def load_model(model_name)
      model_name.constantize.inspect
    end

    def preload_association(base_model: nil, base_model_objects: nil, association_spec: nil, base_primary_key: :id)
      unless base_model.present? && association_spec.present? && base_model_objects.present?
        fail ArgumentError, "Error preloading association: #{base_model}, #{association_spec}, #{base_model_objects}"
      end

      if association_spec[:association_type] == :has_many
        ids = base_model_objects.map { |bm| bm.send(base_primary_key) }
        preload_model(association_spec, association_spec[:foreign_key], ids)
      elsif association_type==:belongs_to
        # Only has_many currently supported for preloading
      end
    end

    def preload_includes?(model, ids)
      # Make this more efficient by having it break on the first fail
      ids.reduce(true) { |pass, id| pass && find_preloaded_record_by_id(model, id).present? }
    end

    # Enters into the preload Hash records from 'model' where 'key' IN (['ids'])
    def preload_model(model_spec, key, ids)
      model_name = model_spec[:base_model].to_s
      @preloaded_models[model_name] ||= []

      ar_relation = apply_filters_to_model(model_spec)
      all_records = ar_relation.where(key => ids).all

      all_records.each do |r|
        @preloaded_models[model_name].delete_if { |pr| pr.id == r.id } # so that we don't have any duplicates
        @preloaded_models[model_name] << r
      end
    end

  end
end
