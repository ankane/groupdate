# Groupdate

The simplest way to group by:

- day
- week
- month
- day of the week
- hour of the day
- *and more* (complete list at bottom)

:tada: Time zones supported!!

PostgreSQL and MySQL only at the moment - support for other datastores coming soon

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

**Note:** Weeks start on Sunday.

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

Use it with anything you can use `group` with:

```ruby
Task.completed.group_by_hour(:completed_at).average(:priority)
```

Go nuts!

```ruby
Request.where(page: "/home").group_by_minute(:started_at).maximum(:request_time)
```

### Note

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

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'groupdate'
```

### MySQL only

[Time zone support](http://dev.mysql.com/doc/refman/5.6/en/time-zone-support.html) must be installed on the server.

```
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
