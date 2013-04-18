# Groupdate

The simplest way to group by:

- day
- week
- month
- year
- hour
- microseconds
- milliseconds
- second
- minute
- quarter
- decade
- century
- millennium

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
User.group_by_day(:created_at, ActiveSupport::TimeZone["Pacific Time (US & Canada)"]).count
# => {2013-04-16 00:00:00 UTC=>80,2013-04-17 00:00:00 UTC=>70}
```

Use it with anything that you can use `group` with:

```ruby
User.group_by_week(:created_at).sum(:tasks_count)

User.group_by_hour(:created_at).average(:tasks_count)

User.group_by_quarter(:created_at).maximum(:tasks_count)

User.group_by_second(:created_at).average(:tasks_count)
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'groupdate'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
