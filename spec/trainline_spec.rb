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

    it 'returns sane segments with fares' do
      from = 'London'
      to = 'Manchester'
      segments = ComThetrainline.find(from, to, departure_at)
      expect(segments.size).to eq 5

      segment = segments.first
      expect(segment.keys.size).to eq 9
      expect(segment[:departure_station]).to eq 'London Euston'
      expect(segment[:departure_at]).to eq DateTime.new(2024, 2, 22, 9, 33)
      expect(segment[:arrival_station]).to eq 'Manchester Piccadilly'
      expect(segment[:arrival_at]).to eq DateTime.new(2024, 2, 22, 11, 44)
      expect(segment[:service_agencies]).to eq ['thetrainline']
      expect(segment[:duration_in_minutes]).to eq 131
      expect(segment[:changeovers]).to eq 0
      expect(segment[:products]).to eq ['train']

      fare = segment[:fares].first
      expect(fare.keys.size).to eq 4
      expect(fare[:name]).to eq 'Off-Peak Single'
      expect(fare[:price_in_cents]).to eq 8925
      expect(fare[:currency]).to eq 'EUR'
      expect(fare[:comfort_class]).to eq 2
    end
  end
end
