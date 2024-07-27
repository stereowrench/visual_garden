import scrapy
import string
import logging
from urllib.parse import urljoin
from scrapy.utils.response import open_in_browser

class BlogSpider(scrapy.Spider):
    name = 'seedsnow-spider'

    start_urls = []
    # for letter in list(string.ascii_lowercase):
    for letter in list("t"):
        start_urls.append('https://www.seedsnow.com/collections/alphabetical-begins-with-' + letter)

    def parse_item(self, response):
        # open_in_browser(response)
        category = response.css('.breadcrumbs-list > :nth-child(2) > a::text').get().strip()
        title = response.css('.product-title::text').get().strip()
        description = " ".join(response.css(".disclosure__content.rte ::text").getall()).strip()
        yield {"category": category, "title": title, "description": description, "url": response.url}

    def parse(self, response):
        # url = urljoin(response.url, "/collections/shop-tomato-seeds/products/tomato-abraham-abe-lincoln")
        # yield response.follow(url, self.parse_item)
        for title in response.css('.js-pagination-result .card__title > .card-link'):
            # yield {'title': title.css('::text').get()}
            url = urljoin(response.url, title.css("::attr(href)").get())
            yield response.follow(url, self.parse_item)
        # for next_page in response.css('alphabet'):
        #     yield response.follow(next_page, self.parse)
        for next_page in response.css('.pagination--modern > a'):
            print(next_page)
            yield response.follow(next_page, self.parse)
