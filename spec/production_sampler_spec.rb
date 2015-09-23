require 'spec_helper'

describe ProductionSampler do
  it 'has a version number' do
    expect(ProductionSampler::VERSION).not_to be nil
  end

  describe "#available_models" do
    let(:ps) { ProductionSampler::ProductionSampler.new }
    let(:expected_output) do
      ["Faction", "Ship", "CrewMember"]
    end

    it 'lists all the models in the application' do
      expect(array_includes_expected(expected_output, ps.app_models)).to be_truthy
    end


  end

  describe "#sample_data" do
    let(:data_to_sample) do
      {
        Faction: {
          criteria:      { id: 2 },
          associations:  [:Ship]
        }
      }
    end

  end

  private

  def array_includes_expected(expectation, arr)
    expectation.reduce(false) { |pass, expected| arr.include?(expected) }
  end

end
