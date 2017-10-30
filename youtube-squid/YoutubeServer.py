#!/usr/bin/env python

from SocketServer import ThreadingMixIn
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import SocketServer
import os 
import urlparse
import httplib2
import re
import sys
import logging
import threading
from sys import argv

class ThreadSafeDict :
	def __init__(self, max_size) :
		self._max_size = max_size
		self._lru = []
		self._dict = {}
		self._lock = threading.Lock()

	def get(self, key, default=None):
		with self._lock:
			return self._dict.get(key, default)

	def add(self, key, value):
		with self._lock:
			if len(self._dict) >= self._max_size:
				oldkey = self._lru.pop(0)
				del self._dict[oldkey]

			self._lru.append(key)
			self._dict[key] = value

	def __contains__(self, key):
		with self._lock:
			return key in self._dict

	def __len__(self):
		with self._lock:
			return len(self._dict)

PORT = 80
dir_path = os.path.dirname(os.path.realpath(__file__))

logger = logging.getLogger('console')
logger.setLevel(logging.INFO)
ch = logging.FileHandler(filename="/var/log/squid/youtube-server.log")
ch.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

def findchannelidforwatch(watch):
	try:
		url = 'https://www.youtube.com/watch?v=' + watch
		logger.info("Finding channel id for URL: " + url)
		#httplib2.debuglevel=4
		h = httplib2.Http(disable_ssl_certificate_validation=False)

		r, content = h.request(url, "GET")

		match = re.compile('"ucid":"([^"]+)"').findall(content)
		if match:
			logger.info("Found ucid: " + match[0])
			return match[0]
		else:
			logger.error("Could not find ucid for url " + url)
			return ""
	except Exception as e:
		print e
		logger.error("Failed to download url " + url)
		return ""

def finduser(url):
	try:
		#httplib2.debuglevel=4
		h = httplib2.Http(disable_ssl_certificate_validation=False)

		uservars = dict()
		r, content = h.request(url, "GET")
#vnd.youtube://user/UCXuqSBlHAE6Xw-yeJA0Tunw
#<meta name="twitter:image" content="https://yt3.ggpht.com/-QGhAvSy7npM/AAAAAAAAAAI/AAAAAAAAAAA/Uom6Bs6gR9Y/s900-c-k-no-mo-rj-c0xffffff/photo.jpg">
		match = re.compile('<meta property="og:image" content="([^"]+)"').findall(content)
		if match:
			uservars.update({'photo':match[0]})
		else:
			logger.error("Could not find photo for user " + url)

		match = re.compile('<meta property="og:title" content="([^"]+)"').findall(content)
		if match:
			uservars.update({'title':match[0]})
		else:
			logger.error("Could not find title for user " + url)

		match = re.compile('<meta property="og:description" content="([^"]+)"').findall(content)
		if match:
			uservars.update({'description':match[0]})
		else:
			logger.error("Could not find description for user " + url)

		match = re.compile('"vnd.youtube://user/([^"]+)"').findall(content)
		if match:
			uservars.update({'channel':match[0]})
			uservars.update({'url':url})

			user = line[url.find('/user/') + 6:].strip()
			uservars.update({'user':user})
			return uservars
		else:
			logger.error("Could not find channel id for user " + url)
			return None
	except Exception as e:
		print e
		logger.error("Failed to download page for user " + url)
		return None

userlist = list()
channellist = list()
users = dict()
watchCache = ThreadSafeDict(100)

with open(dir_path + '/youtube.whitelist.txt') as f:
	for line in f:
		if line.startswith("https://"):
			userurl = line.strip()
			userdetails = finduser(userurl)
			if userdetails != None:
				username = userdetails.get('user')
				logger.info("Adding user " + username)
				userlist.append(username)
				
				channel = userdetails.get('channel')

				channellist.append(userdetails.get('channel'))
				users.update({username:userdetails})

class ThreadingSimpleServer(ThreadingMixIn, HTTPServer):
	allow_reuse_address = True

