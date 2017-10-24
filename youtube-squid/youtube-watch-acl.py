#!/usr/bin/env python

import httplib2
import socks
import re
import sys
import logging
from urlparse import urlparse

logger = logging.getLogger('console')
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
		#httplib2.debuglevel=4
		h = httplib2.Http()

		r, content = h.request(url, "GET")

		match = re.compile('"ucid":"([^"]+)"').findall(content)
		if match:
			return match[0]
		else:
			logger.error("Could not find ucid")
			return ""
	except:
		logger.error("Failed to download url " + url)
		return ""

while True:
	try:
		line = sys.stdin.readline().strip()

		if line == "":
			exit()
		elif line.startswith("https://www.youtube.com/watch?"):
			dcid = download(line)
			if dcid == 'UCu6mSoMNzHQiBIOCkHUa2Aw':
				logger.info("Valid Channel for " + line)
				response("OK")
			else:
				logger.error("Invalid Channel for " + line)
				response("ERR")
		else:
			response("ERR")
	except Exception as e:
		pass

