# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'cgi'
require 'time'

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
    journeys =
      trainline_journey_search_result['data']['journeySearch']['journeys']

    journeys.values.map do |journey|
      departure_at = DateTime.parse(journey['departAt'])
      arrival_at = DateTime.parse(journey['arriveAt'])

      start_leg = leg_from journey['legs'].first
      end_leg = leg_from journey['legs'].last

      departure_location = location_from start_leg['departureLocation']
      arrival_location = location_from end_leg['arrivalLocation']

      section_id = journey['sections'].first
      next if section_id.nil? # NOTE: unsellable ticket

      fares = trainline_journey_search_result.dig(
        'data', 'journeySearch', 'sections', section_id, 'alternatives'
      ).map do |alternative_id|
        alternative =
          trainline_journey_search_result
          .dig('data', 'journeySearch', 'alternatives', alternative_id)
        fare =
          trainline_journey_search_result
          .dig('data', 'journeySearch', 'fares', alternative['fares'].first)

        name = trainline_journey_search_result['data']['fareTypes'][fare['fareType']]['name']
        price_in_cents = (alternative['fullPrice']['amount'] * 100).to_i
        currency = alternative['fullPrice']['currencyCode']

        # TODO: could be multiple class
        # TODO: translate to 1 or 2
        comfort_class = fare['fareLegs'].first['travelClass']['name']

        {
          name:,
          price_in_cents:,
          currency:,
          comfort_class:
        }
      end

      {
        departure_station: departure_location['name'],
        departure_at:,
        arrival_station: arrival_location['name'],
        arrival_at:,
        service_agencies: ['thetrainline'],
        duration_in_minutes: ((arrival_at - departure_at) * 24 * 60).to_i,
        changeovers: (journey['legs'].size - 1),
        products: ['train'],
        fares:
      }
    rescue StandardError => e
      binding.pry
    end
  end

  def leg_from(id)
    trainline_journey_search_result['data']['journeySearch']['legs'][id]
  end

  def location_from(id)
    trainline_journey_search_result['data']['locations'][id]
  end

  def trainline_journey_search_result
    @trainline_journey_search_result ||=
      TrainLineApi.journey_search(
        trainline_origin['code'], trainline_destination['code'], departure_at
      )
  end

  def trainline_origin
    @trainline_origin ||=
      TrainLineApi.location_search(from)['searchLocations'].first
  end

  def trainline_destination
    @trainline_destination ||=
      TrainLineApi.location_search(to)['searchLocations'].first
  end
end

class TrainLineApi
  def self.journey_search(origin, destination, depart_after)
    post_body =
      {
        'passengers' => [
          { 'id' => 'pid-0', 'dateOfBirth' => '1991-07-13', 'cardIds' => [] }
        ],
        'isEurope' => true,
        'cards' => [],
        'transitDefinitions' =>
        [
          {
            'direction' => 'outward',
            'origin' => origin,
            'destination' => destination,
            'journeyDate' => {
              'type' => 'departAfter',
              'time' => depart_after.strftime('%Y-%m-%dT%H:%M:%S')
            }
          }
        ],
        'type' => 'single',
        'maximumJourneys' => 5,
        'includeRealtime' => true,
        'transportModes' => ['mixed'],
        'directSearch' => false,
        'composition' => ['through', 'interchangeSplit']
      }
    trainline_response_for :post, '/api/journey-search/', post_body
  end

  def self.location_search(search_term)
    trainline_response_for(
      :get,
      '/api/locations-search/v2/search?locale=en-US&'\
      "searchTerm=#{CGI.escape(search_term)}",
      nil
    )
  end

  def self.trainline_response_for(method, path, request_body)
    url = URI("https://www.thetrainline.com#{path}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = build_trainline_request(method, url)
    request.body = request_body.to_json unless request_body.nil?
    response = http.request(request)
    JSON.parse response.read_body
  end

  def self.build_trainline_request(method, url)
    headers = {
      'Content-Type' => 'application/json',
      'Cookie' => 'pdt=b9f2d079-eb01-4a29-a1cc-690ade250862; customerUserCountry=DE; tl_sid=s%3A36869929-c41a-4497-aa05-6db3c0a89ee0.hFugzh%2BH3ONYnUUe9S9b46RSXS5Fxu2DSYZz9fO0fpE; context_id=faf792ef-ce97-4e4d-beb1-e3f4f8a74ccc; currency_code=EUR; __adal_ses=*; __adal_id=53ebbee1-6598-48b2-960d-2337fc470403.1708352145.1.1708352145.1708352145.2a6b2911-45b8-4317-b9c8-8431c6071fd0; __adal_ca=so%3Ddirect%26me%3Dnone%26ca%3Ddirect%26co%3D%28not%2520set%29%26ke%3D%28not%2520set%29%26cg%3DDirect; __adal_cw=1708352145158; ravelinDeviceId=rjs-a6f23c3d-8a72-4d37-8c71-9cf6d538e4c8; ravelinSessionId=rjs-a6f23c3d-8a72-4d37-8c71-9cf6d538e4c8:eb356c67-1870-4018-8c87-192f0c2bb9e9; datadome=vdeODoMHGYnZ1eaMr3XQyM0W6u~DZB8Lrde1DK3Tp64chG2svs7FHhYXWOgm4u8hTg6VLhmJAuZFR86FP0UseIO24H6qA992xxgT4~vrZK6KIO_3d7lrEHYP7n9~FGgJ',
      'Accept' => 'application/json',
      'Accept-Language' => 'en-US',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15',
      'X-Version' => '4.35.28172',
      'Accept-Encoding' => 'identity'
    }
    case method
    when :get
      Net::HTTP::Get.new(url, headers)
    when :post
      Net::HTTP::Post.new(url, headers)
    else
      raise 'method not implemented'
    end
  end
end
