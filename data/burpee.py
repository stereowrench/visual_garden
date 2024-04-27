import scrapy
import string
import logging

class BlogSpider(scrapy.Spider):
    name = 'seedsnow-spider'

    start_urls = ["https://www.burpee.com/sitemap.html"]

    def parse(self, response):
        # a = response.selector.xpath("//h2[text()='Categories']/following-sibling::div[1]//a").getall()
        a = response.selector.xpath("//h2[text()='Categories']/following-sibling::div[1]//a")
        logging.debug(a)
        for title in a:
            yield {'title': title.css('::text').get(), 'url': title.attrib["href"]}
        # for title in response.css('.product-item__title.text--strong.link'):
            # yield {'title': title.css('::text').get()}
        # for next_page in response.css('alphabet'):
        #     yield response.follow(next_page, self.parse)
        # for next_page in response.css('.pagination__next.link'):
            # yield response.follow(next_page, self.parse)
