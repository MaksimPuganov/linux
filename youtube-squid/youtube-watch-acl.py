#!/usr/bin/env python

import httplib2
import re
import sys
import logging
from urlparse import urlparse
import os 

youtubeServerUrl = "http://localhost:9999"

logger = logging.getLogger('console')
logger.setLevel(logging.INFO)
ch = logging.FileHandler(filename="/var/log/squid/youtube.log")
ch.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

def response(r):
	sys.stdout.write("%s\n" % r)
	sys.stdout.flush()

def queryYoutubeServer(url):
	try:
		#httplib2.debuglevel=4
		h = httplib2.Http(disable_ssl_certificate_validation=False)

		r, content = h.request(url, "GET")
		return content
	except Exception as e:
		print e
		logger.error("Failed to download url " + url)
		return ""

while True:
	try:
		line = sys.stdin.readline().strip()
		
		if line == "":
			exit()
		elif line.startswith("https://www.youtube.com/user/"):
			user = line[line.find('/user/')+6:]
			reply = queryYoutubeServer(youtubeServerUrl + "/user/" + user)
			response(reply)
		elif line.startswith("https://www.youtube.com/watch?v="):
			watch = line[line.find('/watch?v=')+9:]
			reply = queryYoutubeServer(youtubeServerUrl + "/watch/" + watch)
			response(reply)
		else:
			response("ERR")
	except Exception as e:
		logger.error("Error: " + str(e))
		pass

