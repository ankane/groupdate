## 2.5.3

- All tests green with `mysql` gem
- Added support for decimal day start

## 2.5.2

- Added `dates` option to return dates for day, week, month, quarter, and year

## 2.5.1

- Added `group_by_quarter`
- Added `default_value` option
- Accept symbol for `format` option
- Raise `ArgumentError` if no field specified
- Added support for ActiveRecord 5 beta

## 2.5.0

- Added `group_by_period` method
- Added `current` option
- Raise `ArgumentError` if no block given to enumerable

## 2.4.0

- Added localization
- Added `carry_forward` option
- Added `series: false` option for arrays and hashes
- Fixed issue w/ Brasilia Summer Time
- Fixed issues w/ ActiveRecord 4.2

## 2.3.0

- Raise error when ActiveRecord::Base.default_timezone is not `:utc`
- Added `day_of_month`
- Added `month_of_year`
- Do not quote column name

## 2.2.1

- Fixed ActiveRecord 3 associations

## 2.2.0

- Added support for arrays and hashes

## 2.1.1

- Fixed format option with multiple groups
- Better error message if time zone support is missing for MySQL

## 2.1.0

- Added last option
- Added format option

## 2.0.4

- Added multiple groups
- Added order
- Subsequent methods no longer modify relation

## 2.0.3

- Implemented respond_to?

## 2.0.2

- where, joins, and includes no longer need to be before the group_by method

## 2.0.1

- Use time zone instead of UTC for results

## 2.0.0

- Returns entire series by default
- Added day_start option
- Better interface

## 1.0.5

- Added global time_zone option

## 1.0.4

- Added global week_start option
- Fixed bug with NULL values and series

## 1.0.3

- Fixed deprecation warning when used with will_paginate
- Fixed bug with DateTime series

## 1.0.2

- Added :start option for custom week start for group_by_week

## 1.0.1

- Fixed series for Rails < 3.2 and MySQL

## 1.0.0

- First major release
