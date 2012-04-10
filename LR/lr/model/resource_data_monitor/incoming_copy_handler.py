import logging
import pprint
import urllib2
import couchdb
import json
import urlparse
import ConfigParser
import os
from pylons import config
from lr.lib import helpers as h
from lr.lib.couch_change_monitor import BaseChangeHandler

log = logging.getLogger(__name__)

scriptPath = os.path.dirname(os.path.abspath(__file__))
_PYLONS_CONFIG =  os.path.join(scriptPath, '..', '..', '..', 'development.ini.orig')
_config = ConfigParser.ConfigParser()
_config.read(_PYLONS_CONFIG)

_RESOURCE_DISTRIBUTABLE_TYPE = "resource_data_distributable"
_DOC_TYPE = "doc_type"
_DOC = "doc"


class IncomingCopyHandler(BaseChangeHandler):
	def __init__(self):
		self._serverUrl = _config.get("app:main", "couchdb.url")
		self._targetName = _config.get("app:main", "couchdb.db.resourcedata")	
		
		s = couchdb.Server(self._serverUrl)
		self._db = s[self._targetName]

	def _canHandle(self, change, database):
		if ((_DOC in change) and (change[_DOC].get(_DOC_TYPE) ==_RESOURCE_DISTRIBUTABLE_TYPE)):
			return True
		return False


	def _handle(self, change, database):

		newDoc = change[_DOC]
		newDoc['node_timestamp'] = h.nowToISO8601Zformat()
		del newDoc['_rev']
		self._db.save(newDoc)