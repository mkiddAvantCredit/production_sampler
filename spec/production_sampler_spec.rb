require 'spec_helper'
require 'hashie'

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
  end

  describe "#build_hashie" do
    let(:association_paths) do
      Hashie::Mash.new(
      {
        base_model: Series,
        ids: [1],
        columns: [:id, :name],
        associations: [
          {
          association_name: 'episodes',
          columns: [:title],
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

    let (:expected_output) do
      [
        Hashie::Mash.new(
          {
            id: 1,
            name: "Star Trek TOS",
            episodes: [
              {
                title: "The Squire of Gothos",
                characters: [
                  {
                    name: "Trelane"
                  },
                ]
              },
              {
                title: "Arena"
              }
            ]
          }
        ),
      ]
    end

    before(:all) do
      generate_fixture_data
    end

    it 'extracts the expected models and data' do
      result = ps.build_hashie(association_paths)
      expect(result).to eql(expected_output)
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
      title: "The Squire of Gothos",
      production_number: "1x17",
      series_id: 1
    )

    Episode.create(
      id: 2,
      title: "Arena",
      production_number: "1x18",
      series_id: 1
    )

    Episode.create(
      id: 3,
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
  end

end
