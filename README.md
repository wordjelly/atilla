# Atilla - Ruby Web-Crawler, Cache Warmer and SEO metric Generator

<img src="https://github.com/wordjelly/atilla/blob/master/atilla_image.png" height="250" width="250" />

Inspired by Atilla the Hun, this gem will crawl all pages on a given domain. It provides ultra-useful metrics about every page and warms site caches at the same time.

The generated metrics file can be uploaded to https://www.envybase.com and viewed. Here is a link to a demo crawl.

It also provides a visual embeddable sitemap that can be placed on any site.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add atilla

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install atilla

## Usage

### How to initialize:

```
require "atilla"

The crawler accepts three arguments.
1. host -> the host that we are supposed to crawl [REQUIRED]
2. seed_urls -> these can be additional urls within the website from where you wish to start the crawl. Assume that your website is not highly internally linked and some pages may not be accessible to a crawler starting at the home page. You can specify as many seed urls as you want. 
3. opts -> a general options hash. It accepts various parameters including:

a. params -> url_params that are appended to every url that is crawled. Here "nocache" => true is passed as this is commonly respected by most caching solutions to bypass the cache.
b. max_concurrency -> how many urls to hit in parallel while crawling

crawler = Atilla::Crawler.new("http://localhost:3000",["http://localhost:3000/entry_point_1","http://localhost:3000/entry_point_2"],{"params" => {"nocache" => true}})



```

### Url Following System:

1. No-follow urls are not followed.
2. Atilla looks for meta-tags on pages like the following and will also index those pages : 

```
This is useful if your page has multiple urls pointing to it and you want to cache all versions.
<meta alternate-cache-url="/whatever" />
<meta alternate-cache-url="/something else" />
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wordjelly/atilla. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/wordjelly/atilla/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Atilla project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wordjelly/atilla/blob/master/CODE_OF_CONDUCT.md).
