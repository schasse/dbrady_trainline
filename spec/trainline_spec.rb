# frozen_string_literal: true

require_relative '../trainline'
require 'pry'

RSpec.describe ComThetrainline do
  let(:departure_at) { DateTime.new(2024, 2, 22, 9, 30) }
  let(:location_london_response) do
    file = File.expand_path(
      'trainline_api_location_london.json', __dir__
    )
    JSON.parse(File.read(file))
  end
  let(:location_manchester_response) do
    file = File.expand_path(
      'trainline_api_location_manchester.json', __dir__
    )
    JSON.parse(File.read(file))
  end
  let(:journey_london_manchester_response) do
    file = File.expand_path(
      'trainline_api_journey_london_manchester.json', __dir__
    )
    JSON.parse(File.read(file))
  end

  describe '.find' do
    before do
      allow(TrainLineApi).to receive(:journey_search).with(
        'urn:trainline:generic:loc:182gb',
        'urn:trainline:generic:loc:MAN2968gb',
        departure_at
      ).and_return(journey_london_manchester_response)
      allow(TrainLineApi).to receive(:location_london_response).with(
        'London'
      ).and_return(location_london_response)
      allow(TrainLineApi).to receive(:location_london_response).with(
        'Manchester'
      ).and_return(location_manchester_response)
    end

    it 'returns the segments' do
      from = 'London'
      to = 'Manchester'
      res = ComThetrainline.find(from, to, departure_at)
      binding.pry
    end
  end
end
