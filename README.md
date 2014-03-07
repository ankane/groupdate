# Groupdate

The simplest way to group by:

- day
- week
- hour of the day
- and more (complete list below)

:tada: Time zones supported!! **the best part**

:cake: Get the entire series - **the other best part**

Works with Rails 3.0+

Supports PostgreSQL and MySQL

[![Build Status](https://travis-ci.org/ankane/groupdate.png)](https://travis-ci.org/ankane/groupdate)

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

Results are returned in ascending order, so no need to sort.

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

### Time Zones

The default time zone is `Time.zone`.  Change this with:

```ruby
Groupdate.time_zone = "Pacific Time (US & Canada)"
```

or

```ruby
User.group_by_week(:created_at, time_zone: "Pacific Time (US & Canada)").count
# {
#   2013-03-03 08:00:00 UTC => 80,
#   2013-03-10 08:00:00 UTC => 70,
#   2013-03-17 07:00:00 UTC => 54
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

## Before 2.0

Before 2.0, Groupdate returned an `ActiveRecord::Relation` instead of a `Groupdate::Series` by default.

Use `series: false` for this behavior.

```ruby
User.group_by_day(:created_at, series: false).count
```

**Note:** Results will be unordered, and days with no records will not appear.

## History

View the [changelog](https://github.com/ankane/groupdate/blob/master/CHANGELOG.md)

Groupdate follows [Semantic Versioning](http://semver.org/)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/groupdate/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/groupdate/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
