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
# => {2013-04-16 00:00:00 UTC=>50,2013-04-17 00:00:00 UTC=>100}

Task.group_by_month(:updated_at).count
# => {2013-04-01 00:00:00 UTC=>23,2013-04-01 00:00:00 UTC=>44}

Goal.group_by_year(:accomplished_at).count
# => {2012-01-01 00:00:00 UTC=>11,2013-01-01 00:00:00 UTC=>3}
```

The default time zone is `Time.zone`.  Pass a time zone as the second argument.

```ruby
time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
User.group_by_week(:created_at, time_zone).count
# => {2013-04-16 00:00:00 UTC=>80,2013-04-17 00:00:00 UTC=>70}
```

Use it with anything that you can use `group` with:

```ruby
Task.completed.group_by_hour(:completed_at).average(:priority)
```

Go nuts!

```ruby
Request.where(page: "/home").group_by_minute(:started_at).maximum(:request_time)
```

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
