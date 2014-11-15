# ICU::Calendar

[Ruby-FFI] bindings for the Calendar functionality of [ICU].

[![Build Status](https://travis-ci.org/cbandy/icu-calendar.svg?branch=master)](https://travis-ci.org/cbandy/icu-calendar)


## Requirements

* [ICU4C] >= 4.2
* [Ruby-FFI]
* Ruby >= 1.9.3


## Installation

```sh
gem install icu-calendar
```

### Ubuntu

```sh
sudo apt-get install ^libicu..$
```

## Usage

```ruby
require 'icu/calendar'

# Calendar for the default locale at the current time in the current timezone
ICU::Calendar.new

ICU::Calendar.new(locale: 'de_DE')
ICU::Calendar.new(time: Time.now - 300)
ICU::Calendar.new(timezone: 'America/New_York')

# Chinese calendar for the default locale
ICU::Calendar.new(locale: '@calendar=chinese')

calendar = ICU::Calendar.new
calendar[:year] # 2014
calendar.add(:month, 12)
calendar[:year] # 2015
```


[ICU]: http://icu-project.org "International Components for Unicode"
[ICU4C]: http://icu-project.org/download
[Ruby-FFI]: https://github.com/ffi/ffi
