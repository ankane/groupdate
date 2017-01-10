# Groupdate

The simplest way to group by:

- day
- week
- hour of the day
- and more (complete list below)

:tada: Time zones - including daylight saving time - supported!! **the best part**

:cake: Get the entire series - **the other best part**

Supports PostgreSQL, MySQL, and Redshift, plus arrays and hashes

Experimental support for [SQLite](#sqlite-experimental)

[![Build Status](https://travis-ci.org/ankane/groupdate.svg?branch=master)](https://travis-ci.org/ankane/groupdate)

:cupid: Goes hand in hand with [Chartkick](http://ankane.github.io/chartkick/)

**Groupdate 3.0 was just released!** See [instructions for upgrading](#30). If you use Chartkick with Groupdate, we recommend Chartkick 2.0 and above.

## Get Started

```ruby
User.group_by_day(:created_at).count
# {
#   Sat, 28 May 2016 => 50,
#   Sun, 29 May 2016 => 100,
#   Mon, 30 May 2016 => 34
# }
```

Results are returned in ascending order by default, so no need to sort.

You can group by:

- second
- minute
- hour
- day
- week
- month
- quarter
- year

and

- hour_of_day
- day_of_week (Sunday = 0, Monday = 1, etc)
- day_of_month
- month_of_year

Use it anywhere you can use `group`.

### Time Zones

The default time zone is `Time.zone`.  Change this with:

```ruby
Groupdate.time_zone = "Pacific Time (US & Canada)"
```

or

```ruby
User.group_by_week(:created_at, time_zone: "Pacific Time (US & Canada)").count
# {
#   Sun, 06 Mar 2016 => 70,
#   Sun, 13 Mar 2016 => 54,
#   Sun, 20 Mar 2016 => 80
# }
```

Time zone objects also work. To see a list of available time zones in Rails, run `rake time:zones:all`.

### Week Start

Weeks start on Sunday by default. Change this with:

```ruby
Groupdate.week_start = :mon # first three letters of day
```

or

```ruby
User.group_by_week(:created_at, week_start: :mon).count
```

### Day Start

You can change the hour days start with:

```ruby
Groupdate.day_start = 2 # 2 am - 2 am
```

or

```ruby
User.group_by_day(:created_at, day_start: 2).count
```

### Time Range

To get a specific time range, use:

```ruby
User.group_by_day(:created_at, range: 2.weeks.ago.midnight..Time.now).count
```

To get the most recent time periods, use:

```ruby
User.group_by_week(:created_at, last: 8).count # last 8 weeks
```

To exclude the current period, use:

```ruby
User.group_by_week(:created_at, last: 8, current: false).count
```

### Order

You can order in descending order with:

```ruby
User.group_by_day(:created_at).reverse_order.count
```

or

```ruby
User.group_by_day(:created_at).order("day desc").count
```

### Keys

Keys are returned as date or time objects for the start of the period.

To get keys in a different format, use:

```ruby
User.group_by_month(:created_at, format: "%b %Y").count
# {
#   "Jan 2015" => 10
#   "Feb 2015" => 12
# }
```

or

```ruby
User.group_by_hour_of_day(:created_at, format: "%-l %P").count
# {
#    "12 am" => 15,
#    "1 am"  => 11
#    ...
# }
```

Takes a `String`, which is passed to [strftime](http://strfti.me/), or a `Symbol`, which is looked up by `I18n.localize` in `i18n` scope 'time.formats', or a `Proc`.  You can pass a locale with the `locale` option.

### Series

The entire series is returned by default. To exclude points without data, use:

```ruby
User.group_by_day(:created_at, series: false).count
```

Or change the default value with:

```ruby
User.group_by_day(:created_at, default_value: "missing").count
```

### Dynamic Grouping

```ruby
User.group_by_period(:day, :created_at).count
```

Limit groupings with the `permit` option.

```ruby
User.group_by_period(params[:period], :created_at, permit: %w[day week]).count
```

Raises an `ArgumentError` for unpermitted periods.

### Date Columns

If grouping on date columns which don’t need time zone conversion, use:

```ruby
User.group_by_week(:created_on, time_zone: false).count
```

## Arrays and Hashes

```ruby
users.group_by_day { |u| u.created_at } # or group_by_day(&:created_at)
```

Supports the same options as above

```ruby
users.group_by_day(time_zone: time_zone) { |u| u.created_at }
```

Count

```ruby
Hash[ users.group_by_day { |u| u.created_at }.map { |k, v| [k, v.size] } ]
```

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'groupdate'
```

#### For MySQL

[Time zone support](http://dev.mysql.com/doc/refman/5.6/en/time-zone-support.html) must be installed on the server.

```sh
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
```

or copy and paste [these statements](https://gist.githubusercontent.com/ankane/1d6b0022173186accbf0/raw/time_zone_support.sql) into a SQL console.

You can confirm it worked with:

```sql
SELECT CONVERT_TZ(NOW(), '+00:00', 'Etc/UTC');
```

It should return the time instead of `NULL`.

## SQLite [experimental]

Groupdate has limited support for SQLite.

- No time zone support
- No `day_start` or `week_start` options
- No `group_by_quarter` method

To install, add this line to your application’s Gemfile:

```ruby
gem 'groupdate', github: 'ankane/groupdate', branch: 'sqlite'
```

If your application’s time zone is set to something other than `Etc/UTC`, create an initializer with:

```ruby
Groupdate.time_zone = false
```

## Upgrading

### 3.0

Groupdate 3.0 brings a number of improvements.  Here are a few to be aware of:

- `Date` objects are now returned for day, week, month, quarter, and year by default. Use `dates: false` for the previous behavior, or change this globally with `Groupdate.dates = false`.
- Array and hash methods no longer return the entire series by default. Use `series: true` for the previous behavior.
- The `series: false` option now returns the correct type and order, and plays nicely with other options.

### 2.0

Groupdate 2.0 brings a number of improvements.  Here are two things to be aware of:

- the entire series is returned by default
- `ActiveSupport::TimeWithZone` keys are now returned for every database adapter - adapters previously returned `Time` or `String` keys

## History

View the [changelog](https://github.com/ankane/groupdate/blob/master/CHANGELOG.md)

Groupdate follows [Semantic Versioning](http://semver.org/)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/groupdate/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/groupdate/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
