# Groupdate

The simplest way to group by:

- day
- week
- hour of the day
- and more (complete list below)

:tada: Time zones supported!! **the best part**

:cake: Get the entire series - **the other best part**

Works with Rails 3.1+

Supports PostgreSQL and MySQL, plus arrays and hashes

[![Build Status](https://travis-ci.org/ankane/groupdate.svg?branch=master)](https://travis-ci.org/ankane/groupdate)

:cupid: Goes hand in hand with [Chartkick](http://ankane.github.io/chartkick/)

## Get Started

Group by day

```ruby
User.group_by_day(:created_at).count
# {
#   2013-04-16 00:00:00 UTC => 50,
#   2013-04-17 00:00:00 UTC => 100,
#   2013-04-18 00:00:00 UTC => 34
# }
```

Results are returned in ascending order by default, so no need to sort.

You can also group by:

- second
- minute
- hour
- week
- month
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
#   2013-03-10 00:00:00 PST => 70,
#   2013-03-17 00:00:00 PDT => 54,
#   2013-03-24 00:00:00 PDT => 80
# }
```

Time zone objects also work.

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

### Format

To get keys in a different format, use:

```ruby
User.group_by_day(:created_at, format: "%b %-e, %Y").count
# {
#   "Jan 1, 2015" => 10
#   "Jan 2, 2015" => 12
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

Takes a `String`, which is passed to [strftime](http://strfti.me/), or a `Proc`.  You can pass a locale with the `locale` option.

### Dynamic Grouping

```ruby
User.group_by_period(:day, :created_at).count
```

Limit groupings with the `permit` option.

```ruby
User.group_by_period(params[:period], :created_at, permit: %w[day week]).count
```

Raises an `ArgumentError` for unpermitted periods.

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

## Upgrading to 2.0

Groupdate 2.0 brings a number a great improvements.  Here are two things to be aware of:

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
