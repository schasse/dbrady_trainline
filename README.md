# dbrady_trainline

Api that triggers searches on https://trainline.com and returns results in a specific format.

## example usage

``` ruby
require 'com_thetrainline'

ComThetrainline.find('Berlin', 'München', DateTime.new(2024, 3, 1))

# =>
# [{:departure_station=>"Berlin Hbf (tief)",
#   :departure_at=>#<DateTime: 2024-03-01T04:30:00+01:00 ((2460371j,12600s,0n),+3600s,2299161j)>,
#   :arrival_station=>"München Hbf",
#   :arrival_at=>#<DateTime: 2024-03-01T09:17:00+01:00 ((2460371j,29820s,0n),+3600s,2299161j)>,
#   :service_agencies=>["thetrainline"],
#   :duration_in_minutes=>287,
#   :changeovers=>0,
#   :products=>["train"],
#   :fares=>
#    [{:name=>"Super Sparpreis", :price_in_cents=>8190, :currency=>"EUR", :comfort_class=>1},
#     {:name=>"Sparpreis", :price_in_cents=>9290, :currency=>"EUR", :comfort_class=>1},
#     {:name=>"Flexpreis", :price_in_cents=>32460, :currency=>"EUR", :comfort_class=>1},
#     {:name=>"Super Sparpreis", :price_in_cents=>6990, :currency=>"EUR", :comfort_class=>2},
#     {:name=>"Sparpreis", :price_in_cents=>7890, :currency=>"EUR", :comfort_class=>2},
#     {:name=>"Flexpreis", :price_in_cents=>18030, :currency=>"EUR", :comfort_class=>2}]},
# ...
```

## installation

``` bash
git clone git@github.com:schasse/dbrady_trainline.git
cd dbrady_trainline
irb -r ./com_thetrainline.rb
```
(tested with ruby version 3.2.3)
