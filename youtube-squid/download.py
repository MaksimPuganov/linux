#!/usr/bin/env python

import httplib2
import socks
import re
import sys
import logging
from urlparse import urlparse

logger = logging.getLogger('awsconsole')
logger.setLevel(logging.INFO)
ch = logging.FileHandler(filename="/tmp/logger.log")
ch.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

def response(r):
	sys.stdout.write("%s\n" % r)
	sys.stdout.flush()

def download(url):
	try:
		#UCu6mSoMNzHQiBIOCkHUa2Aw
		#httplib2.debuglevel=4
		h = httplib2.Http(proxy_info = httplib2.ProxyInfo(socks.PROXY_TYPE_HTTP, 'localhost', 3128), disable_ssl_certificate_validation=True)

		logger.info(url)
		r, content = h.request(url, "GET")

		match = re.compile('"ucid":"([^"]+)"').findall(content)
		if match:
			return match[0]
		else:
			logger.error("Could not find ucid")
			return ""
	except:
		logger.error("Failed to download url")
		return ""

while True:
	try:
		line = sys.stdin.readline().strip()

		if line == "":
			exit()
		elif line.startswith("https://www.youtube.com/embed"):
			logger.info(line)
			ucid = download(line)
			if ucid == 'UCu6mSoMNzHQiBIOCkHUa2Aw':
				response("OK")
			else:
				response("ERR message=Invalid%20Channel")
		else:
			response("ERR")
	except:
		pass

