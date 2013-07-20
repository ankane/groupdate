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

## Usage

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

The default time zone is `Time.zone`.  Pass a time zone as the second argument.

```ruby
User.group_by_week(:created_at, "Pacific Time (US & Canada)").count
# {
#   2013-03-03 08:00:00 UTC => 80,
#   2013-03-10 08:00:00 UTC => 70,
#   2013-03-17 07:00:00 UTC => 54
# }

# equivalently
time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
User.group_by_week(:created_at, time_zone).count
```

**Note:** Weeks start on Sunday by default. For other days, use:

```ruby
User.group_by_week(:created_at, :start => :mon) # first three letters of day

# must be the last argument
User.group_by_week(:created_at, time_zone, :start => :sat)

# change globally
Groupdate.week_start = :mon
```

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
User.group_by_hour_of_day(:created_at, "Pacific Time (US & Canada)").count
# {
#   0 => 34,
#   1 => 61,
#   ...
#   23 => 12
# }
```

You can order results with:

```ruby
User.group_by_day(:created_at).order("day asc").count

User.group_by_week(:created_at).order("week desc").count

User.group_by_hour_of_day(:created_at).order("hour_of_day asc").count
```

Use it with anywhere you can use `group`.

```ruby
Task.completed.group_by_hour(:completed_at).average(:priority)
```

Go nuts!

```ruby
Request.where(page: "/home").group_by_minute(:started_at).maximum(:request_time)
```

### Show me the series :moneybag:

You have two users - one created on May 2 and one on May 5.

```ruby
User.group_by_day(:created_at).count
# {
#   2013-05-02 00:00:00 UTC => 1,
#   2013-05-05 00:00:00 UTC => 1
# }
```

Awesome, but you want to see the first week of May.  Pass a range as the third argument.

```ruby
# pretend today is May 7
time_range = 6.days.ago..Time.now

User.group_by_day(:created_at, Time.zone, time_range).count
# {
#   2013-05-01 00:00:00 UTC => 0,
#   2013-05-02 00:00:00 UTC => 1,
#   2013-05-03 00:00:00 UTC => 0,
#   2013-05-04 00:00:00 UTC => 0,
#   2013-05-05 00:00:00 UTC => 1,
#   2013-05-06 00:00:00 UTC => 0,
#   2013-05-07 00:00:00 UTC => 0
# }

User.group_by_day_of_week(:created_at, Time.zone, time_range).count
# {
#   0 => 0,
#   1 => 1,
#   2 => 0,
#   3 => 0,
#   4 => 1,
#   5 => 0,
#   6 => 0
# }
```

Results are returned in ascending order, so no need to sort.

Also, this form of the method returns a Groupdate::Series instead of an ActiveRecord::Relation.  ActiveRecord::Relation method calls (like `where` and `joins`) should come before this.

## Installation

Add this line to your application's Gemfile:

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

## Note

activerecord <= 4.0.0.beta1 and the pg gem returns String objects instead of Time objects.
[This is fixed on activerecord master](https://github.com/rails/rails/commit/2cc09441c2de57b024b11ba666ba1e72c2b20cfe)

```ruby
User.group_by_day(:created_at).count

# mysql2
# pg and activerecord master
{2013-04-22 00:00:00 UTC => 1} # Time object

# pg and activerecord <= 4.0.0.beta1
{"2013-04-22 00:00:00+00" => 1} # String
```

Another data type inconsistency

```ruby
User.group_by_day_of_week(:created_at).count

# mysql2
{0 => 1, 4 => 1} # Integer

# pg and activerecord <= 4.0.0.beta1
{"0" => 1, "4" => 1} # String

# pg and activerecord master
{0.0 => 1, 4.0 => 1} # Float
```

These are *not* a result of groupdate (and unfortunately cannot be fixed by groupdate)

## History

View the [changelog](https://github.com/ankane/groupdate/blob/master/CHANGELOG.md)

Groupdate follows [Semantic Versioning](http://semver.org/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
