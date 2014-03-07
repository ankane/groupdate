# Groupdate

The simplest way to group by:

- day
- week
- month
- day of the week
- hour of the day
- and more (complete list at bottom)

:tada: Time zones supported!! **the best part**

:cake: Get the entire series - **the other best part**

Works with Rails 3.0+

Supports PostgreSQL and MySQL

[![Build Status](https://travis-ci.org/ankane/groupdate.png)](https://travis-ci.org/ankane/groupdate)

:cupid: Goes hand in hand with [Chartkick](http://ankane.github.io/chartkick/)

## Get Started

```ruby
User.group_by_day(:created_at).count
# {
#   2013-04-16 00:00:00 UTC => 50,
#   2013-04-17 00:00:00 UTC => 100,
#   2013-04-18 00:00:00 UTC => 34
# }

Task.group_by_month(:updated_at).count
# {
#   2013-02-01 00:00:00 UTC => 84,
#   2013-03-01 00:00:00 UTC => 23,
#   2013-04-01 00:00:00 UTC => 44
# }

Goal.group_by_year(:accomplished_at).count
# {
#   2011-01-01 00:00:00 UTC => 7,
#   2012-01-01 00:00:00 UTC => 11,
#   2013-01-01 00:00:00 UTC => 3
# }
```

Results are returned in ascending order, so no need to sort.

The default time zone is `Time.zone`.  Pass a time zone with:

```ruby
User.group_by_week(:created_at, time_zone: "Pacific Time (US & Canada)").count
# {
#   2013-03-03 08:00:00 UTC => 80,
#   2013-03-10 08:00:00 UTC => 70,
#   2013-03-17 07:00:00 UTC => 54
# }

# equivalently
time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
User.group_by_week(:created_at, time_zone: time_zone).count
```

**Note:** Weeks start on Sunday by default.

You can also group by the day of the week or hour of the day.

```ruby
# day of the week
User.group_by_day_of_week(:created_at).count
# {
#   0 => 54, # Sunday
#   1 => 2,  # Monday
#   ...
#   6 => 3   # Saturday
# }

# hour of the day
User.group_by_hour_of_day(:created_at, time_zone: "Pacific Time (US & Canada)").count
# {
#   0 => 34,
#   1 => 61,
#   ...
#   23 => 12
# }
```

Go nuts!

```ruby
Request.where(page: "/home").group_by_minute(:started_at).average(:request_time)
```

## Customize

You can change the day weeks start with:

```ruby
User.group_by_week(:created_at, week_start: :mon) # first three letters of day

# change globally
Groupdate.week_start = :mon
```

You can change the hour days start with:

```ruby
User.group_by_day(:created_at, day_start: 2) # 2 am - 2 am

# change globally
Groupdate.day_start = 2
```

This works with `week`, `month`, `year` and `hour_of_day`.

The default time zone is `Time.zone`.  To change this, use:

```ruby
Groupdate.time_zone = "Pacific Time (US & Canada)"
```

To return an `ActiveRecord::Relation` instead of a `Groupdate::Series`, use:

```ruby
User.group_by_day(:created_at, series: false)
```

**Note:** Results will be unordered, and days with no records will not appear.

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

#### For JRuby

Use the master version of your JDBC adapter.  You will get incorrect results for versions before [this commit](https://github.com/jruby/activerecord-jdbc-adapter/commit/c1cdb7cec8d3f06fc54995e8d872d830bd0a4d91).

```ruby
# postgresql
gem "activerecord-jdbcpostgresql-adapter", :github => "jruby/activerecord-jdbc-adapter"

# mysql
gem "activerecord-jdbcmysql-adapter", :github => "jruby/activerecord-jdbc-adapter"
```

## Complete list

group_by_?

- second
- minute
- hour
- day
- week
- month
- year
- hour_of_day
- day_of_week

## History

View the [changelog](https://github.com/ankane/groupdate/blob/master/CHANGELOG.md)

Groupdate follows [Semantic Versioning](http://semver.org/)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/groupdate/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/groupdate/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
