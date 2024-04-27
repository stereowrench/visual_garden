import scrapy
import string
import logging

class BlogSpider(scrapy.Spider):
    name = 'seedsnow-spider'

    start_urls = []
    # for letter in list(string.ascii_lowercase):
    for letter in list("t"):
        start_urls.append('https://www.seedsnow.com/collections/alphabetical-begins-with-' + letter)

    def parse(self, response):
        for title in response.css('.product-item__title.text--strong.link'):
            yield {'title': title.css('::text').get()}
        # for next_page in response.css('alphabet'):
        #     yield response.follow(next_page, self.parse)
        for next_page in response.css('.pagination__next.link'):
            yield response.follow(next_page, self.parse)
