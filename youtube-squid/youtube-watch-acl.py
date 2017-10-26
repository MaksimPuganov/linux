#!/usr/bin/env python

import httplib2
import re
import sys
import logging
from urlparse import urlparse
import os 

dir_path = os.path.dirname(os.path.realpath(__file__))

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

def findbrowseidforuser(url):
	try:
		#httplib2.debuglevel=4
		h = httplib2.Http(disable_ssl_certificate_validation=False)

		r, content = h.request(url, "GET")
#vnd.youtube://user/UCXuqSBlHAE6Xw-yeJA0Tunw
		match = re.compile('"vnd.youtube://user/([^"]+)"').findall(content)
		if match:
			return match[0]
		else:
			logger.error("Could not find browseId for url " + url)
			return ""
	except Exception as e:
		print e
		logger.error("Failed to download url " + url)
		return ""

def findchannelidforwatch(url):
	try:
		#httplib2.debuglevel=4
		h = httplib2.Http(disable_ssl_certificate_validation=False)

		r, content = h.request(url, "GET")

		match = re.compile('"ucid":"([^"]+)"').findall(content)
		if match:
			return match[0]
		else:
			logger.error("Could not find ucid for url " + url)
			return ""
	except Exception as e:
		print e
		logger.error("Failed to download url " + url)
		return ""

users = list()
channels = list()
with open(dir_path + '/youtube.whitelist.txt') as f:
    for line in f:
        if line.startswith("https://"):
			user = line.strip()
			channel = findbrowseidforuser(user)
			if channel != "":
				logger.info("Adding user " + user + " with channel " + channel)
				users.append(user)
				channels.append(channel)

while True:
	try:
		line = sys.stdin.readline().strip()
		
		if line == "":
			exit()
		elif line.startswith("https://www.youtube.com/user/"):
			stripped_line = line[:line.find('?')] if '?' in line else line
			if stripped_line in users:
				logger.info("Valid user: " + line)
				response("OK")
			else:
				logger.info("Invalid user: " + line)
				response("ERR")
		elif line.startswith("https://www.youtube.com/watch?"):
			dcid = findchannelidforwatch(line)
			if dcid != "":
				if dcid in channels:
					logger.info("Valid Channel for " + line)
					response("OK")
				else:
					logger.error("Invalid Channel for " + line)
					response("ERR")
			else:
				response("ERR")
		else:
			response("ERR")
	except Exception as e:
		pass

