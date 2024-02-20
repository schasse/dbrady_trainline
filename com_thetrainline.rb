# frozen_string_literal: true

require 'time'
require_relative 'trainline_api'

class ComThetrainline
  def self.find(from, to, departure_at)
    new(from, to, departure_at).segments
  end

  def initialize(from, to, departure_at)
    @from = from
    @to = to
    @departure_at = departure_at
  end
  attr_reader :from, :to, :departure_at

  def segments
    journeys.values.map do |journey|
      section_id = journey['sections'].first
      next if section_id.nil? # NOTE: unsellable ticket

      fares = fares_for section_id
      times = times_for journey

      {
        departure_station: departure_station_for(journey),
        departure_at: times[:departure_at],
        arrival_station: arrival_station_for(journey),
        arrival_at: times[:arrival_at],
        service_agencies: ['thetrainline'],
        duration_in_minutes: times[:duration_in_minutes],
        changeovers: (journey['legs'].size - 1),
        products: products_for(journey),
        fares:
      }
    end.compact
  end

  def departure_station_for(journey)
    start_leg = legs[journey['legs'].first]
    departure_location = locations[start_leg['departureLocation']]
    departure_location['name']
  end

  def arrival_station_for(journey)
    end_leg = legs[journey['legs'].last]
    arrival_location = locations[end_leg['arrivalLocation']]
    arrival_location['name']
  end

  def times_for(journey)
    departure_at = DateTime.parse(journey['departAt'])
    arrival_at = DateTime.parse(journey['arriveAt'])
    {
      departure_at:,
      arrival_at:,
      duration_in_minutes: ((arrival_at - departure_at) * 24 * 60).to_i
    }
  end

  def products_for(journey)
    journey['legs'].map do |leg_id|
      leg = legs[leg_id]
      transport_modes[leg['transportMode']]['mode']
    end.uniq
  end

  def fares_for(section_id)
    sections.dig(section_id, 'alternatives').map do |alternative_id|
      alternative = alternatives[alternative_id]
      fare = fares[alternative['fares'].first]
      if alternative['fares'].size > 1
        # NOTE: so far it seems like every alternative has exactly one fare
        warn 'WARN: multiple fares per alternative found'
      end
      {
        name: fare_name_for(fare),
        price_in_cents: price_in_cents_for(alternative),
        currency: currency_for(alternative),
        comfort_class: comfort_class_for(fare)
      }
    end
  end

  def fare_name_for(fare)
    fare_types[fare['fareType']]['name']
  end

  def price_in_cents_for(alternative)
    (alternative.dig('fullPrice', 'amount') * 100).to_i
  end

  def currency_for(alternative)
    alternative.dig 'fullPrice', 'currencyCode'
  end

  def comfort_class_for(fare)
    fare['fareLegs'].map do |fare_leg|
      name = fare_leg['travelClass']['name'].downcase
      if name =~ /first/
        1
      else
        2
      end
    end.max
  end

  # below: data from response

  def journeys
    trainline_journey_search_result.dig 'data', 'journeySearch', 'journeys'
  end

  def sections
    trainline_journey_search_result.dig 'data', 'journeySearch', 'sections'
  end

  def legs
    trainline_journey_search_result.dig 'data', 'journeySearch', 'legs'
  end

  def locations
    trainline_journey_search_result.dig 'data', 'locations'
  end

  def fares
    trainline_journey_search_result.dig 'data', 'journeySearch', 'fares'
  end

  def fare_types
    trainline_journey_search_result.dig 'data', 'fareTypes'
  end

  def alternatives
    trainline_journey_search_result.dig 'data', 'journeySearch', 'alternatives'
  end

  def transport_modes
    trainline_journey_search_result.dig 'data', 'transportModes'
  end

  # below: caching the trainline requests

  def trainline_journey_search_result
    @trainline_journey_search_result ||=
      TrainlineApi.journey_search(
        trainline_origin['code'], trainline_destination['code'], departure_at
      )
  end

  def trainline_origin
    @trainline_origin ||=
      TrainlineApi.location_search(from)['searchLocations'].first
  end

  def trainline_destination
    @trainline_destination ||=
      TrainlineApi.location_search(to)['searchLocations'].first
  end
end
