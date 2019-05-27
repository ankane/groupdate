## 4.1.2

- Fixed error with empty data and `current: false`
- Fixed error in time zone check for Rails < 5.2
- Prevent infinite loop with endless ranges

## 4.1.1

- Made column resolution consistent with `group`
- Added support for `alias_attribute`

## 4.1.0

- Many performance improvements
- Added check for consistent time zone info
- Fixed error message for invalid queries with MySQL and SQLite
- Fixed issue with enumerable methods ignoring nils

## 4.0.2

- Make `current` option work without `last`
- Fixed default value for `maximum`, `minimum`, and `average` (periods with no results now return `nil` instead of `0`, pass `default_value: 0` for previous behavior)

## 4.0.1

- Fixed incorrect range with `last` option near time change

## 4.0.0

- Custom calculation methods are supported by default - `groupdate_calculation_methods` is no longer needed

Breaking changes

- Dropped support for Rails < 4.2
- Invalid options now throw an `ArgumentError`
- `group_by` methods return an `ActiveRecord::Relation` instead of a `Groupdate::Series`
- `week_start` now affects `day_of_week`
- Removed support for `reverse_order` (was never supported in Rails 5)

## 3.2.1

- Added `minute_of_hour`
- Added support for `unscoped`

## 3.2.0

- Added limited support for SQLite

## 3.1.1

- Fixed `current: false`
- Fixed `last` with `group_by_quarter`
- Raise `ArgumentError` when `last` option is not supported

## 3.1.0

- Better support for date columns with `time_zone: false`
- Better date range handling for `range` option

## 3.0.2

- Fixed `group_by_period` with associations
- Fixed `week_start` option for enumerables

## 3.0.1

- Added support for Redshift
- Fix for infinite loop in certain cases for Rails 5

## 3.0.0

Breaking changes

- `Date` objects are now returned for day, week, month, quarter, and year by default. Use `dates: false` for the previous behavior, or change this globally with `Groupdate.dates = false`.
- Array and hash methods no longer return the entire series by default. Use `series: true` for the previous behavior.
- The `series: false` option now returns the correct types and order, and plays nicely with other options.

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
