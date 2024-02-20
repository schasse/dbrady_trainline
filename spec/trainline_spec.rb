# frozen_string_literal: true

require_relative '../com_thetrainline'

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
    context 'with valid TrainlineApi responses' do
      before do
        allow(TrainlineApi).to receive(:journey_search).with(
          'urn:trainline:generic:loc:182gb',
          'urn:trainline:generic:loc:MAN2968gb',
          departure_at
        ).and_return(journey_london_manchester_response)
        allow(TrainlineApi).to receive(:location_london_response).with(
          'London'
        ).and_return(location_london_response)
        allow(TrainlineApi).to receive(:location_london_response).with(
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

    context 'with TrainlineApi returning an error' do
      before do
        allow(TrainlineApi).to receive(:journey_search).and_return(
          [
            {
              'code' => 'ItinerarySearch.Request.Validation'\
                        '.TransitDefinition.InvalidFormat',
              'severity' => 'correctable',
              'detail' => 'TransitDefinitions time must not be'\
                          ' more than 2 days in the past'
            }
          ]
        )
        allow(TrainlineApi).to receive(:location_london_response).with(
          'London'
        ).and_return(location_london_response)
        allow(TrainlineApi).to receive(:location_london_response).with(
          'Manchester'
        ).and_return(location_manchester_response)
      end

      it 'returns an empty array' do
        from = 'London'
        to = 'Manchester'
        segments = ComThetrainline.find(from, to, departure_at)
        expect(segments).to eq []
      end
    end
  end

  describe '#comfort_class_for' do
    let(:com_thetrainline) { ComThetrainline.new(nil, nil, nil) }
    {
      %w[First Second] => 2,
      %w[Second First] => 2,
      %w[first first] => 1,
      %w[Second Second] => 2
    }.each do |comfort_classes, result|
      it "returns the lowest comfort class (#{comfort_classes} => #{result})" do
        fare_stub = {
          'fareLegs' =>
          comfort_classes.map do
            {
              'travelClass' => { 'name' => _1 }
            }
          end
        }

        expect(com_thetrainline.comfort_class_for(fare_stub)).to eq result
      end
    end
  end

  describe '#times_for' do
    let(:com_thetrainline) { ComThetrainline.new(nil, nil, nil) }
    let(:journey) do
      {
        'departAt' => '2023-12-01T08:00:00',
        'arriveAt' => '2023-12-01T10:30:00'
      }
    end

    it 'returns the correct departure and arrival times' do
      times = com_thetrainline.times_for journey

      expect(times[:departure_at]).to eq DateTime.new(2023, 12, 1, 8)
      expect(times[:arrival_at]).to eq DateTime.new(2023, 12, 1, 10, 30)
      expect(times[:duration_in_minutes]).to eq 150
    end
  end
end
