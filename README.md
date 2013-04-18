# Groupdate

The simplest way to group by:

- day
- week
- month
- hour
- *and more* (complete list at bottom)

:tada: Time zones supported!!

PostgreSQL only at the moment - support for other datastores coming soon

## Usage

```ruby
User.group_by_day(:created_at).count
# {
#   "2013-04-16 00:00:00+00" => 50,
#   "2013-04-17 00:00:00+00" => 100,
#   "2013-04-18 00:00:00+00" => 34
# }

Task.group_by_month(:updated_at).count
# {
#   "2013-02-01 00:00:00+00" => 84,
#   "2013-03-01 00:00:00+00" => 23,
#   "2013-04-01 00:00:00+00" => 44
# }

Goal.group_by_year(:accomplished_at).count
# {
#   "2011-01-01 00:00:00+00" => 7,
#   "2012-01-01 00:00:00+00" => 11,
#   "2013-01-01 00:00:00+00" => 3
# }
```

The default time zone is `Time.zone`.  Pass a time zone as the second argument.

```ruby
User.group_by_week(:created_at, "Pacific Time (US & Canada)").count
# {
#   "2013-02-25 08:00:00+00" => 80,
#   "2013-03-04 08:00:00+00" => 70,
#   "2013-03-11 07:00:00+00" => 54
# }

# equivalently
time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
User.group_by_week(:created_at, time_zone).count
```

Use it with anything you can use `group` with:

```ruby
Task.completed.group_by_hour(:completed_at).average(:priority)
```

Go nuts!

```ruby
Request.where(page: "/home").group_by_minute(:started_at).maximum(:request_time)
```

**Note:** On Rails 4 edge, queries return a Time object (much better!) as a result of [this commit](https://github.com/rails/rails/commit/2cc09441c2de57b024b11ba666ba1e72c2b20cfe)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'groupdate'
```

## Complete list

- microseconds
- milliseconds
- second
- minute
- hour
- day
- week
- month
- quarter
- year
- decade
- century
- millennium

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