#http://stackoverflow.com/questions/22077881/yes-reporting-error-with-subprocess-communicate/22083141#22083141
def restore_signals(): # from http://hg.python.org/cpython/rev/768722b2ae0a/
	signals = ('SIGPIPE', 'SIGXFZ', 'SIGXFSZ')
	for sig in signals:
		if hasattr(signal, sig):
			signal.signal(getattr(signal, sig), signal.SIG_DFL)

class HttpRequestHandler(BaseHTTPRequestHandler):
	def _output_file(self, name, contentType):
		filePath = dir_path + '/' + name

		self.send_response(200)
		self.send_header("Content-Type", contentType + "; charset=UTF-8")
		self.end_headers()

		with open(filePath, 'r') as myfile:
			readfile=myfile.read()

		self.wfile.write(readfile)

	def _set_headers(self):
		self.send_response(200)
		self.send_header('Content-type', 'text/html; charset=UTF-8')
		self.end_headers()

	# /user/XXXXX
	def _do_get_user(self, path):
		user = path[6:]

		logger.info("User is " + user)
		self.send_response(200)
		self.send_header('Content-type', 'text/plain; charset=UTF-8')
		self.end_headers()

		if user in userlist:
			self.wfile.write("OK")
		else:
			self.wfile.write("ERR")
	# /watch/XXXXX
	def _do_get_watch(self, path):
		watch = path[7:]

		logger.info("Watch is " + watch)
		self.send_response(200)
		self.send_header('Content-type', 'text/plain; charset=UTF-8')
		self.end_headers()

		try:
			with watchCache as wc:
				# if not in cache as yet, then download and add to cache
				if watch not in wc:
					ucid = findchannelidforwatch(watch)
					if ucid != "":
						wc.add(watch, ucid)
				
				if watch in wc:
					ucid = wc.get(watch)
					if ucid in channellist:
						self.wfile.write("OK")
					else:
						self.wfile.write("ERR")
				else:
					self.wfile.write("ERR")
		except Exception as e:
			logger.error("Error " + str(e))
			self.wfile.write("ERR")
			
	def do_GET(self):
		path = urlparse.urlparse(self.path)
		query = urlparse.parse_qs(path.query)

		if path.path[1:].endswith(".ico"):
			self._output_file(path.path[1:], 'image/x-icon')
		elif path.path[1:].endswith(".png"):
			self._output_file(path.path[1:], 'image/png')
		elif path.path.startswith("/user/"):
			self._do_get_user(path.path)
		elif path.path.startswith("/watch/"):
			self._do_get_watch(path.path)
		else:
			self._set_headers()

			self.wfile.write("<html><html style=\"background-color: #fafafa;\">")
			self.wfile.write("<title>Youtube Channels</title>")
			self.wfile.write("</head><body>")
			self.wfile.write("<p><img style=\"vertical-align:middle\" src=\"youtube.png\"> <span style=\"font-size: x-large; font-weight: bold\">Youtube Channels</span></p>")

			self.wfile.write("<ul>")
			for i in userlist:
				self.wfile.write("<li>");
				user = users.get(i)

				self.wfile.write("<a style=\"text-decoration: none\" href=\"" + user.get('url') + "\">")
				if 'photo' in user:
					self.wfile.write('<img style=\"vertical-align:middle\" src="' + user.get('photo') + '" width="50"> ')

				if 'title' in user:
					self.wfile.write(user.get('title'))
				else:
					self.wfile.write(i)

				self.wfile.write("</a>")
				if 'description' in user:
					self.wfile.write('<p>' + user.get('description') + '</p>')
				self.wfile.write("</li>")
				
			self.wfile.write("</ul></body></html>")

#if len(argv) > 0:
#	PORT=int(argv[1])

try:
    logger.info("Starting Console on port " + str(PORT) + "...")
    server = ThreadingSimpleServer(('0.0.0.0', PORT), HttpRequestHandler)

    try:
        while 1:
            sys.stdout.flush()
            server.handle_request()
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        server.server_close()
        server.socket.close()
finally:
    logger.info("Done!")


