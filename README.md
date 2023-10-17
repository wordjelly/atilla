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

The third argument is the options hash
```

### Options

#### Seed Urls: 

The seed urls, are specified in the second argument of the initializer. If left blank, it uses the host as a seed url. If provided, it will use those seed urls. Optionally the following two options can be set :

1. only_sitemap [DEFAULT FALSE] -> the crawler will only crawl the urls provided in the host/sitemap.xml and no other urls.
2. urls_file [DEFAULT NIL] -> Will read the provided file path (must be absolute path), and will parse the urls out of that file. Every url should be provided on a new line.
2a. urls_file_limit [DEFAULT ALL] -> If provided, will restrict the urls from the file to the given number

If either of 'only_sitemap' or 'urls_file' is provided, the 'crawl_discovered_urls' option is set to 'false'. This means that only the urls populated into the 'seed_urls' will be crawled.

Sitemap urls are appended to the seed urls, by default if neither of the above two options are specified. This ensures that the sitemap will always be crawled.

#### Miscellaneous Options:

1. crawl_discovered_urls [DEFAULT TRUE] -> the crawler will follow all 'a' tags on every page that it visits and add those pages to the crawl queue. Thie setting is switched to false if 'only_sitemap' or 'urls_file' is provided. 
2. urls_limit [DEFAULT ALL] -> limit the number of urls that will be crawled, once this limit is crossed no new urls are crawled. The limit is applied at runtime.
3. normalize_urls [DEFAULT TRUE] -> whether to normalize all urls, as per the Addressable Gem's specifications.
4. save_output [DEFAULT FALSE] -> the crawler does not save the crawl output by default. This must be set to true explicitly. The crawler instance holds a hash called 'completed_urls' which contains all information about every url. You can access this directly on the crawler object at the end of the crawl.
5. output_path [DEFAULT NIL, WILL RAISE] -> you must specify an output directory to write the json of the crawl, only IF you set "save_output" to true.
6. params [EMPTY HASH] -> custom parameters to append to each url request.
7. requests_per_second -> how many requests to make per second to the host. Defaults to 30. 
8. headers -> the request headers for every request.


### Indexing to Elasticsearch:


### Url Following System:

1. No-follow urls are not followed.
2. Atilla looks for meta-tags on pages like the following and will also index those pages : 

```
This is useful if your page has multiple urls pointing to it and you want to cache all versions.
<meta alternate-cache-url="/whatever" />
<meta alternate-cache-url="/something else" />
```

## ROADMAP
# free
# meta inspector for data extraction
# page stats
# distributed
# dashboard


# speed 2x faster than nokogiri.
# nap parser inbuilt 
# internal page weight, and page keyword scoring, to simply search
# talk to documents
# auto extraction of structured jsonld and schema
# distributed - add and remove workers at will, just get a digitalocean api key
# data qa : use openai to ask questions to the data.
# outputs structured data to any sheet.
# dashboard to view progress, use redis to 
# specify site crawl budget


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wordjelly/atilla. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/wordjelly/atilla/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the GNU General Public License v3.0. The terms of the same can be found in this repository. I explicitly forbid the use of my source code or any output generated by it as training/test/validation data in any machine learning or AI/ML pipelines.

## Code of Conduct

Everyone interacting in the Atilla project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wordjelly/atilla/blob/master/CODE_OF_CONDUCT.md).
