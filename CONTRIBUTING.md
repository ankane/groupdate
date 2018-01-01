# Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/groupdate/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/groupdate/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## Testing

On Mac:

```
# install and run PostgreSQL
brew install postgresql
brew services start postgresql

# install and run MySQL
brew install mysql
brew services start mysql

# create databases
createdb groupdate_test
mysql -u root -e "create database groupdate_test"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql

# clone the repo and run the tests
git clone https://github.com/ankane/groupdate.git
cd groupdate
bundle install
bundle exec rake test
```
