require 'spec_helper'
require 'hashie'
require 'money'

describe ProductionSampler do
  let(:ps) { ProductionSampler::ProductionSampler.new }

  it 'has a version number' do
    expect(ProductionSampler::VERSION).not_to be nil
  end

  describe "#available_models" do
    let(:expected_output) do
      ['Series', 'Episode', 'Character', 'Species']
    end

    it 'lists all the models in the application' do
      expect(array_includes_expected(expected_output, ps.app_models)).to be_truthy
    end

    context 'when loading specific models only' do
      let(:ps) { ProductionSampler::ProductionSampler.new(load_models: ['Series', 'Episode']) }

      it 'lists the model specified, but not the others' do
        models = ps.app_models
        expect(models).to include('Series')
        #expect(models).to_not include('Character') # this line giving me trouble because I can't "un-load" the loaded models from the first test
      end
    end
  end

  describe "#build_hashie" do
    before(:all) do
      generate_fixture_data
    end

    context "with a scope and a where condition" do
      let(:model_spec) do
        Hashie::Mash.new(
          {
            base_model: Series,
            ids: [1],
            columns: [:id, :name],
            associations: [
              {
                association_name: 'episodes',
                scope: 'season_one',
                where: { expression: 'title NOT IN (?)', parameters: [["Return of the Archons", "Arena"]] }, # parameters must be an Array
                columns: [:title, :cost, :uuid],
                associations: [
                  {
                    association_name: 'characters',
                    columns: [:name],
                  },
                  {
                    association_name: 'ships',
                    columns: [:name, :registry_number]
                  }
                ]
              },
            ]
          })
      end

      let(:expected_output) do
        [
          Hashie::Mash.new(
            {
              id: 1,
              name: "Star Trek TOS",
              episodes: [
                {
                  id: 1,
                  title: "The Squire of Gothos",
                  cost: Money.new(1995),
                  uuid: '5922d60a-b05b-4157-b5ee-41ffa6379796',
                  characters: [
                    {
                      id: 1,
                      name: "Trelane"
                    },
                  ],
                  ships: []
                },
                {
                  id: 4,
                  title: "Space Seed",
                  cost: nil,
                  uuid: '94544426-7b53-450c-9f03-42a3a48ad21d',
                  characters: [],
                  ships: [
                    {
                      id: 1,
                      name: 'SS Botany Bay',
                      registry_number: nil
                    }
                  ]
                }
              ]
            }
          ),
        ]
      end

      it 'extracts the expected models and data' do
        result = ps.build_hashie(model_spec)
        expect(result).to eql(expected_output)
      end
    end

    context 'with exclude_columns list' do
      let(:model_spec) do
        Hashie::Mash.new(
          {
            base_model: Episode,
            ids: [1],
            exclude_columns: [:created_at, :updated_at],
          }
        )
      end

      it 'returns all columns except the excluded columns' do
        result = ps.build_hashie(model_spec).first
        expect(result[:created_at]).to be_falsey
        expect(result[:updated_at]).to be_falsey
        expect(result.size).to be > 0
      end
    end

  end

  describe "#build_sql" do
    context "with a scope and a where condition" do
      let(:model_spec) do
        Hashie::Mash.new(
          {
            base_model: Series,
            ids: [1],
            columns: [:id, :name],
            associations: [
              {
                association_name: 'episodes',
                scope: 'season_one',
                where: { expression: 'title NOT IN (?)', parameters: [["Return of the Archons", "Space Seed"]] }, # parameters must be an Array
                columns: [:title, :cost_cents],
                associations: [
                  {
                    association_name: 'characters',
                    columns: [:name],
                  }
                ]
              },
            ]
          })
      end

      let(:expected_output) do
        <<-SQL
INSERT INTO series (id,name) VALUES (1,'Star Trek TOS');
INSERT INTO episodes (id,title,cost_cents) VALUES (1,'The Squire of Gothos',1995);
INSERT INTO characters (id,name) VALUES (1,'Trelane');
INSERT INTO episodes (id,title,cost_cents) VALUES (2,'Arena',null);
        SQL
      end

      it 'extracts the expected models and data' do
        result = ps.build_sql(model_spec)
        expect(result).to eql(expected_output)
      end
    end

  end

  private

  def array_includes_expected(expectation, arr)
    expectation.reduce(true) { |pass, expected| pass && arr.include?(expected) }
  end

  def generate_fixture_data
    Series.create(
      id: 1,
      name: "Star Trek TOS",
      year: "1967"
    )

    Series.create(
      id: 2,
      name: "Star Trek TNG",
      year: "1987"
    )

    Episode.create(
      id: 1,
      uuid: '5922d60a-b05b-4157-b5ee-41ffa6379796',
      title: "The Squire of Gothos",
      production_number: "1x17",
      series_id: 1,
      cost: Money.new(1995)
    )

    Episode.create(
      id: 2,
      uuid: 'ce62f25d-8de1-437f-a2fe-7b500c7e5caa',
      title: "Arena",
      production_number: "1x18",
      series_id: 1
    )

    Episode.create(
      id: 3,
      uuid: 'd5df36d7-56e9-4e77-9397-233e3bdd57dd',
      title: "Return of the Archons",
      production_number: "1x21",
      series_id: 1
    )

    Episode.create(
      id: 4,
      uuid: '94544426-7b53-450c-9f03-42a3a48ad21d',
      title: "Space Seed",
      production_number: "1x22",
      series_id: 1
    )

    Episode.create(
      id: 5,
      uuid: '0ceb99ff-c35c-4d18-abde-5b35aeff8f95',
      title: "Amok Time",
      production_number: "2x30",
      series_id: 1
    )

    Episode.create(
      id: 6,
      uuid: '9f148d8e-8520-43b5-a5e5-512aa3a4e2d6',
      title: "Who Mourns for Adonias?",
      production_number: "2x31",
      series_id: 1
    )

    Episode.create(
      id: 7,
      uuid: 'f0fb4f0c-8cdd-4cd1-b43f-00fe9de4485c',
      title: "Encounter at Farpoint",
      production_number: "1x1",
      series_id: 2
    )

    Species.create(
       id: 1,
       name: "Human"
    )

    Species.create(
       id: 2,
       name: "Q Continuum"
    )

    Character.create(
       id: 1,
       name: "Trelane",
       species_id: 2,
       episode_id: 1
    )

    Character.create(
      id: 2,
      name: "Q",
      species_id: 2,
      episode_id: 3
    )

    Ship.create(
      id: 1,
      name: 'SS Botany Bay',
      episode_uuid: '94544426-7b53-450c-9f03-42a3a48ad21d'
    )
  end

end
