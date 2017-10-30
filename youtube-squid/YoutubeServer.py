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

class ThreadSafeDict(dict) :
    def __init__(self, * p_arg, ** n_arg) :
        dict.__init__(self, * p_arg, ** n_arg)
        self._lock = threading.Lock()

    def __enter__(self) :
        self._lock.acquire()
        return self

    def __exit__(self, type, value, traceback) :
        self._lock.release()

WATCH_CACHE = ThreadSafeDict()

PORT = 8080
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

			user = line[url.find('/user/'):]
			user = user[6:]
			uservars.update({'user':user.strip()})
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
with open(dir_path + '/youtube.whitelist.txt') as f:
	for line in f:
		if line.startswith("https://"):
			user = line.strip()
			userdetails = finduser(user)
			if userdetails != None:
				username = userdetails.get('user')
				logger.info("Adding user " + username)
				userlist.append(username)
				
				channel = userdetails.get('channel')

				channellist.append(userdetails.get('channel'))
				users.update({user:userdetails})

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
			with WATCH_CACHE as w:
				if watch not in w:
					ucid = findchannelidforwatch(watch)
					if ucid != "":
						w[watch] = ucid
				
				if watch in w:
					ucid = w[watch]
					if ucid in channellist:
						self.wfile.write("OK")
					else:
						self.wfile.write("ERR")
				else:
					self.wfile.write("BH")
		except Exception as e:
			logger.error("Error " + str(e))
			self.wfile.write("BH")
			
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
			self.wfile.write("</head><body>")
			self.wfile.write("<img src=\"youtube.png\"><ul>")
			for i in userlist:
				self.wfile.write("<li>");
				user = users.get(i)
				
				self.wfile.write("<a href=\"" + i + "\">")
				if 'photo' in user:
					self.wfile.write('<img src="' + user.get('photo') + '" width="50">')
				if 'title' in user:
					self.wfile.write(user.get('title'))
				else:
					self.wfile.write(i)
				self.wfile.write("</a>")
				if 'description' in user:
					self.wfile('<p>' + user.get('description') + '</p>')
				self.wfile.write("</li>")
				
			self.wfile.write("</ul></body></html>")

PORT=int(argv[1])
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


